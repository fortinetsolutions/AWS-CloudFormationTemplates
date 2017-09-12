variable "worker-amis" {
  description = "AMIs by region"
  type = "map"
  default = {
    "us-east-1"       = "ami-6245d474"
    "us-east-2"       = "ami-349db951"
    "eu-west-1"       = "ami-dccbcfba"
    "eu-west-2"       = "ami-04c4d060"
    "eu-central-1"    = "ami-8869bbe7"
    "ap-northeast-1"  = "ami-860926e1"
    "ap-northeast-2"  = "ami-c818caa6"
    "ap-southeast-1"  = "ami-4f52eb2c"
    "ap-southeast-2"  = "ami-44262f27"
    "ap-south-1"      = "ami-16c7b479"
    "sa-east-1"       = "ami-b0d3b1dc"
    "us-west-1"       = "ami-6480a504"
    "us-west-2"       = "ami-752ab815"
    "ca-central-1"    = "ami-1ed16d7a"
  }
}
