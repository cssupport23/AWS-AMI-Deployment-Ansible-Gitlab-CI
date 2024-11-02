data "aws_ssm_parameter" "env" {
    name = "env"
  }
  
  data "aws_ssm_parameter" "vpc_id" {
    name = "vpc_id"
  }
  
  data "aws_region" "current" {}
  
  data "aws_caller_identity" "current" {}
  
  data "aws_partition" "current" {}

  data "aws_ssm_parameter" "nexjs_ami" {
    name = "/nextjs/ami-id"
  }

  data "aws_subnets" "public_subnets" {

    filter {
      name   = "vpc-id"
      values = [data.aws_ssm_parameter.vpc_id.value]
    }
  }