#KMS key
resource "aws_kms_key" "hwe_kms_key" {
  description              = "KMS key used to encrypt MSK username + password"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  key_usage                = "ENCRYPT_DECRYPT"
}

#KMS key alias
resource "aws_kms_alias" "hwe_kms_key_alias" {
  name          = "alias/hwe_kms_key"
  target_key_id = aws_kms_key.hwe_kms_key.key_id
}

#VPC
resource "aws_vpc" "hwe_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "hwe-vpc"
  }
}

data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_security_group" "allow_ssh_zk_kafka_outbound" {
  name        = "allow-ssh-zk-kafka-outbound"
  description = "Allow all outbound traffic and inbound traffic on SSH, Zookeeper, and Kafka ports"
  vpc_id      = aws_vpc.hwe_vpc.id

  tags = {
    Name = "allow-ssh-zk-kafka-outbound"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh_zk_kafka_outbound.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_zk_ipv4" {
  security_group_id = aws_security_group.allow_ssh_zk_kafka_outbound.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 2181
  ip_protocol       = "tcp"
  to_port           = 2181
}

resource "aws_vpc_security_group_ingress_rule" "allow_kafka_ipv4" {
  security_group_id = aws_security_group.allow_ssh_zk_kafka_outbound.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 9196
  ip_protocol       = "tcp"
  to_port           = 9196
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_ipv4" {
  security_group_id = aws_security_group.allow_ssh_zk_kafka_outbound.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_subnet" "subnet_az1" {
  availability_zone       = data.aws_availability_zones.azs.names[0]
  cidr_block              = "10.0.0.0/20"
  vpc_id                  = aws_vpc.hwe_vpc.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_az2" {
  availability_zone       = data.aws_availability_zones.azs.names[1]
  cidr_block              = "10.0.16.0/20"
  vpc_id                  = aws_vpc.hwe_vpc.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_az3" {
  availability_zone       = data.aws_availability_zones.azs.names[2]
  cidr_block              = "10.0.32.0/20"
  vpc_id                  = aws_vpc.hwe_vpc.id
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "hwe_igw" {
  vpc_id = aws_vpc.hwe_vpc.id
}

resource "aws_route_table" "hwe_rt" {
  vpc_id = aws_vpc.hwe_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hwe_igw.id
  }
}

resource "aws_route_table_association" "subnet_az1_associate_public" {
  subnet_id      = aws_subnet.subnet_az1.id
  route_table_id = aws_route_table.hwe_rt.id
}
resource "aws_route_table_association" "subnet_az2_associate_public" {
  subnet_id      = aws_subnet.subnet_az2.id
  route_table_id = aws_route_table.hwe_rt.id
}
resource "aws_route_table_association" "subnet_az3_associate_public" {
  subnet_id      = aws_subnet.subnet_az3.id
  route_table_id = aws_route_table.hwe_rt.id
}

#Secret for MSK username/password
resource "aws_secretsmanager_secret" "amazonmsk_hwe_secret" {
  name                    = "AmazonMSK_hwe_secret5" #This name MUST start with AmazonMSK_!
  kms_key_id              = aws_kms_key.hwe_kms_key.key_id
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
  secret_id     = aws_secretsmanager_secret.amazonmsk_hwe_secret.id
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

resource "aws_msk_configuration" "dont_allow_everyone_if_no_acl_found" {
  kafka_versions = ["2.6.2"]
  name           = "dont-allow-everyone-if-no-acl-found"

  server_properties = <<PROPERTIES
auto.create.topics.enable=false
default.replication.factor=3
min.insync.replicas=2
num.io.threads=8
num.network.threads=5
num.partitions=1
num.replica.fetchers=2
replica.lag.time.max.ms=30000
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
socket.send.buffer.bytes=102400
unclean.leader.election.enable=true
zookeeper.session.timeout.ms=18000
allow.everyone.if.no.acl.found=false
PROPERTIES
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
    security_groups = [aws_security_group.allow_ssh_zk_kafka_outbound.id]
  }
  client_authentication {
    sasl {
      scram = true
    }
  }
  configuration_info {
    arn      = aws_msk_configuration.dont_allow_everyone_if_no_acl_found.arn
    revision = 1
  }
}

resource "aws_msk_scram_secret_association" "msk_secret_association" {
  cluster_arn     = aws_msk_cluster.hwe_msk.arn
  secret_arn_list = [aws_secretsmanager_secret.amazonmsk_hwe_secret.arn]
  depends_on      = [aws_secretsmanager_secret_version.amazonmsk_hwe_secret_value]
}


output "zookeeper_connect_string" {
  value = aws_msk_cluster.hwe_msk.zookeeper_connect_string
}

output "bootstrap_brokers_sasl_scram" {
  description = "SASL/SCRAM connection host:port pairs"
  value       = aws_msk_cluster.hwe_msk.bootstrap_brokers_public_sasl_scram
}


#Edge node
resource "aws_instance" "edge_node" {
  ami                         = "ami-0a3c3a20c09d6f377"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet_az1.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_zk_kafka_outbound.id]
  key_name                    = "ec2-kafka-key-pair" #Legacy key pair for HWE, created outside Terraform
  tags = {
    Name = "msk-edge-node"
  }
}