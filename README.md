# CloudSec-Terraform-Project

Welcome to the CloudSec-Terraform-Project

This project launches a wordpress application on AWS ECS, connecting it to a database on AWS RDS and uses AWS EFS as its volume.

## Prerequisites:

* An AWS Account
* AWS Access and Secret keys                   #___In the absence of a github actions role for openid connect___
* SSM parameter for database username and password
* S3 bucket for terraform backend state files. The bucket name must be unique, so you cannot use what is in this repository
* Domain name 
* ACMS certificate for the Domain name 


## The terraform configuration creates: 

* one (1) virtual private cloud
* Two (2) subnets
* One (1) route table which is associated with the two subnets
* One (1) internet gateway which serves as the route for the route table
* Four (4) security groups, one for RDS, one for ECS, one for EFS, and one for the Load Balancer:
     
    1. RDS is made to be only privately accessible, but its security group allows traffic from the ECS security group on port 3306.

    2. The ECS security group has ingress for Load Balancer security group on both HTTPS and HTTPS, egress on port 3306 (so that it can communicate with RDS), egress on port 2049 (in order to communicate with EFS on NFS) and egress on port 443 (so that it can pull the container image "wordpress:php8.3-apache" from docker hub). 

    3. The EFS security group has ingress on port 2049 for the ECS security group.

    4. The Load Balancer security group has ingress for both port 80 and 443 (HTTP and HTTPS).

* One (1) Load Balancer.
* One (1) Target Group, with target type being "ip" and health check path of "/wp-admin/install.php".
* Two (1) Listeners for the Load Balancer, one for HTTP and the other for HTTPS.
* One (1) DNS Record on Route 53 to map registered domain name to Load Balancer dns. The "allow overwrite" is set to true, hence it will overwrite any record with same name in Route 53.
* One (1) EFS File System
* One (1) EFS Access Point for the EFS File System
* Two (2) Mount Targets in each of the two Subnets, whiles making use of the EFS security group 
* One (1) Volume for the container, using the EFS File System


_Note that the wordpress container needs a database. The details of the RDS database (database host, database name, database username, and database password) are passed on to the wordpress container as environmental variables in the ECS task definition configuration. The database username and password must have been stored as secrets in AWS SSM parameter store before referenced within the configuration_


* One (1) ECS Cluster, within which the ECS Task Definition will run
* One (1) ECS Rask Definition that will be run by an ecs service.
* One (1) ECS Service, which specifies the vpc, subnets, security group for ECS, Load Balancer and Target Group to run the container specified in the Task Definition. The Target Group is of type "ip", hence the ECS Service dynamically registers the private ip of the container on the Target Group anytime you run the terraform configuration. 
 

## How to run the configuration files

* git clone the repo 
```
git clone https://github.com/seyramgabriel/CloudSec-Terraform-Project
```
* move into the source directory
```
cd source/
```
* Open to the variable.tf file and customise the default values (such as resource names, cidr blocks, ACMS certificate) to your choice.

* Modify the domain name to your domain name

* Modify the image name from "wordpress:php8.3-apache" to any wordpress image of your choice in the ecs task definition configuraion in vpc-infra.tf file. Note that the wordpress image "wordpress:php8.3-apache" comes with wordpress, php, and apache.

* Run 
```
terraform validate
```
```
terraform plan
```
````
terraform apply
````

* After all resources are created, there will be an output of the load balancer dns, with which you can browse the wordpress application

To destroy the resources, run
````
terraform destroy
````

## CICD

The repo deploys the terraform configuration using the .github/workflows/action.yml file.

It is set to be triggered manually, by choosing either "apply" or "destroy" as inputs.

It also uses AWS access key and secret key defined in the repository secret to authenticate to the AWS account.

The load balancer dns is to be output once an apply is complete. 








