provider "aws" {
    region = "us-west-1"
  
}

#vpc
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
      Name = "techhealth_vpc"
    }
  
}

#public Subnet 1AZ

resource "aws_subnet" "public-subnet1a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-west-1a"

    tags = {
      Name = "public-subnet1a"
    }
  
}

#private Subnet 1AZ

resource "aws_subnet" "private-subnet1b" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.16.0/24"
    map_public_ip_on_launch = false
    availability_zone = "us-west-1a"

    tags = {
      Name = "private-subnet1b"
    }
  
}

#Private subnet 2AZ
resource "aws_subnet" "public-subnet2a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-west-1c"

    tags = {
      Name = "public-subnet2a"
    }
  
}

#private Subnet 1Z

resource "aws_subnet" "private-subnet2b" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.32.0/24"
    map_public_ip_on_launch = false
    availability_zone = "us-west-1c"

    tags = {
      Name = "private-subnet2b"
    }
  
}

#igw

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id

    tags = {
      Name = "igw"
    }
  
}
# public route
resource "aws_route_table" "public-rt" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
      Name = "public-rt"
    }
  
}

#1aroute table association
resource "aws_route_table_association" "public_assoc_1a" {
    subnet_id = aws_subnet.public-subnet1a.id
    route_table_id = aws_route_table.public-rt.id
  
}

#2a route table association
resource "aws_route_table_association" "public_assoc_2a" {
    subnet_id = aws_subnet.public-subnet2a.id
    route_table_id = aws_route_table.public-rt.id
  
}


#IAM instance profile

resource "aws_iam_instance_profile" "ec2_instance" {
  name = "EC2instance"
  role = aws_iam_role.ec2_rds_role.name
  
}

#EC2
# 


resource "aws_instance" "web-server" {
    ami = "ami-04fdea8e25817cd69"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public-subnet1a.id
    associate_public_ip_address = true
    vpc_security_group_ids = [ aws_security_group.web-server-sg.id ]
    key_name = aws_key_pair.web-key.key_name
    iam_instance_profile = aws_iam_instance_profile.ec2_instance.name

    tags = {
      Name = "public_webserver"
    }
  
}

resource "aws_instance" "web-server1a" {
    ami = "ami-04fdea8e25817cd69"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public-subnet2a.id
    associate_public_ip_address = true
    vpc_security_group_ids = [ aws_security_group.web-server-sg.id ]
    key_name = aws_key_pair.web-key.key_name

    tags = {
      Name = "public_1awebserver"
    }
  
}

#key
resource "aws_key_pair" "web-key" {
    key_name = "web-key"
    public_key = file("web-key.pem.pub")
  
}

#sg
resource "aws_security_group" "web-server-sg" {
  name = "web-server"
  description = "ssh access"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Name = "web-server"
  }
}


# private EC2

resource "aws_instance" "rds-private" {
    ami = "ami-04fdea8e25817cd69"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.private-subnet1b.id
    associate_public_ip_address = false
    vpc_security_group_ids = [ aws_security_group.rds-private-sg.id ]
    key_name = aws_key_pair.web-key.key_name

    tags = {
      Name = "rds_1awebserver"
    }
}

resource "aws_instance" "rds-private1" {
    ami = "ami-04fdea8e25817cd69"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.private-subnet2b.id
    associate_public_ip_address = false
    vpc_security_group_ids = [aws_security_group.rds-private-sg.id  ]
    key_name = aws_key_pair.web-key.key_name

    tags = {
      Name = "rds_2awebserver"
    }
}

#private SG

resource "aws_security_group" "rds-private-sg" {
    name = "rds-private-sg"
    description = "allow ssh access from webserver"
    vpc_id = aws_vpc.main.id

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
  
}
resource "aws_security_group_rule" "ssh-ec2" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_group_id = aws_security_group.rds-private-sg.id
    source_security_group_id = aws_security_group.web-server-sg.id
  
}


resource "aws_db_instance" "db_instance" {
    allocated_storage = 100
    engine = "mysql"
    engine_version = "8.0.34"
    instance_class = "db.t3.micro"
    username = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["username"]
    password = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["password"]
    vpc_security_group_ids = [aws_security_group.rds-sg.id  ]
    multi_az = false
    publicly_accessible = false 
    db_subnet_group_name = aws_db_subnet_group.wordserver-db.id
    skip_final_snapshot = true
    db_name = "webserver"
    identifier = "webserver-db"

    tags = {
      Name = "webserver-db"
    }
  
}

#rds Subnet Group
resource "aws_db_subnet_group" "wordserver-db" {
    name = "wordserver-db"
    subnet_ids = [aws_subnet.private-subnet1b.id,aws_subnet.private-subnet2b.id]

    tags = {
      Name = "wordserver-db-db"
    }
  
}

#SG

resource "aws_security_group" "rds-sg" {
    name = "rds-sg"
    description = "Allow rds to the private"
    vpc_id = aws_vpc.main.id

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

resource "aws_security_group_rule" "rds-sg1" {
    type = "ingress"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_group_id = aws_security_group.rds-sg.id
    source_security_group_id = aws_security_group.rds-private-sg.id
  
}