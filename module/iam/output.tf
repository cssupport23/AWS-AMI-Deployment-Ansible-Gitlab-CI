output "ec2_profile_name" {
    value = aws_iam_instance_profile.nextjs_profile.name
}

output "canary_role_arn" {
    value = aws_iam_role.canary_role.arn
}