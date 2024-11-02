

  resource "aws_synthetics_canary" "canary" {
    name       = var.canary_name
    artifact_s3_location = "s3://${var.canary_bucket}/${var.canary_name}"
    execution_role_arn   = var.canary_role_arn
  
    runtime_version = "syn-nodejs-puppeteer-9.1"
    schedule {
      expression = "rate(5 minutes)"  # Run every 5 minutes
    }
  
    start_canary = true
  
    handler = "script.handler"
    
    
    zip_file = "${path.module}/script.zip" # Replace with your Canary script zip
    
  
    run_config {
        timeout_in_seconds = 60
        memory_in_mb       = 500
        environment_variables = {
          INSTANCE_URL = var.instance_ip   # Inject public IP of green EC2 instance
        }
      }
  }
  
  
  

  
  