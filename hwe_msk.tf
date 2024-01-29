
#VPC
resource "aws_vpc" "hwe_vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  
  tags = {
    Name = "hwe-vpc"
  }
}

data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_subnet" "subnet_az1" {
  availability_zone = data.aws_availability_zones.azs.names[0]
  cidr_block        = "10.0.0.0/20"
  vpc_id            = aws_vpc.hwe_vpc.id
}

resource "aws_subnet" "subnet_az2" {
  availability_zone = data.aws_availability_zones.azs.names[1]
  cidr_block        = "10.0.16.0/20"
  vpc_id            = aws_vpc.hwe_vpc.id
}

resource "aws_subnet" "subnet_az3" {
  availability_zone = data.aws_availability_zones.azs.names[2]
  cidr_block        = "10.0.32.0/20"
  vpc_id            = aws_vpc.hwe_vpc.id
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.hwe_vpc.id
}


resource "aws_msk_cluster" "hwe_msk" {
  cluster_name           = "hwe-msk"
  kafka_version          = "3.2.0"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type = "kafka.t3.small"
    client_subnets = [
      aws_subnet.subnet_az1.id,
      aws_subnet.subnet_az2.id,
      aws_subnet.subnet_az3.id,
    ]
    storage_info {
      ebs_storage_info {
        volume_size = 10
      }
    }
    security_groups = [aws_security_group.sg.id]
    connectivity_info {
      vpc_connectivity {
        client_authentication {
          sasl {
            scram = true
          }
        }
      }
    }
  }
}

output "zookeeper_connect_string" {
  value = aws_msk_cluster.hwe_msk.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.hwe_msk.bootstrap_brokers_tls
}

/*
resource "aws_cloudwatch_log_group" "test" {
  name = "msk_broker_logs"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "msk-broker-logs-bucket"
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose_test_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "terraform-kinesis-firehose-msk-broker-logs-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket.arn
  }

  tags = {
    LogDeliveryEnabled = "placeholder"
  }

  lifecycle {
    ignore_changes = [
      tags["LogDeliveryEnabled"],
    ]
  }
}
*/