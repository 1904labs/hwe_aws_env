#Tf Provider
provider "aws" {
  region = "us-east-1"
}

#IAM group for students
resource "aws_iam_group" "hwe_students" {
  name = "hwe-students"
}

#Make the IAM console less ugly for students, lots of red errors that look broken which will make them think something is wrong
resource "aws_iam_policy" "allow_student_iam_read_for_themselves" {
  name        = "allow-student-iam-read-for-themselves"
  description = ""
  policy = jsonencode(
    {
      Version = "2012-10-17",
      "Statement": [
        {
          "Sid": "AllowAccountLevelAccess",
          "Effect": "Allow",
          "Action": [
            "iam:ListAccountAliases",
            "iam:GetAccountSummary",
            "iam:ListAccessKeys"
          ],
          "Resource": "*"
        },
        {
          "Sid": "AllowUserToManageTheirOwnMFA",
          "Effect": "Allow",
          "Action": [
            "iam:EnableMFADevice",
            "iam:GetMFADevice",
            "iam:ListMFADevices",
            "iam:ResyncMFADevice",
            "iam:ListSigningCertificates",
            "iam:GetLoginProfile",
            "iam:ListUserTags"
          ],
          "Resource": "arn:aws:iam::*:user/$${aws:username}"
        },
      ]
    }
  )
}

resource "aws_iam_group_policy_attachment" "attach_iam_read_for_themselves" {
  group      = aws_iam_group.hwe_students.name
  policy_arn = aws_iam_policy.allow_student_iam_read_for_themselves.arn
}

resource "aws_iam_policy" "allow_student_s3_permissions" {
  name        = "allow-student-s3-permissions"
  description = ""
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Sid = "AllowsListingAllBuckets",
          Action = [
            "s3:ListAllMyBuckets",
            "s3:GetBucketLocation"
          ],
          Effect = "Allow",
          Resource = [
            "arn:aws:s3:::*"
          ]
        },
        {
          Sid = "AllowListingOfSubfoldersInHWEBucket",
          Action = [
            "s3:ListBucket"
          ],
          Effect = "Allow",
          Resource = [
            "arn:aws:s3:::${aws_s3_bucket.hwe_bucket.bucket}"
          ]
        },
        {
          Sid = "AllowListOnAthenaBucket",
          Action = [
            "s3:ListBucket"
          ],
          Effect = "Allow",
          Resource = [
            "arn:aws:s3:::hwe-athena-results"
          ]
        },
        {
          Sid = "AllowAllActionsInMyOwnSubfolder",
          Action = [
            "s3:*"
          ],
          Effect = "Allow",
          Resource = [
            "arn:aws:s3:::${aws_s3_bucket.hwe_bucket.bucket}/$${aws:username}/*"
          ]
        }
      ]
    }

  )
}

resource "aws_iam_group_policy_attachment" "attach_s3_student" {
  group      = aws_iam_group.hwe_students.name
  policy_arn = aws_iam_policy.allow_student_s3_permissions.arn
}

resource "aws_iam_policy" "allow_viewing_permissions_on_s3_buckets_through_console" {
  name        = "allow-viewing-permissions-on-s3-buckets-through-console2"
  description = "Allow users to view S3 buckets through AWS GUI"
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Sid    = "AllowUsersUseS3Console",
          Effect = "Allow",
          Action = [
            "s3:GetBucketPublicAccessBlock",
            "s3:GetBucketPolicyStatus",
            "s3:GetAccountPublicAccessBlock",
            "s3:ListAccessPoints",
            "s3:GetBucketAcl"
          ],
          Resource = "*"
        }
      ]
  })
}

resource "aws_iam_group_policy_attachment" "attach_s3_viewing" {
  group      = aws_iam_group.hwe_students.name
  policy_arn = aws_iam_policy.allow_viewing_permissions_on_s3_buckets_through_console.arn
}

resource "aws_iam_policy" "allow_writes_to_athena_results_bucket" {
  name        = "allow-writes-to-athena-results-bucket"
  description = "Allow users to write their Athena results to S3"
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Sid      = "AllowWritesToAthenaResultsBucket",
          Effect   = "Allow",
          Action   = "s3:*",
          Resource = "arn:aws:s3:::hwe-athena-results/*"
        }
      ]
    }
  )
}

resource "aws_iam_group_policy_attachment" "attach_athena_write_results" {
  group      = aws_iam_group.hwe_students.name
  policy_arn = aws_iam_policy.allow_writes_to_athena_results_bucket.arn
}

