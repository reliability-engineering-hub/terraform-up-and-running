
# aws provider
provider "aws" {
  region = var.region
}

# create aws instance
resource "aws_instance" "example" {
  ami                    = "ami-0e38c97339cddf4bd"
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
                   #!/bin/bash
                   echo "Hello, World" > index.html
                   nohup busybox httpd -f -p ${var.server_port} &
                   EOF

  tags = {
    Name = "terraform-example"
  }
}

# create aws security group
resource "aws_security_group" "instance" {
  name   = "terraform-example-instance"
  vpc_id = data.aws_vpc.default.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
  }
}
