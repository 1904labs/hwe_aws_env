# HWE setup

A guide to setting up the AWS environment for Hours With Experts. This guide is broken down into several steps:

* Destroying the environment
* Infrastructure provisioning
* Server configuration
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

### Special manual setup step needed for MSK

MSK clusters cannot be created with public access turned on - they must be created as private clusters, then they can be modified to enable public access. The `hwe_msk.tf` file currently creates the private MSK cluster, then an administrator has to enable public access via the console. This is very straightforward using the GUI but does take ~30 minutes to run.

## Server configuration

### Setting up the Kafka edge node used to create topics

```bash
#Set up ZK variable
export ZK=#Use the PLAINTEXT/2181 ZK connection string, not the TLS/2182 one
#install Java
sudo dnf install java-11-amazon-corretto-devel -y
#Install kafka CLI tools
wget https://archive.apache.org/dist/kafka/2.6.2/kafka_2.12-2.6.2.tgz
tar -xvf kafka_2.12-2.6.2.tgz
#Set up Kafka ACLs on the cluster
cd kafka_2.12-2.6.2/bin
./kafka-acls.sh --authorizer-properties zookeeper.connect=$ZK --add --allow-principal 'User:*' --operation All --topic '*' --group '*'
#Create topics
./kafka-topics.sh --create --zookeeper $ZK --replication-factor 3 --partitions 1 --topic kafka-connection-test
```

### Setting up the Superset master node
https://1904labs.atlassian.net/wiki/spaces/DAT/pages/2189000705/Setting+up+a+Superset+server+in+EC2

## Setting up users

Setting up a user involves:

1. Creating the user
2. Assigning them to the `hwe-students` group
3. Creating a subfolder for them under the `hwe-bucket`
4. Creating a file named `success_message` under that bucket containing a success message

## Populating class data sources

### Setting up the Kafka connection test topic

### Setting up the Kafka `reviews` topic

### Setting up the static `customer` data on S3

### Setting up the Athena query test data

## Improvements to make to this repo
* Add Athena workgroup information (primary, hwe, superset)
* Make each module 100% independent so they can be run separately (imports?)
* Need to make the secret read from an environment variable.
* Script user creation process
* Use Terraform backend on AWS instead of local
* Key pair (ec2_kafka_key_pair) is currently managed outside of Terraform
* Use a tool to script the bash/Python components of this
