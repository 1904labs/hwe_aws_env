#Tf Provider
provider "aws" {
    region     = "us-east-1"
}

#IAM group for students
resource "aws_iam_group" "hwe_students" {
  name = "hwe-students"
}

resource "aws_iam_policy" "allow_viewing_permissions_on_s3_buckets_through_console" {
  name        = "allow-viewing-permissions-on-s3-buckets-through-console2"
  description = "Allow users to view S3 buckets through AWS GUI"
  policy      = jsonencode(
{
    Version = "2012-10-17",
    Statement = [
        {
            Sid = "AllowUsersUseS3Console",
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
  name = "allow-writes-to-athena-results-bucket"
  description = "Allow users to write their Athena results to S3"
  policy = jsonencode(
    {
    Version = "2012-10-17",
    Statement = [
        {
            Sid = "AllowWritesToAthenaResultsBucket",
            Effect = "Allow",
            Action = "s3:*",
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
  name        = "alllow-full-read-on-athena"
  description = "Allow users to query Athena"
  policy      = jsonencode(
    {
    Version = "2012-10-17",
    Statement = [
        {
            Sid = "FullAthenaReadAccess",
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

resource "aws_iam_policy" "allow_manage_own_access_keys" {
  name        = "allow-manage-own-access-keys"
  description = "Allow users to fully manage their own access keys"
  policy      = jsonencode(
{
    Version = "2012-10-17",
    Statement = [
        {
            Sid = "ManageOwnAccessKeys",
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
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
        {
            Sid = "AllowLimitedAthenaWriteAccess",
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
  policy      = jsonencode(
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
                "arn:aws:s3:::hwe-bucket"
            ]
        },
        {
            Sid = "AllowAllActionsInMyOwnSubfolder",
            Action = [
                "s3:*"
            ],
            Effect = "Allow",
            Resource = [
                "arn:aws:s3:::hwe-bucket/$${aws:username}/*"
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

#S3 bucket
resource "aws_s3_bucket" "hwe_bucket" {
    bucket = "hwe-bucket"
}

#KMS key
resource "aws_kms_key" "hwe_kms_key" {
  description = "KMS key used to encrypt MSK username + password"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  key_usage = "ENCRYPT_DECRYPT"
}

#KMS key alias
resource "aws_kms_alias" "hwe_kms_key_alias" {
  name = "alias/hwe_kms_key"
  target_key_id = aws_kms_key.hwe_kms_key.key_id
}

#Secret for MSK username/password
resource "aws_secretsmanager_secret" "amazonmsk_hwe_secret" {
  name = "AmazonMSK_hwe_secret3" #This name MUST start with AmazonMSK_!
  kms_key_id = aws_kms_key.hwe_kms_key.key_id
}

variable "msk_connection_info" {
  sensitive = true
  default = {
    username = "1904labs"
    password = "TODO: Set password securely"
  }
}

resource "aws_secretsmanager_secret_version" "amazonmsk_hwe_secret_value" {
  secret_id = aws_secretsmanager_secret.amazonmsk_hwe_secret.id
  secret_string = jsonencode(var.msk_connection_info)
}
