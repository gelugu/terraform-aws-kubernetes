resource "aws_security_group" "all" {
  name        = "allow all"
  description = "Allow all traffic"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description      = "Allow all traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow all traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}_k8s-allow_all"
  }
}
