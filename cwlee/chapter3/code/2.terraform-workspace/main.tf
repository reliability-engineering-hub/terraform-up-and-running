# create ec2
resource "aws_instance" "example" {
  ami           = "ami-0e38c97339cddf4bd"
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.public_subnet.id
}

# create security group
locals {
  sg_name = terraform.workspace == "default" ? "allow_tls" : "allow_tls-${terraform.workspace}"
}

resource "aws_security_group" "example" {
  name        = local.sg_name
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = local.sg_name
  }
}
