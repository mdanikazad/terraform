
resource "aws_vpc" "my_vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "my_public_subnet_1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev_public_subnet_1"
  }

}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "dev_igw"
  }
}

resource "aws_route_table" "my_public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.my_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

resource "aws_route_table_association" "my_public_assoc" {
  subnet_id      = aws_subnet.my_public_subnet_1.id
  route_table_id = aws_route_table.my_public_rt.id
}

resource "aws_security_group" "mysg" {
  name        = "my_sg"
  description = "my security group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress = [
    {
      description      = "HTTP"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },

  ]
  egress = [
    {
      description      = "for all outgoing traffics"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}

resource "aws_key_pair" "my_key" {
  key_name   = "mykey"
  public_key = file("~/.ssh/id_rsa.pub")

}

resource "aws_instance" "dev-node" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.my_key.id
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id              = aws_subnet.my_public_subnet_1.id
  user_data = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-node"
  }

  provisioner "local-exec" {
      command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname = self.public_ip
      user = "ubuntu"
      IdentityFile = "~/.ssh/id_rsa"
      })
      interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
    
  }

}

