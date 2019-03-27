

provider "aws" {
  region = "us-east-1"
}


output "public_ip" {  value = "${aws_instance.example.public_ip}"}
output "public_ip1" {  value = "${aws_instance.example1.public_ip}"}



resource "aws_security_group" "instance" {
    name = "webserver_sec_grp" 
    vpc_id = "vpc-98d97dfd" 
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
 
}



resource "aws_instance" "example" {
  ami           = "ami-011b3ccf1bd6db744"
  instance_type = "t2.micro"
  security_groups= ["${aws_security_group.instance.id}"]
  subnet_id = "subnet-73a36704"
  user_data_base64 ="IyEvYmluL2Jhc2gKeXVtIHVwZGF0ZSAteQp5dW0gaW5zdGFsbCBodHRwZCAteQp5dW0gY2xlYW4gYWxsIAoKZWNobyAiSGVsbG8gV29ybGQgdjIiID4gL3Zhci93d3cvaHRtbC9pbmRleC5odG1sCgpzeXN0ZW1jdGwgZW5hYmxlIGh0dHBkCnN5c3RlbWN0bCBzdGFydCBodHRwZAoKCg=="
  tags {
    Name = "testserver"

  }

}

resource "aws_instance" "example1" {
  ami           = "ami-011b3ccf1bd6db744"
  instance_type = "t2.micro"
  security_groups=["${aws_security_group.instance.id}"]
  subnet_id = "subnet-73a36704"
  user_data_base64="IyEvYmluL2Jhc2gKeXVtIHVwZGF0ZSAteQp5dW0gaW5zdGFsbCBodHRwZCAteQp5dW0gY2xlYW4gYWxsIAoKZWNobyAiSGVsbG8gV29ybGQgdjIiID4gL3Zhci93d3cvaHRtbC9pbmRleC5odG1sCgpzeXN0ZW1jdGwgZW5hYmxlIGh0dHBkCnN5c3RlbWN0bCBzdGFydCBodHRwZAoKCg=="
  tags {
    Name = "testserver1"

  }

}



