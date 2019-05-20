variable "fgt-byol-amis" {
  description = "FortiGate BYOL AMIs by region"
  type = "map"
  default = {
    "ap-northeast-1"  = "ami-021c40c8d7d07a99a"
    "ap-northeast-2"  = "ami-09c6e2b31c5aeeef5"
    "ap-south-1"      = "ami-066e2d633f25457cf"
    "ap-southeast-1"  = "ami-0b09627a8727a840e"
    "ap-southeast-2"  = "ami-03812d85cf5ab60b6"
    "ca-central-1"    = "ami-0e2dfde704479020d"
    "eu-central-1"    = "ami-084fbc093774e3d55"
    "eu-west-1"       = "ami-01e8b02ab1ac6f0be"
    "eu-west-2"       = "ami-0fee8ad3dbfdc59f7"
    "eu-west-3"       = "ami-01f28c942780fe93d"
    "sa-east-1"       = "ami-0e2e26cbaae02e210"
    "us-east-1"       = "ami-0545ab5cfcb04ae1f"
    "us-east-2"       = "ami-06c0b5327ae077f9b"
    "us-west-1"       = "ami-0a2dd80d792806156"
    "us-west-2"       = "ami-0e02bbdf523a30000"
  }
}

variable "fgt-ond-amis" {
  description = "FortiGate On Demand AMIs by region"
  type = "map"
  default = {
    "ap-northeast-1"  = "ami-0b7ea934fc0a83064"
    "ap-northeast-2"  = "ami-0c9c34c5ac1adc829"
    "ap-south-1"      = "ami-08509cefe5c6372a8"
    "ap-southeast-1"  = "ami-01b05e38c6388f84f"
    "ap-southeast-2"  = "ami-029bca18bc8f272cd"
    "ca-central-1"    = "ami-0b1d312dc1c41030e"
    "eu-central-1"    = "ami-0a4498f9a72cf2537"
    "eu-west-1"       = "ami-0c1f71f51fb106a31"
    "eu-west-2"       = "ami-0d333d8821f37aa36"
    "eu-west-3"       = "ami-0a97f4194a0515b21"
    "sa-east-1"       = "ami-0851b028d263ced22"
    "us-east-1"       = "ami-0532fcbf3ada1987a"
    "us-east-2"       = "ami-07c2582e55a222dd3"
    "us-west-1"       = "ami-0aa77e91cb3eab854"
    "us-west-2"       = "ami-00a5f7f2848b21194"
  }
}
