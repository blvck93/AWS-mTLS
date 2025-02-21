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

resource "aws_iam_policy" "lambda_vpc_access" {
  name        = "LambdaVPCAccessPolicy"
  description = "Allows Lambda to access VPC resources"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_policy_attach" {
  policy_arn = aws_iam_policy.lambda_vpc_access.arn
  role       = aws_iam_role.lambda_exec.name
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

  vpc_config {
    subnet_ids         = [aws_subnet.webapp_subnet_1.id]  # Use the correct subnet
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

#  environment {
#    variables = {
#      EC2_URL = "http://${aws_instance.webapp_ec2.private_ip}"  # Use Private IP
#    }
#  }

  source_code_hash = filebase64sha256(data.archive_file.lambda_package.output_path)
  filename         = data.archive_file.lambda_package.output_path
}


data "archive_file" "lambda_package" {
  type        = "zip"
  output_path = "lambda.zip"

  source {
    content  = <<EOF
import json
import hashlib
import base64
import urllib.parse

def lambda_handler(event, context):
    headers = event.get("headers", {})

    # Extract the full client certificate (URL-encoded PEM format)
    cert_pem_encoded = headers.get("x-amzn-mtls-clientcert-leaf", None)

    if cert_pem_encoded:
        try:
            # Decode URL-encoded PEM certificate
            cert_pem = urllib.parse.unquote(cert_pem_encoded)

            # Convert PEM to DER (binary format) by stripping header/footer and base64 decoding
            cert_pem_body = cert_pem.replace("-----BEGIN CERTIFICATE-----", "").replace("-----END CERTIFICATE-----", "").replace("\n", "")
            cert_der = base64.b64decode(cert_pem_body)

            # Compute SHA-1 Thumbprint
            thumbprint = hashlib.md5(cert_der).hexdigest().upper()

        except Exception as e:
            thumbprint = f"Error computing thumbprint: {str(e)}"

    else:
        thumbprint = "No Certificate Provided"

    # Log all headers for debugging
    print("Received Headers:", json.dumps(headers, indent=2))

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "client_cert_thumbprint": thumbprint,
            "all_headers": headers  # Return headers for debugging (optional)
        })
    }


EOF
    filename = "index.py"
  }
}
