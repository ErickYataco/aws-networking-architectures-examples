resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh-traffic"
  description = "Allow ssh traffic on 22"
  vpc_id      = module.vpc-public.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "jump-box" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t3.micro"
  subnet_id         = module.vpc-public.public_subnets[0]
  key_name          = "eys-demo"
  security_groups   = [aws_security_group.allow_ssh.id, module.vpc-public.default_security_group_id]


  tags = {
    Name = "JumpBox"
  }
}

resource "aws_instance" "private_in_public_sn" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = module.vpc-public.private_subnets[0]
  key_name      = "eys-demo"
 

  tags = {
    Name = "private_in_public_sn"
  }
}

resource "aws_instance" "private" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = module.vpc-private.private_subnets[0]
  key_name      = "eys-demo"
 

  tags = {
    Name = "private"
  }
}