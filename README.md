# CloudSec-Terraform-Project

Welcome to the CloudSec-Terraform-Project

This project launches a wordpress application on AWS ECS, connecting it to a database on AWS RDS and uses AWS EFS as its volume.

## Prerequisites:

* An AWS Account
* AWS Access and Secret keys                   #___In the absence of a github actions role for openid connect___
* S3 bucket for terraform backend state files. The bucket name must be unique, so you cannot use what is in this repository
* Domain name 
* ACMS certificate for the Domain name 


## Network Configuration

The terraform configuration creates: 

* one (1) virtual private cloud.
* Four(4) subnets in two availability zones.
* Two (2) route tables, one is associated with the two subnets to be used as public subnets, and the other is associated with two private subnets (used as subnet group) within which the RDS database is launched.
* One (1) internet gateway which serves as the route for the public route table.
* Four (4) security groups, one for RDS, one for ECS, one for EFS, and one for the Load Balancer:
     
    1. RDS is made to be only privately accessible, but its security group allows traffic from the ECS security group on port 3306. Once you make RDS not publicly accessible, RDS doesn't assign a public IP address to the database. Only Amazon EC2 instances and other resources inside the VPC can connect to your database. 

    2. The ECS security group has ingress for Load Balancer security group on both HTTPS and HTTPS, egress on port 3306 (so that it can communicate with RDS), egress on port 2049 (in order to communicate with EFS on NFS) and egress on port 443 (so that it can pull the container image "wordpress:php8.3-apache" from docker hub). 

    3. The EFS security group has ingress on port 2049 for the ECS security group.

    4. The Load Balancer security group has ingress for both port 80 and 443 (HTTP and HTTPS).

* One (1) Load Balancer.
* One (1) Target Group, with target type being "ip" and health check path of "/wp-admin/install.php".
* Two (1) Listeners for the Load Balancer, one for HTTP and the other for HTTPS.
* One (1) DNS Record on Route 53 to map registered domain name to Load Balancer dns. The "allow overwrite" is set to true, hence it will overwrite any record with same name in Route 53.
* One (1) EFS File System.
* One (1) EFS Access Point for the EFS File System.
* Two (2) Mount Targets in each of two Subnets, hence two availability zones, whiles making use of the EFS security group. 
* One (1) Volume for the container, using the EFS File System.




_Note that the wordpress container needs a database. The details of the RDS database (database host, database name, database username, and database password) are passed on to the wordpress container as environmental variables in the ECS task definition configuration. The database username and password must have been stored as secrets in AWS SSM parameter store before referenced within the configuration_.




* One (1) ECS Cluster, within which the ECS Task Definition will run
* One (1) ECS Rask Definition that will be run by an ecs service.
* One (1) ECS Service, which specifies the vpc, subnets, security group for ECS, Load Balancer and Target Group to run the container specified in the Task Definition. The Target Group is of type "ip", hence the ECS Service dynamically registers the private ip of the container on the Target Group anytime you run the terraform configuration. 
 

## Security
* RDS database is provisioned in a subnet group made up of private subnets. In addition, the publicly_accessible attribute is set to false to ensure that only resources within the VPC can access it. The rds endpoint has been defined in the output.tf for output after apply. 

* A random password is generated for the RDS database, which is stored in SSM parameter store instead of being hard coded in the configuration files.

You can verify the public accessibility by running and entering the password stored in parameter store.

```
mysql -h <rds_endpoint> -u <database_username> -p 
```


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

The repository deploys the terraform configuration using .github/workflows/action.yml file, and .github/workflows/oidc.yaml as alternative, for better security.

The actions are set to be triggered manually (workflow_dispatch) by choosing either "apply" or "destroy" as inputs.

The github/workflows/action.yml file uses AWS access key and secret key defined in the repository secret to authenticate to the AWS account, whiles .github/workflows/oidc.yaml uses open id connect.

To use open id connect, you can run the terraform configuration in the openid directory as follows:

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






