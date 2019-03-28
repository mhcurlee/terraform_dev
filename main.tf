

provider "aws" {
  region = "us-east-1"
}


output "public_ip" {  value = "${aws_instance.example.public_ip}"}
output "public_ip1" {  value = "${aws_instance.example1.public_ip}"}


resource "aws_vpc" "testvpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "testvpc"
  }
}

resource "aws_subnet" "testsubnet" {
  vpc_id = "${aws_vpc.testvpc.id}"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "testsubnet"
  }

}

resource "aws_internet_gateway" "test_vpc_gw" {
  vpc_id = "${aws_vpc.testvpc.id}"

  tags = {
    Name = "testvpn_gw"
  }
}


resource "aws_route_table"  "test_vpc_route_table" {
  vpc_id = "${aws_vpc.testvpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.test_vpc_gw.id}"

  }
}

resource "aws_route_table_association" "test_vpc_route_table_association" {
  subnet_id      = "${aws_subnet.testsubnet.id}"
  route_table_id = "${aws_route_table.test_vpc_route_table.id}"
}





resource "aws_security_group" "instance" {
    name = "webserver_sec_grp" 
    vpc_id = "${aws_vpc.testvpc.id}" 
    ingress {    
      from_port   = 80    
      to_port     = 80   
      protocol    = "tcp"    
      cidr_blocks = ["0.0.0.0/0"]  }

    ingress {    
      from_port   = 22    
      to_port     = 22   
      protocol    = "tcp"    
      cidr_blocks = ["0.0.0.0/0"]  }  

     egress {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
    
  }



  
 
}



resource "aws_instance" "example" {
  ami           = "ami-011b3ccf1bd6db744"
  instance_type = "t2.micro"
  security_groups= ["${aws_security_group.instance.id}"]
  subnet_id = "${aws_subnet.testsubnet.id}"
  user_data_base64 ="IyEvYmluL2Jhc2gKeXVtIHVwZGF0ZSAteQp5dW0gaW5zdGFsbCBodHRwZCAteQp5dW0gY2xlYW4gYWxsIAoKZWNobyAiSGVsbG8gV29ybGQgdjIiID4gL3Zhci93d3cvaHRtbC9pbmRleC5odG1sCgpzeXN0ZW1jdGwgZW5hYmxlIGh0dHBkCnN5c3RlbWN0bCBzdGFydCBodHRwZAoKCg=="
  tags {
    Name = "testserver"

  }

}

resource "aws_instance" "example1" {
  ami           = "ami-011b3ccf1bd6db744"
  instance_type = "t2.micro"
  security_groups=["${aws_security_group.instance.id}"]
  subnet_id = "${aws_subnet.testsubnet.id}"
  user_data_base64="IyEvYmluL2Jhc2gKeXVtIHVwZGF0ZSAteQp5dW0gaW5zdGFsbCBodHRwZCAteQp5dW0gY2xlYW4gYWxsIAoKZWNobyAiSGVsbG8gV29ybGQgdjIiID4gL3Zhci93d3cvaHRtbC9pbmRleC5odG1sCgpzeXN0ZW1jdGwgZW5hYmxlIGh0dHBkCnN5c3RlbWN0bCBzdGFydCBodHRwZAoKCg=="
  tags {
    Name = "testserver1"

  }

}




