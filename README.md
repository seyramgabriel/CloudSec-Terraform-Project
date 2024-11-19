# CloudSec-Terraform-Project
# Project Description

Welcome to the CloudSec-Terraform-Project

This project launches a wordpress application on AWS ECS with Fargate, connecting it to a database on AWS RDS and uses AWS EFS as its volume.

The project involves setting up a complete infrastructure on AWS, managed through Terraform, ensuring that no hardcoded credentials are used for sensitive data.


# Key Requirements:

* VPC Setup: Create a new VPC with public subnets for the web tier and private subnets for the database.

* Load Balancer: Implement an Application Load Balancer (ALB) to distribute traffic and handle SSL termination.

*  IAM & Security: Configure IAM roles and security groups to enforce least-privilege access and secure traffic control.

*  ECS & Fargate: Deploy WordPress on ECS using Fargate, with Amazon EFS for shared storage.

*  RDS Database: Set up Amazon RDS (MySQL/MariaDB) in a private subnet for the WordPress database.

*  Domain & SSL: Purchase a domain (e.g., .pro, .cloud) and manage it via Route 53. Secure the site with SSL/TLS using AWS Certificate Manager (ACM).

# Deliverables:

* Terraform code, hosted in a GitHub repository.

* Screenshots of the deployed resources.

* Documentation (as a README) explaining the system architecture and final setup.


# Project Implementation 
## Prerequisites:

* An AWS Account
* S3 bucket for terraform backend state files. The bucket name must be unique, so you cannot use what is in this repository
* Domain name 
* ACMS certificate for the Domain name 


## Configuration files

The terraform configuraion files are in the "source' directory in this repository. 
It contains the following files:
* vpc-infra.tf - which is the main configuration file
* provider.tf - which declares the aws region, the terraform version, and the s3 bucket to be used as terraform backend
* variable.tf - which is used to define variables for the terraform configuration
* output.tf - which is used to define the output of rds database endpoint and load balancer dns
* store.tf -  which defines configuration for database password and database username in aws parameter store
* locals.tf - which provides a variable for the path in aws parameter store for the database password and database username

## Network Configuration

The terraform configuration creates: 

* one (1) virtual private cloud.
* Four(4) subnets in two availability zones.
* Two (2) route tables, one is associated with two(2) public subnets, and the other is associated with two(2) private subnets (used as subnet group) within which the RDS database is launched. 
* One (1) internet gateway which serves as the route for the public route table.
* Four (4) security groups, one for RDS, one for ECS, one for EFS, and one for the Load Balancer:
     
    **a.** RDS is made to be only privately accessible, but its security group allows traffic from the ECS security group on port 3306. Once you make RDS not publicly accessible, RDS doesn't assign a public IP address to the database. Only Amazon EC2 instances and other resources inside the VPC can connect to your database. 

    **b.** The ECS security group has ingress for the Load Balancer security group on both HTTP and HTTPS, it has egress on port 3306 (so that it can communicate with RDS), egress on port 2049 (in order to communicate with EFS on NFS) and egress on port 443 (so that it can pull the container image "wordpress:php8.3-apache" from docker hub). 

    **c.** The EFS security group has ingress on port 2049 for the ECS security group.

    **d.** The Load Balancer security group has ingress for both port 80 and 443 (HTTP and HTTPS).

* One (1) Load Balancer, in two public subnets.
* One (1) Target Group, with target type being "ip" and health check path of "/wp-admin/install.php".
* Two (1) Listeners for the Load Balancer, one for HTTP and the other for HTTPS.
* One (1) DNS Record on Route 53 to map registered domain name to Load Balancer dns. The "allow overwrite" is set to true, hence it will overwrite any record with same name in Route 53.
* One (1) EFS File System.
* One (1) EFS Access Point for the EFS File System.
* Two (2) Mount Targets in each of two (2) private Subnets, hence two availability zones, whiles making use of the EFS security group. 
* One (1) Volume for the container, using the EFS File System.


_Note that the wordpress container needs a database. The details of the RDS database (database host, database name, database username, and database password) are passed on to the wordpress container as environmental variables in the ECS task definition configuration_.


* One (1) ECS Cluster, within which the ECS Task Definition will run
* One (1) ECS Task Definition that will be run by an ecs service.
* One (1) ECS Service, which specifies the vpc, subnets, security group for ECS, Load Balancer and Target Group to run the container specified in the Task Definition. The Target Group is of type "ip", hence the ECS Service dynamically registers the private ip of the container on the Target Group anytime you run the terraform configuration. 
 

