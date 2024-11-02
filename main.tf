  
resource "aws_s3_bucket" "canary_results" {
  bucket = "canary-bucket-test-24"
  acl    = "private"
}
  
  module "iam" {
    source = "./module/iam"
    
  }

  
  resource "aws_instance" "green_instance" {
    ami           = data.aws_ssm_parameter.nexjs_ami.value  # Use the AMI ID passed from GitLab
    instance_type = "t2.micro"  # Specify your instance type
    tags = {
      Name = "NextJS App Instance"
      Id = "nextjs-dev"
      instance = "green"
    }

    vpc_security_group_ids = [aws_security_group.nextjs_sg.id]
    
    # Create EC2 instance and attach IAM role 
    iam_instance_profile = module.iam.ec2_profile_name

  }

  resource "aws_instance" "blue_instance" {
    ami           = data.aws_ssm_parameter.nexjs_ami.value  # Use the AMI ID passed from GitLab
    instance_type = "t2.micro"  # Specify your instance type
    tags = {
      Name = "NextJS App Instance"
      Id = "nextjs-dev"
      instance = "blue"
    }

    vpc_security_group_ids = [aws_security_group.nextjs_sg.id]
    
    # Create EC2 instance and attach IAM role 
    iam_instance_profile = module.iam.ec2_profile_name

  }
  
  #module "canary_green" {
  #  source = "./module/canaries"
  #  canary_bucket = aws_s3_bucket.canary_results.bucket
  #  instance_ip = aws_instance.green_instance.public_ip
  #  canary_name = "green_canary"
  #  canary_role_arn = module.iam.canary_role_arn

  #}

  #module "canary_blue" {
  #  source = "./module/canaries"
  #  canary_bucket = aws_s3_bucket.canary_results.bucket
  #  instance_ip = aws_instance.green_instance.public_ip
  #  canary_name = "blue_canary"
  # canary_role_arn = module.iam.canary_role_arn

  #}



  
  resource "aws_security_group" "nextjs_sg" {
    name        = "nextjs_sg"
    description = "Security group for nextjs EC2 instance"
    vpc_id      = data.aws_ssm_parameter.vpc_id.value  # Replace with your VPC ID
  
    # Allow SSH access (port 22) from your IP (replace with your actual IP)
    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  # Replace with your public IP address
    }
    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  # Replace with your public IP address
    }
  
    ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  # Replace with your public IP address
    }

    # Allow outbound traffic to Kinesis
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"  # Allow all protocols
      cidr_blocks = ["0.0.0.0/0"]  # Allows outbound access to all destinations
    }
  
    tags = {
      Name = "nextjs_sg"
    }
  }

  
  

  resource "aws_security_group" "nextjs_sg_alb" {
    name        = "nextjs_sg_alb"
    description = "Security group for EC2 instance ALB"
    vpc_id      = data.aws_ssm_parameter.vpc_id.value  # Replace with your VPC ID
  
   
    ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  # Replace with your public IP address
    }

    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  # Replace with your public IP address
    }
    # Allow outbound traffic to Kinesis
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"  # Allow all protocols
      cidr_blocks = ["0.0.0.0/0"]  # Allows outbound access to all destinations
    }
  
    tags = {
      Name = "nextjs_sg_alb"
    }
  }

  resource "aws_lb" "nextjs_alb" {
    name               = "nextjs-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.nextjs_sg_alb.id]
    subnets            = data.aws_subnets.public_subnets.ids
  
    tags = {
      Name = "Next.js ALB"
    }
  }

 # resource "aws_acm_certificate" "alb_cert" {
 #   domain_name       = "*.${var.region}.elb.amazonaws.com"
 #   validation_method = "DNS"
 # }
  
  resource "aws_lb_listener" "https_listener" {
    load_balancer_arn = aws_lb.nextjs_alb.arn
    port              = "80"
    protocol          = "HTTP"
  #  ssl_policy        = "ELBSecurityPolicy-2016-08"
  #  certificate_arn   = aws_acm_certificate.alb_cert.arn
  
    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.nextjs_green_tg.arn
    }
  }
  
  resource "aws_lb_target_group" "nextjs_green_tg" {
    name     = "nextjs-green-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = data.aws_ssm_parameter.vpc_id.value
  
    health_check {
      path                = "/"
      interval            = 30
      timeout             = 5
      healthy_threshold   = 5
      unhealthy_threshold = 2
    }
  }
  
  resource "aws_lb_target_group" "nextjs_blue_tg" {
    name     = "nextjs-blue-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = data.aws_ssm_parameter.vpc_id.value
  
    health_check {
      path                = "/"
      interval            = 30
      timeout             = 5
      healthy_threshold   = 5
      unhealthy_threshold = 2
    }
  }

  resource "aws_lb_target_group_attachment" "green_instance_attachment" {
    target_group_arn = aws_lb_target_group.nextjs_green_tg.arn
    target_id        = aws_instance.green_instance.id
    port             = 80
  }
  
  resource "aws_lb_target_group_attachment" "blue_instance_attachment" {
    target_group_arn = aws_lb_target_group.nextjs_blue_tg.arn
    target_id        = aws_instance.blue_instance.id
    port             = 80
  }



  resource "aws_sns_topic" "alerts" {
    name = "cloudwatch_alerts"
  }
  
  resource "aws_sns_topic_subscription" "email_alert" {
    topic_arn = aws_sns_topic.alerts.arn
    protocol  = "email"
    endpoint  = var.email_id  # Replace with your email
  }

  resource "aws_cloudwatch_log_group" "log_group" {
    name              = "/pm2/logs"
    retention_in_days = 7
  }

  module "cloudwatch_green" {
    source = "./module/cloudwatch"
    instance_id = aws_instance.green_instance.id
    sns_topic_arn = aws_sns_topic.alerts.arn
    name = "green"
    log_group_name = aws_cloudwatch_log_group.log_group.name

  }

  module "cloudwatch_blue" {
    source = "./module/cloudwatch"
    instance_id = aws_instance.blue_instance.id
    sns_topic_arn = aws_sns_topic.alerts.arn
    name = "blue"
    log_group_name = aws_cloudwatch_log_group.log_group.name

  }
  