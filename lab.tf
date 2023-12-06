# Define VPC
resource "aws_vpc" "lab_vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "lab_vpc"
  }
}

#Define Subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.lab_vpc.id
  cidr_block = "192.168.100.0/24"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.lab_vpc.id
  cidr_block = "192.168.200.0/24"

  tags = {
    Name = "private"
  }
}

#Define Internet gateway
resource "aws_internet_gateway" "intgw" {
  vpc_id = aws_vpc.lab_vpc.id

  tags = {
    Name = "lab_vpc intgw"
  }
}

#Define public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.intgw.id
  }

  tags = {
    Name = "Route table for public subnet"
  }
}

#Association between public subnet and public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

#Elastic IP for NAT gateway
resource "aws_eip" "NAT_eip" {
  domain = "vpc"
  depends_on = [ aws_internet_gateway.intgw ]
  tags = {
    Name = "EIP for NAT gateway"
  }
}

#Define NAT gateway
resource "aws_nat_gateway" "NAT_gw" {
  allocation_id = aws_eip.NAT_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "lab_vpc NAT_gw"
  }
}

#Define private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NAT_gw.id
  }

  tags = {
    Name = "Route Table for private subnet"
  }
}

#Association between private subnet and private route table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}

#Define security group
resource "aws_security_group" "securitygp" {
  name        = "securitygp"
  vpc_id      = aws_vpc.lab_vpc.id

  ingress {
    description      = "rule1"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
  egress {
    description      = "rule2"
    from_port        = 0
    to_port          = 0
    protocol         = "-1" 
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
}

#Create instance in public subnet
resource "aws_instance" "webserver1" {
  ami           = "ami-0e83be366243f524a"
  instance_type = "t2.micro"
  subnet_id   = aws_subnet.public.id
  key_name   = "snda"
  vpc_security_group_ids = [aws_security_group.securitygp.id]
  associate_public_ip_address = true
  tags = {
    Name = "webserver1"
  }
}

#Create instance in private subnet
resource "aws_instance" "webserver2" {
  ami           = "ami-0e83be366243f524a"
  instance_type = "t2.micro"
  subnet_id   = aws_subnet.private.id
  key_name   = "snda"
  vpc_security_group_ids = [aws_security_group.securitygp.id]
  associate_public_ip_address = false
  tags = {
    Name = "webserver2"
  }
}

