# GitLab CI/CD Pipeline for AWS AMI Deployment Using Terraform and Ansible

## Overview
This project automates the deployment of an AWS AMI and execution of an Ansible configuration using a GitLab CI/CD pipeline integrated with Terraform and Ansible. The pipeline manages infrastructure resources such as ELB, EC2 instances for blue-green deployments, and configures CloudWatch for logging and monitoring.

## Pipeline Structure
The pipeline consists of the following stages:

1. **Validate**: Validates the Terraform configuration.
2. **Plan**: Creates an execution plan for the infrastructure.
3. **Apply**: Deploys the infrastructure as defined in the plan.
4. **Setup**: Configures the EC2 instances using Ansible.
5. **Destroy**: Destroys the deployed infrastructure when needed.

## Pipeline Configuration
```yaml
image:
  name: hashicorp/terraform
  entrypoint: [""]

cache:
  policy: pull-push
  paths:
    - .terraform/*.*

variables:
  S3_BUCKET_SSM: 'terrformback-bucket'
  S3_FOLDER_SSM: 'terrformback-bucket-dev'
  EC2_KEYS_PRI_SSM: 'ec2_keys_private'

stages:
  - validate
  - plan
  - apply
  - setup
  - destroy

before_script:
  - apk add --no-cache bash parallel aws-cli zip
  - aws s3 ls
  - zip -r module/canaries/script.zip module/canaries/script.js
  - S3_BE_BUCKET=$(aws ssm get-parameter --name "${S3_BUCKET_SSM}" --query 'Parameter.Value' --output text)
  - S3_BE_FOLDER=$(aws ssm get-parameter --name "${S3_FOLDER_SSM}" --query 'Parameter.Value' --output text)
  - terraform init -backend-config="bucket=${S3_BE_BUCKET}" -backend-config="key=${S3_BE_FOLDER}/$CI_PROJECT_NAME/$CI_COMMIT_REF_NAME" -backend-config="region=ap-south-1"
```

### Stage Details
- **Validate Stage**
  ```yaml
  validate:
    stage: validate
    script:
      - ls -alh
      - echo "$CI_COMMIT_REF_NAME.tfvars"
      - terraform validate
    tags:
      - aws
  ```

- **Plan Stage**
  ```yaml
  plan:
    stage: plan
    script: terraform plan -var-file "$CI_COMMIT_REF_NAME.tfvars" -out=plan.out
    tags:
      - aws
    artifacts:
      when: on_success
      expire_in: "30 days"
      paths:
        - "plan.out"
  ```

- **Apply Stage**
  ```yaml
  apply:
    stage: apply
    script: terraform apply -auto-approve plan.out
    tags:
      - aws
    when: manual
  ```

- **Setup Stage**
  ```yaml
  setup:
    stage: setup
    image: alpine:latest
    before_script:
      - apk add --no-cache bash parallel python3 py3-pip curl aws-cli ansible openssh
      - ansible-galaxy collection install amazon.aws
      - rm /usr/lib/python3.12/EXTERNALLY-MANAGED
      - pip install boto3 botocore
    script:
      - EC2_KEY_PRIVATE=$(aws ssm get-parameter --name "${EC2_KEYS_PRI_SSM}" --query 'Parameter.Value' --output text)
      - echo "$EC2_KEY_PRIVATE" > ec2_keys.pem
      - chmod 400 ec2_keys.pem
      - mv ec2_keys.pem ansible/ec2_keys.pem
      - export ANSIBLE_HOST_KEY_CHECKING=False
      - cd ansible
      - ansible-inventory -i inventory/aws_ec2.yml --graph
      - ansible-playbook -i inventory/aws_ec2.yml playbook.yml -u ec2-user --private-key ec2_keys.pem
    tags:
      - aws
    when: manual
  ```

- **Destroy Stage**
  ```yaml
  destroy:
    stage: destroy
    script: terraform destroy -auto-approve -var-file "$CI_COMMIT_REF_NAME.tfvars"
    tags:
      - aws
    when: manual
  ```

## Ansible Configuration
The Ansible playbook `playbook.yml` performs the following tasks:
- Retrieves the instance metadata and ID.
- Installs and configures the CloudWatch Agent.
- Installs Node.js and PM2 for managing the Next.js application.
- Deploys and builds the Next.js app.
- Sets up PM2 for log rotation and ensures the application restarts on reboot.

### Sample Tasks
```yaml
- name: Get metadata token for IMDSv2
  uri:
    url: "http://169.254.169.254/latest/api/token"
    method: PUT
    headers:
      X-aws-ec2-metadata-token-ttl-seconds: "21600"
    status_code: 200
    return_content: yes
  register: imds_token

- name: Install Node.js
  yum:
    name: nodejs
    state: present
    enablerepo: epel

- name: Start the Next.js app with PM2
  command: pm2 start npm --name "nextjs-app" -- start
  args:
    chdir: /var/www/html
  environment:
    PORT: 80

- name: Set PM2 to restart app on reboot
  command: pm2 save
```

## Infrastructure Resources
### Terraform Configurations
- **EC2 Instances**: Blue and green EC2 instances for deployment.
- **Security Groups**: Configured for secure access and communication.
- **ALB**: Application Load Balancer for traffic routing.
- **CloudWatch**: Configured for logging and alerts.
- **IAM Roles**: Managed through modules for EC2 and canary setups.

### Sample EC2 Configuration
```hcl
resource "aws_instance" "green_instance" {
  ami           = data.aws_ssm_parameter.nexjs_ami.value
  instance_type = "t2.micro"
  tags = {
    Name      = "NextJS App Instance"
    Id        = "nextjs-dev"
    instance  = "green"
  }
  vpc_security_group_ids = [aws_security_group.nextjs_sg.id]
  iam_instance_profile   = module.iam.ec2_profile_name
}
```

## Additional Modules
- **IAM Module**: Manages IAM roles and instance profiles.
- **CloudWatch Module**: Sets up monitoring and integrates with SNS for alerts.


