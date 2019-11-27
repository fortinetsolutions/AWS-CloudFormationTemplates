variable "name" {
  description = "Name to be used on all the resources as identifier."
}

variable "description" {
  default     = ""
  description = "Description of what your Lambda Function does."
}

variable "handler" {
  description = "The function entrypoint in your code. "
}

variable "runtime" {
  description = "The function runtime to use. (nodejs, nodejs4.3, nodejs6.10, nodejs8.10, java8, python2.7, python3.6, dotnetcore1.0, dotnetcore2.0, dotnetcore2.1, nodejs4.3-edge, go1.x)"
}

variable "package_path" {
  description = "The path to the function's deployment package within the local filesystem."
}
