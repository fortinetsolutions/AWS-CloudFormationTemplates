variable "fgt-byol-amis" {
  description = "FortiGate BYOL AMIs by region"
  type = "map"
  default = {
    "ap-northeast-1"  = "ami-2865a957"
    "ap-northeast-2"  = "ami-dc9b31b2"
    "ap-south-1"      = "ami-bb88a0d4"
    "ap-southeast-1"  = "ami-5f6a6d23"
    "ap-southeast-2"  = "ami-6eaa750c"
    "ca-central-1"    = "ami-25028141"
    "eu-central-1"    = "ami-6a85b581"
    "eu-west-1"       = "ami-3da3ae44"
    "eu-west-2"       = "ami-878d63e0"
    "eu-west-3"       = "ami-ae2e9fd3"
    "sa-east-1"       = "ami-03461d6f"
    "us-east-1"       = "ami-48400137"
    "us-east-2"       = "ami-340a3451"
    "us-west-1"       = "ami-05de3a66"
    "us-west-2"       = "ami-b6befdce"
  }
}

variable "fgt-ond-amis" {
  description = "FortiGate On Demand AMIs by region"
  type = "map"
  default = {
    "ap-northeast-1"  = "ami-ff4b2012"
    "ap-northeast-2"  = "ami-b89720d6"
    "ap-south-1"      = "ami-ce0033a1"
    "ap-southeast-1"  = "ami-b546025f"
    "ap-southeast-2"  = "ami-35be1957"
    "ca-central-1"    = "ami-05911c61"
    "eu-central-1"    = "ami-89161662"
    "eu-west-1"       = "ami-17e0f9fd"
    "eu-west-2"       = "ami-5ca64c3b"
    "eu-west-3"       = "ami-2d883850"
    "sa-east-1"       = "ami-438fa92f"
    "us-east-1"       = "ami-0426217b"
    "us-east-2"       = "ami-a94c76cc"
    "us-west-1"       = "ami-408e6323"
    "us-west-2"       = "ami-42dc833a"
  }
}
