variable "access_key" {}
variable "secret_key" {}
variable "region" {
  description = "Provide the region to deploy the transit gateway in"
  default = "us-east-1"
}
variable "tag_name_prefix" {
  description = "Provide a tag prefix value that that will be used in the name tag for all resources"
  default = "stack-1"
}