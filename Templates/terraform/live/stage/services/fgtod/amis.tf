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
