variable "infrastructure" { }
variable "environment" { }
variable "region" { }
variable "subnet_cidrs" { type = "list" }
variable "subnet_ids" { type = "list" }
variable "private_zone_id" { }
variable "public_zone_id" { default = "" }

variable "instance_count" { }
variable "host_group_name" { }
variable "instance_type" { }
variable "ami_id" { }
variable "security_group_ids" { type = "list" }
variable "key_name" { }
variable "iam_instance_profile" { }
variable "user_data" { }

output "private_ips" { value = ["${aws_instance.host.*.private_ip}"] }
output "public_ips" { value = ["${aws_eip.main.*.public_ip}"] }
output "instance_ids" { value = ["${aws_instance.host.*.id}"] }

resource "aws_eip" "main" {
  count = "${var.instance_count}"
  instance = "${element(aws_instance.host.*.id,count.index)}"
}

resource "aws_instance" "host" {
  count = "${var.instance_count}"
  ami = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  subnet_id = "${element(var.subnet_ids, count.index)}"
  private_ip = "${cidrhost(element(var.subnet_cidrs, count.index), 10 + floor(count.index/length(var.subnet_cidrs)))}"
  vpc_security_group_ids = ["${var.security_group_ids}"]
  iam_instance_profile = "${var.iam_instance_profile}"
  user_data = "${file(var.user_data)}"
  tags {
    Name = "${var.infrastructure}-${var.environment}-${var.host_group_name}-${count.index}"
    Infrastructure = "${var.infrastructure}"
    Environment = "${var.environment}"
    Group = "${var.host_group_name}"
  }
}
resource "aws_route53_record" "private" {
  count = "${var.instance_count}"
  zone_id = "${var.private_zone_id}"
  name = "${var.host_group_name}-${count.index}"
  type = "A"
  ttl = "30"
  records = ["${element(aws_instance.host.*.private_ip, count.index)}"]
}
