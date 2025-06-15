provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    cloudwatch = "http://localhost:4566"
    logs       = "http://localhost:4566"
    s3         = "http://localhost:4566"
    ec2        = "http://localhost:4566"
  }
}


module "web_server" {
  source       = "./modules/service"
  service_name = "web"
  environment  = var.environment
  tags = {
    app  = "web"
    team = "devops"
  }
}

module "db_server" {
  source       = "./modules/service"
  service_name = "db"
  environment  = var.environment
  tags = {
    app  = "database"
    team = "backend"
  }
}
