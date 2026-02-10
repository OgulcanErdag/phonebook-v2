# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group

resource "aws_lb_target_group" "app-lb-tg" {
  name        = "phonebook-lb-tg"
  port        = 80                       #  Required when target_type is instance, ip or alb
  protocol    = "HTTP"                   #  Required when target_type is instance, ip, or alb
  vpc_id      = data.aws_vpc.selected.id # Required when target_type is instance, ip or alb
  target_type = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
# ids!!!! = https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets

resource "aws_lb" "app-lb" {
  name               = "phonebook-lb-tf"
  ip_address_type    = "ipv4"
  internal           = false # private
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = data.aws_subnets.pb-subnets.ids # ids !!! https://docs.tf.k2.cloud/d/subnets.html?utm_source .Third-party Terraform provider Doc
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener 

resource "aws_lb_listener" "app-listener" {
  load_balancer_arn = aws_lb.app-lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app-lb-tg.arn
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
# https://developer.hashicorp.com/terraform/language/functions/templatefile  # for userdata with veriables

resource "aws_launch_template" "asg-lt" {
  name                   = "phonebook-lt"
  image_id               = data.aws_ami.al2023.id
  instance_type          = var.instance-type
  key_name               = var.key-name
  vpc_security_group_ids = [aws_security_group.server-sg.id]
  user_data              = base64encode(templatefile("userdata.sh", { db_endpoint = aws_db_instance.db_server.address, user-data-git-token = var.git-token, user-data-git-name = var.git-name }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Web Server of Phonebook App"
    }
  }
  depends_on = [aws_db_instance.db_server]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
# https://developer.hashicorp.com/terraform/language/expressions/references

resource "aws_autoscaling_group" "app-asg" {
  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 1
  name                      = "phonebook-asg"
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.app-lb-tg.arn]
  vpc_zone_identifier       = aws_lb.app-lb.subnets # subnets-->https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb#argument-reference
  launch_template {
    id      = aws_launch_template.asg-lt.id
    version = aws_launch_template.asg-lt.latest_version # version = "$Latest"  This syntax also possible https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#argument-reference
  }                                                     #https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#attribute-reference      
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance

resource "aws_db_instance" "db_server" {
  instance_class              = "db.t3.micro"
  allocated_storage           = 20
  vpc_security_group_ids      = [aws_security_group.db-sg.id]
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  backup_retention_period     = 0
  identifier                  = "phonebook-app-db"
  db_name                     = "phonebook"
  engine                      = "mysql"
  engine_version              = "8.0.44"
  username                    = "admin"
  password                    = "OgulcanErdag_1"
  monitoring_interval         = 0
  multi_az                    = false
  port                        = 3306
  publicly_accessible         = false
  skip_final_snapshot         = true # desable snapshot
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record

resource "aws_route53_record" "phonebook" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "phonebook.${var.hosted-zone}"
  type    = "A"

  alias {
    name                   = aws_lb.app-lb.dns_name
    zone_id                = aws_lb.app-lb.zone_id
    evaluate_target_health = true
  }
}

# Evaluate Target Health: Use the target group's health check status.

# Health Check: Route 53 actively checks the endpoint itself.
