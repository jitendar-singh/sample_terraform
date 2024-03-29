resource "aws_vpc" "myvpc" {
    cidr_block = var.vpc_cidr
}

resource "aws_subnet" "sub1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "myig" {
    vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myig.id
  }
}

resource "aws_route_table_association" "rt_association_sub1" {
  subnet_id = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rt_association_sub2" {
    subnet_id = aws_subnet.sub2.id
    route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id
  
  ingress {
    description = "HTTP from VPC"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
  }
  ingress {
    description = "SSH to EC2"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
  }
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_tls"
  }

}

resource "aws_s3_bucket" "mys3" {
    bucket = "jitsingh-s3-buck9"
}

resource "aws_instance" "web-server1" {
    ami = "ami-007020fd9c84e18c7"
    key_name = "jitsingh-key"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.allow_tls.id]
    subnet_id = aws_subnet.sub1.id
    user_data = base64encode(file("user_data.sh"))
}
resource "aws_instance" "web-server2" {
    ami = "ami-007020fd9c84e18c7"
    key_name = "jitsingh-key"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.allow_tls.id]
    subnet_id = aws_subnet.sub2.id
    user_data = base64encode(file("user_data1.sh"))
}

resource "aws_lb" "mylb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_tls.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]
}

resource "aws_lb_target_group" "mylb_tg" {
  name     = "app-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "mylb_tg_attachment-1" {
  target_group_arn = aws_lb_target_group.mylb_tg.arn
  target_id        = aws_instance.web-server1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "mylb_tg_attachment-2" {
  target_group_arn = aws_lb_target_group.mylb_tg.arn
  target_id        = aws_instance.web-server2.id
  port             = 80
}
resource "aws_lb_listener" "listner" {
    load_balancer_arn = aws_lb.mylb.arn
    protocol = "HTTP"
    port = 80

    default_action {
      target_group_arn = aws_lb_target_group.mylb_tg.arn
      type = "forward"
    }
}

output "Loadbalancer_dns" {
    value = aws_lb.mylb.dns_name
  
}




























