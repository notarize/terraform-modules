variable "name" {
  type        = "string"
  description = "The name of the vpc, used in tags."
}

variable "availability_zones_count" {
  type        = "string"
  description = "The number of availability zones being used. Workaround for not being allowed to calculate the value of `count`."
}

variable "cidr_subnet" {
  type = "string"

  description = <<EOF
This determines which portion of the cidr block will be used for the VPC
If the cidr block allocated to AWS is /16, this value must be between 0 and 31, inclusive
NOTE: Changing this after a VPC has been created will taint basically every resource
EOF
}

variable "cidr_block" {
  type        = "string"
  description = "The cidr block that we have reserved for AWS environments.
}

variable "domain" {
  type = "string"
}

variable "internal_domain" {
  type = "string"
}

variable "name_servers" {
  type = "list"
}