## Security
* RDS database is provisioned in a subnet group made up of private subnets. In addition, the publicly_accessible attribute is set to false to ensure that only resources within the VPC can access it. The rds endpoint has been defined in the output.tf for output after apply. 

* A random password is generated for the RDS database, which is stored in AWS SSM parameter store instead of being hard coded in the configuration files.

You can verify the public accessibility of the RDS Database by running and entering the password stored in parameter store.

```
mysql -h <rds_endpoint> -u <database_username> -p 
```
* The ECS service launches the ecs task definition in public subnets, hence the web application tier is accessible through a public ip, and also through the load balancer, since the ecs security group has ingress for the load balancer security group. 

* The Load Balancer has listeners for both HTTP and HTTPS, this allows access to the application through an A record (alias) created with the registered dns that has ACMS certificate, due to SSL termination.

* The EFS is mounted in private subnets. 


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

* Run the following commands in succession
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

![Screenshot (128)](https://github.com/user-attachments/assets/69c24d85-8870-4dd0-aa49-f690752471b0)

* You can run ```terraform state list``` to list all resources created:

![Screenshot (126)](https://github.com/user-attachments/assets/c5f198a3-c75a-48f9-bf56-5c883aaac918)


* The wordpress application would be accessible via load balancer dns, your dns name, and the public ip of the container.

Via load balancer dns:

![Screenshot (123)](https://github.com/user-attachments/assets/bd0fb194-ffbd-433f-9972-5a7d6a4321ba)

Via dns name:

![Screenshot (124)](https://github.com/user-attachments/assets/8b0f0557-0dee-463f-acf7-564c6b499ef4)

Via public ip:

![Screenshot (125)](https://github.com/user-attachments/assets/d006d860-4628-4161-b43b-10a945ad697a)


So you proceed to choose your preferred language, enter your credentials as a user on wordpress and click install, and log in to wordpress, as in the pictures below: 

![Screenshot (149)](https://github.com/user-attachments/assets/2f92f5eb-ea54-4c62-88dc-b9b8bfc2a696)

![Screenshot (151)](https://github.com/user-attachments/assets/19c91dee-a2e1-4ca5-b852-d89a896253ed)

![Screenshot (152)](https://github.com/user-attachments/assets/fbf87dd3-ce2d-47e9-b485-654305e0c919)

* To destroy the resources, run
````
terraform destroy
````

## CICD

Pre-requisite:
* AWS Access and Secret keys                   #___In the absence of a github actions role for openid connect___
* GitHub actions role for openid connect  (This is optional, but for enhanced security)


The repository deploys a CI/CD for the terraform configuration using [action.yml](https://github.com/seyramgabriel/CloudSec-Terraform-Project/blob/main/.github/workflows/action.yml) file, and [oidc.yaml](https://github.com/seyramgabriel/CloudSec-Terraform-Project/blob/main/.github/workflows/oidc.yaml) as alternative, for better security.


The github/workflows/action.yml file uses AWS access key and secret key defined in the repository secret to authenticate to the AWS account, whiles .github/workflows/oidc.yaml uses open id connect.

To use open id connect rather than AWS access key and secret key, you can run the terraform configuration in the openid directory as follows:

```
cd openid
```

Modify the provider.tf file, ensure you are using your own created bucket and key for backend storage.

Modify the variable.tf file to reflect the region of your choice. The region should be same as is in your oidc file.

Modify the 'repo' from "seyramgabriel/*" to reflect your GitHub user account.


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

This will create a role (whose name and arn are quoted in the oidc.yaml file) with a policy that allows for authentication from your GitHub repository into your AWS Account. You would just have to change the AWS account ID in "arn:aws:iam::431877974142:role/GithubActions" in the oidc.yaml file, then you can now use oidc.yaml file to deploy the terraform configuration into your AWS Account.

### How to trigger the workflow

The actions are set to be triggered manually (workflow_dispatch) by choosing either "apply" or "destroy" as inputs as displayed below:

![Screenshot (120)](https://github.com/user-attachments/assets/d773f373-22be-44b8-ab05-6e493d132054)


Apply:

Choose "apply" and click "Run workflow"

![Screenshot (118)](https://github.com/user-attachments/assets/ed45f436-9e93-48db-ae48-19826a398de8)


Destroy:

Choose "destroy" and click "Run workflow"

![Screenshot (119)](https://github.com/user-attachments/assets/80c347d3-89f0-470d-a679-69886365dd1b)



## Project Architecture 


![Cloudsec-terraform-project](https://github.com/user-attachments/assets/d8f213f0-fd7a-4ef0-ab7f-8f1360a48db9)





