variable "fgt-byol-amis" {
  description = "FortiGate BYOL AMIs by region"
  type = "map"
  default = {
    "ap-northeast-1"  = "ami-0b9bc09695bf7c967"
    "ap-northeast-2"  = "ami-0ff0fd10808128023"
    "ap-south-1"      = "ami-0d889113856925795"
    "ap-southeast-1"  = "ami-04691e16b255aff57"
    "ap-southeast-2"  = "ami-0359d65a4bfa062f8"
    "ca-central-1"    = "ami-0d4e110f611e01904"
    "eu-central-1"    = "ami-077ad124a89b1114e"
    "eu-west-1"       = "ami-0d165a63c9b7dfc29"
    "eu-west-2"       = "ami-0864b9b972c22b53a"
    "eu-west-3"       = "ami-033a64b3420b3a2ae"
    "sa-east-1"       = "ami-0fd3bcbeb96bd6500"
    "us-east-1"       = "ami-064f119cc6dae3186"
    "us-east-2"       = "ami-0990734e0724c409e"
    "us-west-1"       = "ami-0a5c134467f7781fa"
    "us-west-2"       = "ami-0b32d672dfa76305f"
  }
}

variable "fgt-ond-amis" {
  description = "FortiGate On Demand AMIs by region"
  type = "map"
  default = {
    "ap-northeast-1"  = "ami-0bd9e6e0020928ef9"
    "ap-northeast-2"  = "ami-0a560b6c089c6310a"
    "ap-south-1"      = "ami-0c5a28e0b56028d6d"
    "ap-southeast-1"  = "ami-000c0166f49864e4a"
    "ap-southeast-2"  = "ami-0e3662b3f822e3be4"
    "ca-central-1"    = "ami-0583f62d15a462f5c"
    "eu-central-1"    = "ami-0af055c02be246473"
    "eu-west-1"       = "ami-0aeda1bdca1b205bd"
    "eu-west-2"       = "ami-0de7050ef166ab900"
    "eu-west-3"       = "ami-0ce86abfa74c76ad2"
    "sa-east-1"       = "ami-0424ffd602f0af643"
    "us-east-1"       = "ami-09e4f25ec992c94ab"
    "us-east-2"       = "ami-0a1f403f5e0cfa88e"
    "us-west-1"       = "ami-057300bd7e60ea2b2"
    "us-west-2"       = "ami-0ea3f14da73832fdc"
  }
}
