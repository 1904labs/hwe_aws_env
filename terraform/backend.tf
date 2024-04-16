terraform {
    backend "s3" {
        bucket = "hwe-terraform-backend"
        key = "hwe-tfstate/terraform.tfstate"
        region = "us-east-1"
    }
}