resource "aws_iam_policy" "allow_full_read_on_athena" {
  name        = "allow-full-read-on-athena"
  description = "Allow users to query Athena"
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Sid    = "FullAthenaReadAccess",
          Effect = "Allow",
          Action = [
            "athena:GetTableMetadata",
            "athena:GetSession",
            "athena:GetCalculationExecutionCode",
            "athena:GetQueryResults",
            "athena:GetDatabase",
            "athena:GetDataCatalog",
            "athena:GetQueryRuntimeStatistics",
            "athena:GetNamedQuery",
            "athena:GetCapacityReservation",
            "athena:ListQueryExecutions",
            "athena:GetWorkGroup",
            "athena:GetNotebookMetadata",
            "athena:BatchGetPreparedStatement",
            "athena:ListEngineVersions",
            "athena:GetQueryResultsStream",
            "athena:GetCalculationExecution",
            "athena:GetPreparedStatement",
            "athena:ListTagsForResource",
            "athena:GetCalculationExecutionStatus",
            "athena:GetSessionStatus",
            "athena:GetQueryExecution",
            "athena:GetCapacityAssignmentConfiguration",
            "athena:ListTableMetadata",
            "athena:BatchGetNamedQuery",
            "athena:BatchGetQueryExecution"
          ],
          Resource = "*"
        }
      ]
    }
  )
}

resource "aws_iam_group_policy_attachment" "attach_allow_full_read_on_athena" {
  group      = aws_iam_group.hwe_students.name
  policy_arn = aws_iam_policy.allow_full_read_on_athena.arn
}

resource "aws_iam_policy" "allow_full_read_on_glue" {
  name        = "allow-full-read-on-glue"
  description = "Allow users to query Glue"
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Sid    = "FullGlueReadAccess",
          Effect = "Allow",
          Action = [
            "glue:GetDatabase",
            "glue:GetDatabases",
            "glue:GetTables",
            "glue:GetTable",
            "glue:CreateTable",
            "glue:UpdateTable",
            "glue:DeleteTable",
            "glue:UpdateTable"
          ],
          Resource = "*"
        }
      ]
    }
  )
}

resource "aws_iam_group_policy_attachment" "attach_allow_full_read_on_glue" {
  group      = aws_iam_group.hwe_students.name
  policy_arn = aws_iam_policy.allow_full_read_on_glue.arn
}

resource "aws_iam_policy" "allow_manage_own_access_keys" {
  name        = "allow-manage-own-access-keys"
  description = "Allow users to fully manage their own access keys"
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Sid    = "ManageOwnAccessKeys",
          Effect = "Allow",
          Action = [
            "iam:CreateAccessKey",
            "iam:DeleteAccessKey",
            "iam:GetAccessKeyLastUsed",
            "iam:GetUser",
            "iam:ListAccessKeys",
            "iam:UpdateAccessKey",
            "iam:TagUser"
          ],
          Resource = "arn:aws:iam::*:user/$${aws:username}"
        }
      ]
    }
  )
}

resource "aws_iam_group_policy_attachment" "test-attach" {
  group      = aws_iam_group.hwe_students.name
  policy_arn = aws_iam_policy.allow_manage_own_access_keys.arn
}

