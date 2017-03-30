variable "infrastructure" { }
variable "environment" { }

variable "vpc_cidr_block" { }
variable "vpc_subnet_cidrs" { type = "list" }

variable "availability_zones" { type = "list" }

variable "private_domain" { }

output "id" { value = "${aws_vpc.main.id}" }
output "subnet_ids" { value = ["${aws_subnet.main.*.id}"] }
output "route_table_id" { value = "${aws_route_table.main.id}" }

resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags {
    Name = "${var.infrastructure}-${var.environment}"
    Infrastructure = "${var.infrastructure}"
    Environment = "${var.environment}"
  }
}

resource "aws_vpc_dhcp_options" "private" {
  domain_name = "ec2.internal ${var.private_domain}"
  domain_name_servers = [
    "AmazonProvidedDNS"
  ]
  tags {
    Name = "${aws_vpc.main.id}-dhcp-private"
  }
}

resource "aws_vpc_dhcp_options_association" "private_dns_resolver" {
  vpc_id = "${aws_vpc.main.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.private.id}"
}

resource "aws_subnet" "main" {
  count = "${length(var.vpc_subnet_cidrs)}"
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${element(var.vpc_subnet_cidrs, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true
  tags {
    Name = "${var.infrastructure}-${var.environment}-public-${count.index}"
    Infrastructure = "${var.infrastructure}"
    Environment = "${var.environment}"
  }
}

resource "aws_network_acl" "main" {
  vpc_id = "${aws_vpc.main.id}"
  subnet_ids = ["${aws_subnet.main.*.id}"]
  ingress {
    protocol = -1
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }
  egress {
    protocol = -1
    rule_no = 100
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }
  tags {
    Name = "${var.infrastructure}-${var.environment}-public"
    Infrastructure = "${var.infrastructure}"
    Environment = "${var.environment}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "${var.infrastructure}-${var.environment}-igw"
    Infrastructure = "${var.infrastructure}"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "${var.infrastructure}-${var.environment}-table"
    Infrastructure = "${var.infrastructure}"
    Environment = "${var.environment}"
  }
}

resource "aws_route" "main" {
  route_table_id = "${aws_route_table.main.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.main.id}"
}

resource "aws_route_table_association" "main" {
  count = "${length(var.vpc_subnet_cidrs)}"
  subnet_id = "${element(aws_subnet.main.*.id, count.index)}"
  route_table_id = "${aws_route_table.main.id}"
}
