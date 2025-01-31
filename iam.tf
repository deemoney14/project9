resource "aws_iam_role" "ec2_rds_role" {
  name = "EC2RDSAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Policy for both RDS IAM authentication and Secrets Manager
resource "aws_iam_policy" "rds_secrets_access_policy" {
  name        = "RDSIAMAndSecretsPolicy"
  description = "Allows EC2 to authenticate with RDS and retrieve credentials from Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # IAM Authentication for RDS
      {
        Effect = "Allow",
        Action = [
          "rds-db:connect"
        ],
        Resource = "arn:aws:rds-db:us-west-1:${var.aws_account_id}:dbuser:webserver/deemoney"
      },
      # Access Secrets Manager to retrieve RDS credentials
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = "arn:aws:secretsmanager:us-west-1:${var.aws_account_id}:secret:rds/webserver-db-credentials-*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_secrets_access_attachment" {
  policy_arn = aws_iam_policy.rds_secrets_access_policy.arn
  role       = aws_iam_role.ec2_rds_role.name
}