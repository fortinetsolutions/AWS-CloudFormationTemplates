access_key                  = ""
secret_key                  = ""

aws_region                  = "us-west-2"
customer_prefix             = "mdw"
environment                 = "dev"
availability_zone_1         = "us-west-2a"
vpc_cidr                    = "10.0.0.0/16"
public_subnet_cidr1         = "10.0.0.0/24"
public1_description         = "public1-subnet-az1"
public1_ip_address          = "10.0.0.10"
private_subnet_cidr1        = "10.0.1.0/24"
private1_description        = "private1-subnet-az1"
private1_ip_address         = "10.0.1.10"
keypair                     = "mdw-key-oregon"
cidr_for_access             = "0.0.0.0/0"
fortigate_instance_type     = "c5n.2xlarge"
fortigate_instance_name     = "Example Fortigate"
public_ip                   = 1
s3_license_bucket           = "mdw-license-bucket"cd
acl                         = "private"
fortigate_ami_string        = "FortiGate-VM64-AWS build0303 (6.0.8) GA*"
fgt_byol_license            = "fgt1-license.lic"
fgt_password_parameter_name = "password"



