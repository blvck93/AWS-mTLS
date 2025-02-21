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
  source_arn    = aws_lb_target_group.api_tg.arn
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
import urllib3
import os

http = urllib3.PoolManager()

# Replace with your EC2 instance's public DNS/IP
EC2_URL = os.getenv("EC2_URL", "https://10.0.0.76")  # Example: https://54.123.45.67

def lambda_handler(event, context):
    headers = event.get("headers", {})
    path = event.get("path", "/")
    method = event.get("httpMethod", "GET")
    query_string_params = event.get("queryStringParameters", {})
    body = event.get("body", "")

    # Convert query parameters to string
    query_string = ""
    if query_string_params:
        query_string = "?" + "&".join([f"{key}={value}" for key, value in query_string_params.items()])

    # Handle ALB health check
    if path == "/health":
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "text/plain"},
            "body": "Healthy"
        }

    # Extract client certificate thumbprint
    cert_thumbprint = headers.get("x-amzn-tls-tls-client-cert-thumbprint", "No Certificate Provided")

    if cert_thumbprint != "No Certificate Provided":
        thumbprint_hash = hashlib.md5(cert_thumbprint.encode()).hexdigest()
    else:
        thumbprint_hash = "None"

    # Forward request to EC2
    backend_url = f"{EC2_URL}{path}{query_string}"  # Preserve original path & query params
    forward_headers = {key: value for key, value in headers.items()}  # Copy all headers
    forward_headers["x-client-cert-thumbprint"] = thumbprint_hash  # Add certificate thumbprint

    # Forward request to EC2
    response = http.request(
        method=method,
        url=backend_url,
        headers=forward_headers,
        body=body.encode() if body else None
    )

    return {
        "statusCode": response.status,
        "headers": dict(response.headers),
        "body": response.data.decode("utf-8")
    }


EOF
    filename = "index.py"
  }
}
