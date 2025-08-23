resource "aws_instance" "web" {
  ami           = data.aws_ami.rhel-9.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_eksctl.id]
  subnet_id = "subnet-0872f08f5da457eb0"
  user_data = file("workstation.sh")

  tags = {
    Name = "eksctl-workstation"
  }
}

resource "aws_security_group" "allow_eksctl" {
  name        = "allow-eksctl"
  description = "created for eksctl"
  #vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow-eksctl"
  }
  ingress {
      description = "Allow all inbound ports in eksctl"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      #ipv6_cidr_blocks = ["::/0"]
    }

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      #ipv6_cidr_blocks = ["::/0"]
    }

}

data "aws_ami" "rhel-9"{
    owners = ["973714476881"]
    most_recent = true

    filter {
        name = "name"
        values = ["RHEL-9-DevOps-Practice"]
    }

    filter {
        name = "root-device-type"
        values = ["ebs"]
    }   

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}