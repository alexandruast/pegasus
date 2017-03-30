variable "infrastructure" { }
variable "environment" { }
variable "region" { }
variable "host_group_name" { }
variable "public_zone_id" { }
variable "subnet_ids" { type = "list" }
variable "security_group_ids" { type = "list" }
variable "instance_ids" { type = "list" }
variable "http_backend_port" { }
variable "http_backend_hc" { }

output "dns_name" { value = "${aws_elb.main.dns_name}" }

resource "aws_elb" "main" {
  name = "${var.infrastructure}-${var.environment}-${var.host_group_name}"
  subnets = ["${var.subnet_ids}"]
  security_groups = ["${var.security_group_ids}"]

  listener {
    instance_port = "${var.http_backend_port}"
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "${var.http_backend_hc}"
    interval = 10
  }

  instances = ["${var.instance_ids}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "${var.infrastructure}-${var.environment}-${var.host_group_name}"
    Infrastructure = "${var.infrastructure}"
    Environment = "${var.environment}"
    Group = "${var.host_group_name}"
  }
}

resource "aws_route53_record" "latency" {
  zone_id = "${var.public_zone_id}"
  name = "${var.infrastructure}-${var.environment}-${var.host_group_name}"
  type = "CNAME"
  ttl = "30"
  latency_routing_policy {
    region = "${var.region}"
  }
  set_identifier = "${var.region}-${var.host_group_name}"
  records = ["${aws_elb.main.dns_name}"]
}
