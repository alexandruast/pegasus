variable "infrastructure" { }
variable "environment" { }
variable "region" { }
variable "vpc_id" { }
variable "host_group_name" { }

variable "rules" { type = "list" }

output "id" { value = "${aws_security_group.main.id}" }

resource "aws_security_group" "main" {
  vpc_id = "${var.vpc_id}"
  name = "${var.infrastructure}-${var.environment}-${var.host_group_name}"
  tags {
    Name = "${var.infrastructure}-${var.environment}-${var.host_group_name}"
    Infrastructure = "${var.infrastructure}"
    Environment = "${var.environment}"
    Group = "${var.host_group_name}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "main" {
    count = "${length(var.rules)}"
    type = "${lookup(var.rules[count.index],"type")}"
    from_port = "${lookup(var.rules[count.index],"from_port")}"
    to_port = "${lookup(var.rules[count.index],"to_port")}"
    protocol = "${lookup(var.rules[count.index],"protocol")}"
    cidr_blocks = ["${compact(split(",", lookup(var.rules[count.index],"cidr_blocks","")))}"]
    security_group_id = "${aws_security_group.main.id}"
}
