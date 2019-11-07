## step 1 > setup ubuntu host with terraform + zip.  example ubuntu 18.04 commands below.
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y unzip
wget https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_linux_amd64.zip
sudo unzip terraform_0.11.10_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version


## step 2 > download and stage demo terraform templates
wget https://hacorp-base.s3.amazonaws.com/TransitGateway-ECMP-VPN.zip
sudo unzip TransitGateway-ECMP-VPN.zip
cd TransitGateway-ECMP-VPN/
sudo cp examples/FGT_TGW_ECMP_VPN_NewVPCs_PAYG/* ./
cat terraform.tfvars


## step 3 > update 'terraform.tfvars' with relevant information
sudo nano terraform.tfvars
####################
access_key = "... omitted output ..."
secret_key = "... omitted output ..."

region = "us-east-2"
availability_zone1 = "us-east-2a"
availability_zone2 = "us-east-2b"

keypair = "my-keypair"
cidr_for_access = "0.0.0.0/0"
tag_name_prefix = "tf1"
####################


## step 4 > initialize terraform
sudo terraform init
####################
Initializing modules...
- module.transit-gw
  Getting source "modules/ftnt_aws/vpc/tgw"
- module.security-vpc
  Getting source "modules/ftnt_aws/vpc/vpc-security-tgw"
- module.spoke-vpc1
  Getting source "modules/ftnt_aws/vpc/vpc-spoke-tgw"
- module.spoke-vpc2
  Getting source "modules/ftnt_aws/vpc/vpc-spoke-tgw"
- module.elb
  Getting source "modules/ftnt_aws/vpc/elb"
- module.fgt1
  Getting source "modules/ftnt_aws/fgt/1instance_tgw_vpn_payg"
- module.fgt2
  Getting source "modules/ftnt_aws/fgt/1instance_tgw_vpn_payg"

Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "aws" (1.52.0)...
- Downloading plugin for provider "template" (1.0.0)...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.aws: version = "~> 1.52"
* provider.template: version = "~> 1.0"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
####################


## step 5 > deploy terraform templates (deployment ~10 mins)
sudo terraform apply
####################
... omitted output ...
... omitted output ...
... omitted output ...

Plan: 39 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
  
... omitted output ...
... omitted output ...
... omitted output ...

Apply complete! Resources: 39 added, 0 changed, 0 destroyed.

Outputs:

fgt1_login_url = https://18.219.84.212
fgt1_password = i-06aebb6e73af1e006
fgt2_login_url = https://18.220.167.212
fgt2_password = i-08293ace25d4375ac
fgt_username = admin
tgw_default_association_id = tgw-rtb-04fe52f8fb55e9a8a
tgw_default_route_table_id = tgw-rtb-04fe52f8fb55e9a8a
tgw_id = tgw-0327c416c8d64e265
tgw_private_route_table = tgw-rtb-02b46bf11dbaa8c8d
####################

## step 6 > update tgw route tables
- find default tgw route table and go to propagations
	- delete the two vpn entries
- find private tgw route table and go to propagations
	- add the two vpn entries


## step 7 > validate private tgw route table has expected routes
	- '0.0.0.0/0' with two attachments to both fgt's vpns
	- '100.64.0.1/32' with attachment to fgt1's vpn
	- '100.64.0.2/32' with attachment to fgt1's vpn


## step 8 > deploy test instances in both spoke vpcs and create vips on either FGT to ssh\rdp to test instances. example vips and policy below:

####################
config firewall vip
edit spoke1-srv1
set extint port1
set mappedip <-- your 1st test instance ip -->
set portforward enable
set extport 221
set mappedport 22
next
edit spoke2-srv1
set extint port1
set mappedip <-- your 2nd test instance ip -->
set portforward enable
set extport 222
set mappedport 22
next
end

config firewall policy
edit 0
set srcintf "port1"
set dstintf "transit-gw"
set srcaddr "all"
set dstaddr "spoke1-srv1" "spoke2-srv1"
set action accept
set schedule "always"
set service "ALL"
set logtraffic all
set nat enable
set ippool enable
set poolname "ippool"
next
end
####################


## step 9 > test traffic flow
	- north\south: will be snat'd to fgt's 100.64.0.x ip with ippool
	- south\north: will be snat'd to fgt's port1 ip, then aws snat's to mapped eip
	- easth\west: will be snat'd to fgt's 100.64.0.x ip with ippool


## step 10 > delete the previously deployed test instances and any other aws resource added manually


## step 11 > delete demo environment
sudo terraform destroy
####################
... omitted output ...
... omitted output ...
... omitted output ...

Plan: 0 to add, 0 to change, 39 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
####################


## step 12 > if terraform is unable to delete the spoke vpcs successfully, delete these manually in the aws vpc console.  Then clean up the root terraform folder.

sudo rm *.tf*

####################
... omitted output ...
... omitted output ...
... omitted output ...

Error: Error applying plan:

2 error(s) occurred:

* module.spoke-vpc2.aws_vpc.vpc (destroy): 1 error(s) occurred:

* aws_vpc.vpc: DependencyViolation: The vpc 'vpc-02aeaff1061fcbf6a' has dependencies and cannot be deleted.
        status code: 400, request id: 6748b80c-c583-4669-9a41-9d47169d03e5
* module.spoke-vpc1.aws_vpc.vpc (destroy): 1 error(s) occurred:

* aws_vpc.vpc: DependencyViolation: The vpc 'vpc-0ed5f7fc2b89b10e4' has dependencies and cannot be deleted.
        status code: 400, request id: e9aea2b4-fee1-469a-b2f1-6e46a17dd894

Terraform does not automatically rollback in the face of errors.
Instead, your Terraform state file has been partially updated with
any resources that successfully completed. Please address the error
above and apply again to incrementally change your infrastructure.
####################


###
end of file
###
