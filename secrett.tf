resource "aws_secretsmanager_secret" "rds_secret" {
    name = "rds/bd-password"
    description = "RDS Database Credentials"

    tags = {
      Name = "rds-db-password"
    }
  
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
    secret_id = aws_secretsmanager_secret.rds_secret.id
    secret_string = jsonencode({
        username = var.db_username
        password = var.db_password
        
    })
  
}




