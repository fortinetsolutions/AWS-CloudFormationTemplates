access_key = ""
secret_key = ""

aws_region                     = "us-east-1"
customer_prefix                = "asg-concur"
environment                    = "stage"
lambda_name                    = "handler"
lambda_description             = "Fortigate Autoscale Lambda Function"
lambda_handler                 = "lambda_handler.handler"
lambda_runtime                 = "python2.7"
lambda_package_path            = "../build/functions.zip"
vpc_id                         = "vpc-0965cb963ac631678"
public1_subnet_id              = "subnet-05e9c0faddb524065"
public2_subnet_id              = "subnet-0476296f77c7e7792"
private1_subnet_id             = "subnet-0c7f21f6cada96541"
private2_subnet_id             = "subnet-0448a5c4b8c2dd2f2"
keypair                        = "kp-poc-common"
customer_prefix                = "asg-concur"
environment                    = "stage"
cidr_for_access                = "0.0.0.0/0"
instance_type                  = "c5.large"
public_ip                      = true
sg_name                        = "fgt"
max_size-byol                  = 2
min_size-byol                  = 0
desired-byol                   = 0
max_size-paygo                 = 5
min_size-paygo                 = 0
desired-paygo                  = 0
sns_topic                      = "fgtautoscale-sns"



