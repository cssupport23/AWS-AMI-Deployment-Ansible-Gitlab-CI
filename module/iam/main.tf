resource "aws_iam_role" "nextjs_role" {
    name = "nextjs_role"
  
    assume_role_policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [{
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }]
    })
  }
  

  
resource "aws_iam_instance_profile" "nextjs_profile" {
name = "nextjs_profile"
role = aws_iam_role.nextjs_role.name
}

resource "aws_iam_role_policy" "nextjs_policy" {
    role = aws_iam_role.nextjs_role.id
  
    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "cloudwatch:PutMetricData",
            "logs:DescribeLogStreams",
            "cloudwatch:GetMetricStatistics",
            "cloudwatch:ListMetrics",
            "ec2:DescribeTags"
          ],
          "Resource": "*"
        }
      ]
    })
  }

  resource "aws_iam_role" "canary_role" {
    name = "CloudWatchSyntheticsCanaryRole"
  
    assume_role_policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    })
  }
  
  resource "aws_iam_policy" "canary_policy" {
    name = "CloudWatchSyntheticsCanaryPolicy"
    
    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "s3:PutObject",
            "s3:GetBucketLocation",
            "cloudwatch:PutMetricData"
          ],
          "Resource": "*"
        }
      ]
    })
  }
  
  resource "aws_iam_role_policy_attachment" "attach_policy" {
    role       = aws_iam_role.canary_role.name
    policy_arn = aws_iam_policy.canary_policy.arn
  }
  