resource "aws_iam_policy" "allow_limited_athena_write_access" {
  name        = "allow-limited-athena-write-access"
  description = "Allow limited write access to Athena"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowLimitedAthenaWriteAccess",
        Effect = "Allow",
        Action = [
          "athena:TerminateSession",
          "athena:UpdateDataCatalog",
          "athena:StopCalculationExecution",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution",
          "athena:StartCalculationExecution",
          "athena:StartSession"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "attach-allow-limited-athena-write-access" {
  group      = aws_iam_group.hwe_students.name
  policy_arn = aws_iam_policy.allow_limited_athena_write_access.arn
}

resource "aws_iam_policy" "allow_write_to_s3_username_folder" {
  name        = "allow-write-to-s3-username-folder"
  description = "Allow users to write to their individual path under the main S3 student bucket"
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Sid = "AllowsListingAllBuckets",
          Action = [
            "s3:ListAllMyBuckets",
            "s3:GetBucketLocation"
          ],
          Effect = "Allow",
          Resource = [
            "arn:aws:s3:::*"
          ]
        },
        {
          Sid = "AllowListingOfSubfoldersInHWEBucket",
          Action = [
            "s3:ListBucket"
          ],
          Effect = "Allow",
          Resource = [
            "arn:aws:s3:::${aws_s3_bucket.hwe_bucket.bucket}"
          ]
        },
        {
          Sid = "AllowAllActionsInMyOwnSubfolder",
          Action = [
            "s3:*"
          ],
          Effect = "Allow",
          Resource = [
            "arn:aws:s3:::${aws_s3_bucket.hwe_bucket.bucket}/$${aws:username}/*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_group_policy_attachment" "attach_allow_write_to_s3_username_folder" {
  group      = aws_iam_group.hwe_students.name
  policy_arn = aws_iam_policy.allow_write_to_s3_username_folder.arn
}

resource "aws_s3_bucket" "hwe_bucket" {
  bucket = "hwe-${var.SEMESTER}"
 lifecycle {
    prevent_destroy = false
  }

  force_destroy = true
}

resource "aws_s3_bucket" "hwe_athena_results_bucket" {
  bucket = "hwe-athena-results"
 lifecycle {
    prevent_destroy = false
  }

  force_destroy = true
}

#KMS key
resource "aws_kms_key" "hwe_kms_key" {
  description              = "KMS key used to encrypt MSK username + password"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  key_usage                = "ENCRYPT_DECRYPT"
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
  name                    = "AmazonMSK_hwe_secret" #This name MUST start with AmazonMSK_!
  kms_key_id              = aws_kms_key.hwe_kms_key.key_id
  recovery_window_in_days = 0
}

variable "SEMESTER" {
  sensitive   = false
  type        = string
  description = "Semester for this session, formatted season-yyyy (fall-2024, spring-2025, etc.)"
}

variable "HWE_USERNAME" {
  sensitive   = true
  type        = string
  description = "Username for the HWE Kafka cluster"
}

variable "HWE_PASSWORD" {
  sensitive   = true
  type        = string
  description = "Password for the HWE Kafka cluster"
}

locals {
  msk_connection_info = {
    username = var.HWE_USERNAME
    password = var.HWE_PASSWORD
  }
}

resource "aws_secretsmanager_secret_version" "amazonmsk_hwe_secret_value" {
  secret_id     = aws_secretsmanager_secret.amazonmsk_hwe_secret.id
  secret_string = jsonencode(local.msk_connection_info)
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
  kafka_version          = "3.5.1"
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
  tags = {
    Name = "msk-edge-node"
  }
}

resource "aws_security_group" "superset_sg" {
  name        = "superset-sg"
  description = "Security group for Superset with AmazonAthenaFullAccess and AmazonS3FullAccess"
  vpc_id      = aws_vpc.hwe_vpc.id

  tags = {
    Name = "superset-sg"
  }
}

resource "aws_iam_role" "superset_role" {
  name               = "superset-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Effect    = "Allow",
        Principal = { Service = "ec2.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "superset_athena_access" {
  name       = "superset-athena-access"
  roles      = [aws_iam_role.superset_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
}

resource "aws_iam_policy_attachment" "superset_s3_access" {
  name       = "superset-s3-access"
  roles      = [aws_iam_role.superset_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_instance" "superset_master" {
  ami                         = "ami-06aa3f7caf3a30282" # Ubuntu 20.04
  instance_type               = "t2.large"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet_az1.id
  vpc_security_group_ids      = [aws_security_group.superset_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.superset_instance_profile.name

  tags = {
    Name = "superset-master"
  }
}

resource "aws_iam_instance_profile" "superset_instance_profile" {
  name = "superset-instance-profile"
  role = aws_iam_role.superset_role.name
}

resource "aws_glue_catalog_database" "hwe" {
  name = "hwe"
}

resource "aws_glue_catalog_table" "athena_test" {
  name          = "athena_test"
  database_name = aws_glue_catalog_database.hwe.name
  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.hwe_athena_results_bucket.bucket}/athena_test/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
    }
    columns {
      name = "message"
      type = "string"
    }
  }
}

resource "aws_s3_object" "athena_success_message" {
  bucket = aws_s3_bucket.hwe_athena_results_bucket.bucket
  key    = "athena_test/athena_success_message.txt"
  content = "Congratulations! You have successfully executed a query using Amazon Athena!"
  acl     = "private"
}

#Superset node
#resource "aws_instance" "superset_master" {
#  ami = "ami-06aa3f7caf3a30282" #Ubuntu 20.04
#  instance_type     = "t2.large"
# associate_public_ip_address = true
#  subnet_id = aws_subnet.subnet_az1.id
#   tags = {
#    Name = "superset-master"
#  }
#}