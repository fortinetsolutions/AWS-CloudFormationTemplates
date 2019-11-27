access_key = ""
secret_key = ""

aws_region                     = "us-east-1"
customer_prefix                = "asg-concur"
environment                    = "stage"
vpc_id                         = "vpc-0965cb963ac631678"
private1_subnet_id             = "subnet-0c7f21f6cada96541"
private2_subnet_id             = "subnet-0448a5c4b8c2dd2f2"
keypair                        = "kp-poc-common"
customer_prefix                = "asg-concur"
environment                    = "stage"
cidr_for_access                = "0.0.0.0/0"
instance_type                  = "t2.micro"
public_ip                      = true
sg_name                        = "ec2"
max_size                       = 5
min_size                       = 2
desired                        = 2







