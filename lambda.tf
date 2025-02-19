resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_lambda_permission" "alb_lambda" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mtls_lambda.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
}

# outputs.tf
output "alb_dns_name" {
  value = aws_lb.webapp_alb.dns_name
}

resource "aws_lambda_function" "mtls_lambda" {
  function_name    = "mtls-check"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.lambda_handler"
  runtime         = "python3.8"

  source_code_hash = filebase64sha256(data.archive_file.lambda_package.output_path)

  filename = data.archive_file.lambda_package.output_path
}

data "archive_file" "lambda_package" {
  type        = "zip"
  output_path = "lambda.zip"

  source {
    content  = <<EOF
import json
import hashlib

def lambda_handler(event, context):
    headers = event.get("headers", {})
    cert_thumbprint = headers.get("x-amzn-tls-tls-client-cert-thumbprint", "No Certificate Provided")
    if cert_thumbprint != "No Certificate Provided":
        thumbprint_hash = hashlib.md5(cert_thumbprint.encode()).hexdigest()
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "text/plain"},
            "body": f"Client Certificate Thumbprint Hash: {thumbprint_hash}"
        }
    return {
        "statusCode": 403,
        "headers": {"Content-Type": "text/plain"},
        "body": "No valid certificate"
    }
EOF
    filename = "index.py"
  }
}
