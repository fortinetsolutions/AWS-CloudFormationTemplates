output "path" {
  value       = "${local.output_path}"
  description = "The path of the package .zip file within the local filesystem."
}

output "size" {
  value       = "${data.external.lambda_packager.result.output_size}"
  description = "The size of the package .zip file."
}

output "base64sha256" {
  value       = "${data.external.lambda_packager.result.output_base64sha256}"
  description = "The base64-encoded SHA256 checksum of the package .zip file."
}
