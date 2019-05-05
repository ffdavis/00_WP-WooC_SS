# PROVIDER
provider "aws" {
  shared_credentials_file = "${var.credentialsfile}"
  region                  = "${var.region}"
}

# VPC
resource "aws_vpc" "StoreOneVPC" {
  cidr_block = "${var.vpc-fullcidr}"

  #### this 2 true values are for use the internal vpc dns resolution
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "StoreOneVPC"
  }
}

data "aws_availability_zones" "available" {}

# SUBNET PUBLIC
resource "aws_subnet" "StoreOneSNPublic" {
  vpc_id     = "${aws_vpc.StoreOneVPC.id}"
  cidr_block = "${var.StoreOneSNPublic-CIDR}"

  tags {
    Name = "StoreOneSNPublic"
  }

  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_route_table_association" "StoreOneRTA" {
  subnet_id      = "${aws_subnet.StoreOneSNPublic.id}"
  route_table_id = "${aws_route_table.StoreOneRTPub.id}"
}
