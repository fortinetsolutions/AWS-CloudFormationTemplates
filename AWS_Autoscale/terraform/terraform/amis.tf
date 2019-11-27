variable "fortigate-od-amis" {
  description = "AMIs by region"
  type = "map"
  default = {
    "us-east-1"       = "ami-073b7839422f625e5"
  }
}

variable "fortigate-byol-amis" {
  description = "AMIs by region"
  type = "map"
  default = {
    "us-east-1"       = "ami-f2f0d3e5"
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
