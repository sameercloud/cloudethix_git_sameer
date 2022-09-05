provider "aws" {
  region = "us-east-1"
}

################### VPC CONFIGURATION ###################################################

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "myvpc"
  }
}
#################### INTERNET GATEWAY ########################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "internetget"
  }
}

################################ nat gateway ########################################

resource "aws_nat_gateway" "net" {
  allocation_id = aws_eip.lb.id

  subnet_id = aws_subnet.public_subnet.id
}

############################### PRIVATE SUBNET #############################################

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private"
  }
}

###################################PUBLIC SUBNET ###########################################

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1e"

  tags = {
    Name = "public"
  }
}

################################# PRIVATE ROUTE TABLE ########################################

resource "aws_route_table" "private_table" {
  vpc_id = aws_vpc.myvpc.id

  route = []

  tags = {
    Name = "private_route"
  }
}

###################################### PRIVATE ROUTE ########################################

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.net.id
  depends_on             = [aws_route_table.private_table] # basically it means that when public route table is created then after this route wil create
}



################################# PUBLIC ROUTE  ##########################################

resource "aws_route_table" "public_table" {
  vpc_id = aws_vpc.myvpc.id

  route = []

  tags = {
    Name = "public_route"
  }
}

##################################### public route table #####################################

resource "aws_route" "private_route_table" {
  route_table_id         = aws_route_table.public_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on             = [aws_route_table.public_table] # basically it means that when public route table is created then after this route wil create
}
############################################################

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_table.id
}
#########################################################

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_table.id
}

################################################################

resource "aws_security_group" "sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0    # all ports
    protocol    = "-1" # all traffic 
    cidr_blocks = ["0.0.0.0/0"]

    ipv6_cidr_blocks = null
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "terraform"
  }
}
########################################################################################

###################### instance configuration ###########################################

resource "aws_instance" "public" {
  ami           = "ami-02538f8925e3aa27a"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = "lenovo"

}
############################################################################################################
resource "aws_instance" "private" {
  ami           = "ami-02538f8925e3aa27a"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  key_name      = "lenovo"

}

resource "aws_eip" "lb" {
  instance = aws_instance.private.id
  vpc      = true
}





