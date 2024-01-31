
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
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_az2" {
  availability_zone = data.aws_availability_zones.azs.names[1]
  cidr_block        = "10.0.16.0/20"
  vpc_id            = aws_vpc.hwe_vpc.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_az3" {
  availability_zone = data.aws_availability_zones.azs.names[2]
  cidr_block        = "10.0.32.0/20"
  vpc_id            = aws_vpc.hwe_vpc.id
  map_public_ip_on_launch = true
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.hwe_vpc.id
}

#Secret for MSK username/password
resource "aws_secretsmanager_secret" "amazonmsk_hwe_secret" {
  name = "AmazonMSK_hwe_secret5" #This name MUST start with AmazonMSK_!
  kms_key_id = aws_kms_key.hwe_kms_key.key_id
  recovery_window_in_days = 0
}

variable "msk_connection_info" {
  sensitive = true
  default = {
    username = "1904labs"
    password = "1904labsSecurePassword!"
  }
}

resource "aws_secretsmanager_secret_version" "amazonmsk_hwe_secret_value" {
  secret_id = aws_secretsmanager_secret.amazonmsk_hwe_secret.id
  secret_string = jsonencode(var.msk_connection_info)
}

data "aws_iam_policy_document" "secret_access_policy" {
  statement {
    sid    = "AWSKafkaResourcePolicy"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["kafka.amazonaws.com"]
    }

    actions   = ["secretsmanager:getSecretValue"]
    resources = [aws_secretsmanager_secret.amazonmsk_hwe_secret.arn]
  }
}

resource "aws_secretsmanager_secret_policy" "msk_secret_policy" {
  secret_arn = aws_secretsmanager_secret.amazonmsk_hwe_secret.arn
  policy     = data.aws_iam_policy_document.secret_access_policy.json
}

resource "aws_msk_cluster" "hwe_msk" {
  cluster_name           = "hwe-msk"
  kafka_version          = "2.6.2" #Using later versions than this causes a multi-VPC error...
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
  }
  client_authentication {
    sasl {
      scram = true
    }
  }
  configuration_info {
    arn = "arn:aws:kafka:us-east-1:153601099083:configuration/dont-allow-everyone-if-no-acl-found/529fc726-c6d5-4a40-b779-4c1400d43f5c-16"
    revision = 1
  }
    #connectivity_info {
    #  vpc_connectivity {
    #    client_authentication {
    #      sasl {
    #        scram = true
    #        }
    #    }
    #  }
    #}
}

resource "aws_msk_scram_secret_association" "example" {
  cluster_arn     = aws_msk_cluster.hwe_msk.arn
  secret_arn_list = [aws_secretsmanager_secret.amazonmsk_hwe_secret.arn]
  depends_on = [aws_secretsmanager_secret_version.amazonmsk_hwe_secret_value]
}


output "zookeeper_connect_string" {
  value = aws_msk_cluster.hwe_msk.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.hwe_msk.bootstrap_brokers_tls
}
