data "aws_availability_zones" "available" {
  state = "available"
}

// Get a certain number of availability_zones for the current region
// Skips the first one since it's often not fully usable
// NOTE: This ignores changes to input, so in order to change the availability zones, you need to
//    taint this resource. This is done so that any time amazon adds availability zones, it won't
//    trigger a change to our infrastructure
resource "random_shuffle" "availability_zones" {
  input        = ["${slice(data.aws_availability_zones.available.names, 1, length(data.aws_availability_zones.available.names))}"]
  result_count = "${var.availability_zones_count}"

  lifecycle {
    ignore_changes = ["input"]
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "${cidrsubnet(var.cidr_block, 5, var.cidr_subnet)}"

  // The following 2 options must be set to true to allow custom dns via private hosted zone
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name  = "${var.name}"
    fleet = "${var.name}"

    terraform = true
  }
}

// Create a dhcp options set for the vpc that uses custom nameservers and domain name
resource "aws_vpc_dhcp_options" "options" {
  domain_name         = "${var.name}.${var.internal_domain}"
  domain_name_servers = ["${var.name_servers}"]

  tags {
    Name  = "${var.name}"
    fleet = "${var.name}"

    terrafrom = true
  }
}

resource "aws_vpc_dhcp_options_association" "association" {
  vpc_id          = "${aws_vpc.vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.options.id}"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name  = "${var.name}-default"
    fleet = "${var.name}"

    terraform = true
  }
}

// Default Route Table

resource "aws_default_route_table" "default" {
  default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"

  tags {
    Name  = "${var.name}-default"
    fleet = "${var.name}"

    terraform = true
  }
}

// Default Network ACL

resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.vpc.default_network_acl_id}"
  subnet_ids             = ["${concat(aws_subnet.public.*.id, aws_subnet.private.*.id)}"]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags {
    Name  = "${var.name}-default"
    fleet = "${var.name}"

    terraform = true
  }
}

// Default Security Group

resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name  = "${var.name}-default"
    fleet = "${var.name}"

    terraform = true
  }
}

// Public Subnet

resource "aws_subnet" "public" {
  count = "${var.availability_zones_count}"

  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.vpc.cidr_block, 3, count.index)}"
  availability_zone = "${element(random_shuffle.availability_zones.result, count.index)}"

  tags {
    Name  = "${var.name}.public.${element(random_shuffle.availability_zones.result, count.index)}"
    fleet = "${var.name}"
    type  = "public"
    az    = "${element(random_shuffle.availability_zones.result, count.index)}"

    terraform = true
  }
}

resource "aws_eip" "nat" {
  count = "${var.availability_zones_count}"

  vpc = true

  depends_on = ["aws_internet_gateway.default"]
}

resource "aws_nat_gateway" "default" {
  count = "${var.availability_zones_count}"

  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"

  depends_on = ["aws_internet_gateway.default"]
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  depends_on = ["aws_internet_gateway.default"]

  tags {
    Name  = "${var.name}.public"
    fleet = "${var.name}"
    type  = "public"

    terraform = true
  }
}

resource "aws_route" "internet_gateway" {
  route_table_id = "${aws_route_table.public.id}"
  gateway_id     = "${aws_internet_gateway.default.id}"

  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  count = "${var.availability_zones_count}"

  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

// Private Subnet

resource "aws_subnet" "private" {
  count = "${var.availability_zones_count}"

  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.vpc.cidr_block, 3, var.availability_zones_count + count.index)}"
  availability_zone = "${element(random_shuffle.availability_zones.result, count.index)}"

  tags {
    Name  = "${var.name}.private.${element(random_shuffle.availability_zones.result, count.index)}"
    fleet = "${var.name}"
    type  = "private"
    az    = "${element(random_shuffle.availability_zones.result, count.index)}"

    terraform = true
  }
}

resource "aws_route_table" "private" {
  count = "${var.availability_zones_count}"

  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name  = "${var.name}.private.${element(random_shuffle.availability_zones.result, count.index)}"
    fleet = "${var.name}"
    type  = "private"
    az    = "${element(random_shuffle.availability_zones.result, count.index)}"

    terraform = true
  }
}

// Create a route for each nat
resource "aws_route" "nat" {
  count = "${var.availability_zones_count}"

  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
  nat_gateway_id = "${element(aws_nat_gateway.default.*.id, count.index)}"

  destination_cidr_block = "0.0.0.0/0"
}

// Associate each route table with each of the subnets
resource "aws_route_table_association" "private" {
  count = "${var.availability_zones_count}"

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
