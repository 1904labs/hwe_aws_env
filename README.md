# HWE setup

A guide to setting up the AWS environment for Hours With Experts. This guide is broken down into several steps:

* Destroying the environment
* Infrastructure provisioning
* Special manual setup step needed for MSK
* Setting up users
* Populating class data sources
* Improvements to make to this repo

## Destroying the environment:

Note: All `terraform` commands should be run from the `hwe_aws_env/terraform` directory.

Running `terraform destroy` will tear down the environment. Currently, there are 2 resources that may need manual intervention:

 * If any S3 buckets (`hwe-bucket` and `hwe-athena-results`) are not empty, they cannot be removed
 * If the IAM Group `hwe-students` has any members in it, it cannot be removed
 
## Infrastructure provisioning

Note: All `terraform` commands should be run from the `hwe_aws_env/terraform` directory.

Running `terraform apply` will create all resources in all `.tf` files inside the `hwe_aws_env/terraform` folder. The terraform files are divided up into several files:

`hwe_athena.tf`: Defines the Athena resources used in the course.
`hwe_iam.tf`: Defines the IAM groups and policies used in the course.
`hwe_msk.tf`: Defines the MSK Kafka cluster and Kafka edge node used in the course.
`hwe_s3.tf`: Defines the S3 buckets used in the course.
`hwe_superset.tf`: Defines the Superset node used in the course.

Under the current curriculum:
    * IAM, S3, and Athena are required for Week 3
    * MSK is needed for Week 4
    * Superset is needed for Week 7.

## Special manual setup step needed for MSK

MSK clusters cannot be created with public access turned on - they must be created as private clusters, then they can be modified to enable public access. The `hwe_msk.tf` file currently creates the private MSK cluster, then an administrator has to enable public access via the console.

## Setting up users

## Populating class data sources

## Improvements to make to this repo

* Need to make the secret read from an environment variable.