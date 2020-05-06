variable "name" {
  default     = "functions.zip"
  description = "The name of the package .zip file when no path is specified. The path will result in ./.terraform/$(name).zip."
}

variable "path" {
  description = "The file or directory which should be part of of the package .zip file within the local filesystem."
  default     = "../build/"
}

variable "include_paths" {
  default     = []
  description = "Additional files and directories which should be part of of the package .zip file within the local filesystem."
}

variable "output_path" {
  default     = "../build/"
  description = "The path of the package .zip file within the local filesystem."
}
