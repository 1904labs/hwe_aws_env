resource "aws_s3_bucket" "hwe_bucket" {
    bucket = "hwe-bucket"
}

resource "aws_s3_bucket" "hwe_athena_results_bucket" {
    bucket = "hwe-athena-results"
}
