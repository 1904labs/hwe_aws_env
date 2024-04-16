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

 * If any S3 buckets (`hwe-bucket`,  `hwe-athena-results`,) are not empty, they cannot be removed
 * If the IAM Group `hwe-students` has any members in it, it cannot be removed
 
## Infrastructure provisioning

Note: All `terraform` commands should be run from the `hwe_aws_env/terraform` directory.

Running `terraform apply` will create all resources in all `.tf` files inside the `hwe_aws_env/terraform` folder. All resources are currently in a large `hwe_all.tf` file.

Under the current curriculum:
* IAM, S3, and Athena are required for Week 3
* MSK is needed for Week 4
* Superset is needed for Week 7.

### Special manual setup step needed for MSK

MSK clusters cannot be created with public access turned on - they must be created as private clusters, then they can be modified to enable public access. After the MSK cluster has been created, an administrator has to enable public access via the console. This is very straightforward using the GUI but does take ~30 minutes to run.

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

## Creating/Destroying users

Currently, creating and destroying users is handled outside of Terraform by some bash scripts. A file must be created with a list of student names ("handles"), 1 per line. This handles file drives the creation/deletion process.

Creating users:
`create_iam_users_for_hwe.sh handles.txt bucketsuffix`

Deleting users:
`delete_iam_users_for_hwe.sh handles.txt`

## Populating class data sources

### Setting up the Kafka connection test topic
TODO

### Setting up the Kafka `reviews` topic
TODO

### Setting up the static `customer` data on S3
TODO

### Setting up the Athena query test data
TODO

## Improvements to make to this repo
* Add Athena workgroup information (primary, hwe, superset)
* Possibly make each module 100% independent so they can be run separately rather than one large `hwe_all.tf` file
* Key pair (ec2_kafka_key_pair) is currently managed outside of Terraform
* Use a tool to script the bash/Python components of this
