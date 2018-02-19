output "id" {
  value = "${aws_vpc.vpc.id}"
}

output "public_subnet_ids" {
  value = ["${aws_subnet.public.*.id}"]
}

output "private_subnet_ids" {
  value = ["${aws_subnet.private.*.id}"]
}

output "default_route_table_id" {
  value = "${aws_vpc.vpc.default_route_table_id}"
}

output "default_network_acl_id" {
  value = "${aws_vpc.vpc.default_network_acl_id}"
}

output "default_security_group_id" {
  value = "${aws_vpc.vpc.default_security_group_id}"
}

output "availability_zones" {
  value = ["${random_shuffle.availability_zones.result}"]
}

output "availability_zones_count" {
  value = "${var.availability_zones_count}"
}
