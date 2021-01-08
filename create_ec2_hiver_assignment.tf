provider "aws" {
  access_key = "<access_key_id>"
  secret_key = "<secret_access_key>"  
  region     = "ap-south-1"
}

#CREATE EC2 INSTANCE

resource "aws_instance" "prod-web-server-1" {
  ami           = "ami-04b1ddd35fd71475a"
  key_name = "test_key"
  instance_type = "r5.large"
  vpc_security_group_ids = ["${aws_security_group.prod-web-servers-sg.id}"]
  subnet_id = "${aws_subnet.private_subnet.id}"
  tags = {
    Name = "prod-web-server-1"
  }
 }

resource "aws_instance" "prod-web-server-2" {
  ami           = "ami-04b1ddd35fd71475a"
  key_name = "test_key"
  instance_type = "r5.large"
  vpc_security_group_ids = ["${aws_security_group.prod-web-servers-sg.id}"]
  subnet_id = "${aws_subnet.private_subnet.id}"
  tags = {
    Name = "prod-web-server-2"
  }
 }

#ASSIGN DEFAULT VPC

resource "aws_default_vpc" "default" {
}

#CREATE SECURITY GROUP
resource "aws_security_group" "prod-web-servers-sg" {
  name        = "prod-web-servers-sg"
  description = "security group for production grade web servers"
  vpc_id      = "${aws_default_vpc.default.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#CREATE SUBNET
resource "aws_subnet" "private_subnet" {
  vpc_id     = "${aws_default_vpc.default.id}"
  cidr_block = "172.31.0.0/24"
  availability_zone = "ap-south-1a"
}

data "aws_subnet_ids" "subnet" {
  vpc_id = "${aws_default_vpc.default.id}"

}

#lb target check
resource "aws_lb_target_group" "NLB_check" {
  name     = "prod-nlb-check"
  port     = 80
  protocol = "TCP"
  target_type = "instance"
  vpc_id = "${aws_default_vpc.default.id}"
}

resource "aws_lb" "prod-nlb" {
  name = "prod-nlb"
  internal = false
  subnets = data.aws_subnet_ids.subnet.ids
  ip_address_type = "ipv4"
  load_balancer_type = "network"
}

resource "aws_lb_listener" "prod-nlb-listener" {
  load_balancer_arn = aws_lb.prod-nlb.arn
    port 	       = 80
    protocol 	       = "TCP"
    default_action {
      target_group_arn = "${aws_lb_target_group.NLB_check.arn}"
      type             = "forward"
      }
}
resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.NLB_check.arn
  target_id = aws_instance.prod-web-server-1.id
}

resource "aws_lb_target_group_attachment" "ec2_attach1" {
  target_group_arn = aws_lb_target_group.NLB_check.arn
  target_id = aws_instance.prod-web-server-2.id
}







