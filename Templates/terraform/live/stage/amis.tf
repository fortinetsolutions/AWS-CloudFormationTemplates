variable "fortigate-od-amis" {
  description = "AMIs by region"
  type = "map"
  default = {
    "us-east-1"       = "ami-97f7d480"
    "us-east-2"       = "ami-904b11f5"
    "eu-west-1"       = "ami-90c592e3"
    "eu-west-2"       = "ami-462d2722"
    "eu-central-1"    = "ami-7ea45e11"
    "ap-northeast-1"  = "ami-a2b917c3"
    "ap-northeast-2"  = "ami-a84296c6"
    "ap-southeast-1"  = "ami-24359547"
    "ap-southeast-2"  = "ami-f969569a"
    "ap-south-1"      = "ami-6c9aee03"
    "sa-east-1"       = "ami-15f56a79"
    "us-west-1"       = "ami-76e8a216"
    "us-west-2"       = "ami-933797f3"
    "ca-central-1"    = "ami-e5823081"
  }
}

variable "fortigate-byol-amis" {
  description = "AMIs by region"
  type = "map"
  default = {
    "us-east-1"       = "ami-f2f0d3e5"
    "us-east-2"       = "ami-88570ded"
    "eu-west-1"       = "ami-1ac79069"
    "eu-west-2"       = "ami-e62f2582"
    "eu-central-1"    = "ami-22a75d4d"
    "ap-northeast-1"  = "ami-eebb158f"
    "ap-northeast-2"  = "ami-c74c98a9"
    "ap-southeast-1"  = "ami-67359504"
    "ap-southeast-2"  = "ami-686b540b"
    "ap-south-1"      = "ami-dd9befb2"
    "sa-east-1"       = "ami-f0f8679c"
    "us-west-1"       = "ami-3be8a25b"
    "us-west-2"       = "ami-113b9b71"
    "ca-central-1"    = "ami-698a380d"
  }
}

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

variable "amazon-linux-amis" {
    description = "AMIs by region"
    type = "map"
    default = {
      "us-east-1" =  "ami-4fffc834"
      "us-west-2" = "ami-aa5ebdd2"
    }
}

variable "ftpserver-amis" {
  description = "AMIs by region"
  type = "map"
  default = {
    "us-east-1" = "ami-b82664ae"
    "us-west-2" = "ami-b4c2cacd"
  }
}

variable "ftpclient-amis" {
    description = "AMIs by region"
    type = "map"
    default = {
      "us-east-1" =  "ami-e82361fe"
      "us-west-2" = "ami-e0ebe499"
    }
}
