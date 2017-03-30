ec2_instance_vpn = {
  size = 1
  type = "t2.small"
  ami = "ami-f0768de6"
  key = "default"
}

ec2_instance_management = {
  size = 3 # Nomad / Consul / Vault servers must be 3 or 5
  type = "t2.small"
  ami = "ami-f0768de6"
  key = "default"
}

ec2_instance_compute = {
  size = 0
  type = "t2.micro"
  ami = "ami-f0768de6"
  key = "default"
}

ec2_instance_compute_c4 = {
  size = 0
  type = "c4.2xlarge"
  ami = "ami-f0768de6"
  key = "default"
}


vpc_cidr_block = "10.10.0.0/16"

/* Setup uses 3 availability zones if possible, one subnet in each */
availability_zones = [
  "us-east-1a",
  "us-east-1c",
  "us-east-1e"
]

vpc_subnet_cidrs = [
  "10.10.0.0/20",
  "10.10.32.0/20",
  "10.10.64.0/20"
]

vpn_cidr_blocks = [
  "10.254.224.0/20"
]

ec2_vpn_security_group_rules = [
  { type = "egress",  to_port = 0,     protocol = "-1",  from_port = 0,     cidr_blocks = "0.0.0.0/0"         },
  { type = "ingress", to_port = 0,     protocol  = "-1", from_port = 0,     cidr_blocks = "10.0.0.0/8"        },
  { type = "ingress", to_port = 0,     protocol  = "-1", from_port = 0,     cidr_blocks = "10.254.224.0/20"   },
  { type = "ingress", to_port = 8443,  protocol  = "6",  from_port = 8443,  cidr_blocks = "0.0.0.0/0"         },
  { type = "ingress", to_port = 11947, protocol  = "17", from_port = 11940, cidr_blocks = "0.0.0.0/0"         }
]

ec2_management_security_group_rules = [
  { type = "egress",  to_port = 0,     protocol = "-1",  from_port = 0,     cidr_blocks = "0.0.0.0/0"          },
  { type = "ingress", to_port = 0,     protocol  = "-1", from_port = 0,     cidr_blocks = "10.0.0.0/8"         },
  { type = "ingress", to_port = 0,     protocol  = "-1", from_port = 0,     cidr_blocks = "10.254.224.0/20"    }
]

ec2_compute_security_group_rules = [
  { type = "egress",  to_port = 0,     protocol = "-1",  from_port = 0,     cidr_blocks = "0.0.0.0/0"          },
  { type = "ingress", to_port = 0,     protocol  = "-1", from_port = 0,     cidr_blocks = "10.0.0.0/8"         },
  { type = "ingress", to_port = 0,     protocol  = "-1", from_port = 0,     cidr_blocks = "10.254.224.0/20"    }
]

elb_fabio_security_group_rules = [
  { type = "egress",  to_port = 0,     protocol = "-1",  from_port = 0,     cidr_blocks = "0.0.0.0/0"         },
  { type = "ingress", to_port = 80,    protocol  = "6",  from_port = 80,    cidr_blocks = "0.0.0.0/0"         },
  { type = "ingress", to_port = 443,   protocol  = "6",  from_port = 443,   cidr_blocks = "0.0.0.0/0"         }
]
