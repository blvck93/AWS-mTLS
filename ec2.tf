resource "aws_instance" "webapp_ec2" {
  ami           = "ami-053a45fff0a704a47" # Updated with a placeholder, verify correct AMI ID
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.webapp_subnet_1.id
  vpc_security_group_ids = [aws_security_group.webapp_sg.id]
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              echo '<h1>Static Website</h1>' > /var/www/html/index.html
              echo '<h1>API: ' > /var/www/html/api.html
              echo $HTTP_CLIENT_THUMBPRINT >> /var/www/html/api.html
              echo '</h1>' >> /var/www/html/api.html
              service httpd start
              EOF
}

resource "random_string" "suffix2" {
  length  = 5
  special = false
  upper   = false
}


resource "aws_secretsmanager_secret" "trust_store" {
  name = "ec2-trust-store-${random_string.suffix2.result}"
}

resource "aws_secretsmanager_secret_version" "trust_store_version" {
  secret_id     = aws_secretsmanager_secret.trust_store.id
  secret_string = <<EOT
-----BEGIN CERTIFICATE-----
MIIDeDCCAmCgAwIBAgIUbKQGiXQs/ScfDI8e6x1Rdhb1H9IwDQYJKoZIhvcNAQEL
BQAwYjELMAkGA1UEBhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWExFjAUBgNVBAcM
DVNhbiBGcmFuY2lzY28xETAPBgNVBAoMCE15Um9vdENBMRMwEQYDVQQDDApNeSBS
b290IENBMB4XDTI1MDIxOTEyMzQzMloXDTM1MDIxNzEyMzQzMlowYjELMAkGA1UE
BhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWExFjAUBgNVBAcMDVNhbiBGcmFuY2lz
Y28xETAPBgNVBAoMCE15Um9vdENBMRMwEQYDVQQDDApNeSBSb290IENBMIIBIjAN
BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnVEEnRMNy6joroGCe81CAXjOPLq1
8WrtqrdZ8H0N4jUj8efHfJslfQZtABByJM5GGCrJQjwn1ezdQW0fzhAXTXX/3yk7
02HSnS5Z8lzIEwn0BI71vL4u4frp75DyV/nMlPfQ0NtOEvyRtsx5lDt2HsA4zern
GGnISNyhM6wa0zAm7lLAwEwuLB6YNF2FeSSYRdROeOjViWOH/BhH/Ew/M0w/6t6a
sXTYFRIht1mIR5UHkPGhYfO3VDgB1fnNl9e9wH7deDAPW/jXX5dc0CkWjSqlZ9iB
r4+0JVvyBkfrW+9MIN9SnGkjhLToYx6vChmAEddue22wnRcCqKMs9tWOgQIDAQAB
oyYwJDASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBpjANBgkqhkiG
9w0BAQsFAAOCAQEADSVi/+KhLnE/D71FqDkH2thUPbXzO7KSEChM5iVD7PCw1O+O
cO8KWe86ouMm3mlXiZHC8DakheqIci80EmG/zy6Sl1q0IPd2xUsotRKKEiVec6ga
mcFuKgm46MZYLLzRNTx1kMpyBpTyEtNz9UBHq2sVhpqIvSuseNyeg4xAsgLP9dmO
jhke8GDEZZVUbhaLtNtUfsbWZhl5zOPk4JkCcPcSvG0/p0tOQWdzy9Ke8Q4RzAdp
wOJccwe5gjRU0Xd45qYm01+7cfPNODZNa1vEau9LKIwN8m11Nzerjncd1J3eUCEy
gJC3gPKoorISZe58Fjx41VNpZOSCvFYRF9/vhA==
-----END CERTIFICATE-----
  EOT
}

resource "aws_s3_bucket" "trust_store_bucket" {
  bucket = "ec2-trust-store-bucket-${random_string.suffix.result}" 
}

resource "aws_s3_object" "trust_store_cert" {
  bucket = aws_s3_bucket.trust_store_bucket.id
  key    = "trust-store-cert.pem"
  content = <<EOT
-----BEGIN CERTIFICATE-----
MIIDeDCCAmCgAwIBAgIUbKQGiXQs/ScfDI8e6x1Rdhb1H9IwDQYJKoZIhvcNAQEL
BQAwYjELMAkGA1UEBhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWExFjAUBgNVBAcM
DVNhbiBGcmFuY2lzY28xETAPBgNVBAoMCE15Um9vdENBMRMwEQYDVQQDDApNeSBS
b290IENBMB4XDTI1MDIxOTEyMzQzMloXDTM1MDIxNzEyMzQzMlowYjELMAkGA1UE
BhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWExFjAUBgNVBAcMDVNhbiBGcmFuY2lz
Y28xETAPBgNVBAoMCE15Um9vdENBMRMwEQYDVQQDDApNeSBSb290IENBMIIBIjAN
BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnVEEnRMNy6joroGCe81CAXjOPLq1
8WrtqrdZ8H0N4jUj8efHfJslfQZtABByJM5GGCrJQjwn1ezdQW0fzhAXTXX/3yk7
02HSnS5Z8lzIEwn0BI71vL4u4frp75DyV/nMlPfQ0NtOEvyRtsx5lDt2HsA4zern
GGnISNyhM6wa0zAm7lLAwEwuLB6YNF2FeSSYRdROeOjViWOH/BhH/Ew/M0w/6t6a
sXTYFRIht1mIR5UHkPGhYfO3VDgB1fnNl9e9wH7deDAPW/jXX5dc0CkWjSqlZ9iB
r4+0JVvyBkfrW+9MIN9SnGkjhLToYx6vChmAEddue22wnRcCqKMs9tWOgQIDAQAB
oyYwJDASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBpjANBgkqhkiG
9w0BAQsFAAOCAQEADSVi/+KhLnE/D71FqDkH2thUPbXzO7KSEChM5iVD7PCw1O+O
cO8KWe86ouMm3mlXiZHC8DakheqIci80EmG/zy6Sl1q0IPd2xUsotRKKEiVec6ga
mcFuKgm46MZYLLzRNTx1kMpyBpTyEtNz9UBHq2sVhpqIvSuseNyeg4xAsgLP9dmO
jhke8GDEZZVUbhaLtNtUfsbWZhl5zOPk4JkCcPcSvG0/p0tOQWdzy9Ke8Q4RzAdp
wOJccwe5gjRU0Xd45qYm01+7cfPNODZNa1vEau9LKIwN8m11Nzerjncd1J3eUCEy
gJC3gPKoorISZe58Fjx41VNpZOSCvFYRF9/vhA==
-----END CERTIFICATE-----
EOT
}


resource "aws_lb_trust_store" "alb_trust_store" {
  name                          = "alb-trust-store"
  ca_certificates_bundle_s3_bucket = aws_s3_bucket.trust_store_bucket.id
  ca_certificates_bundle_s3_key    = aws_s3_object.trust_store_cert.key
}