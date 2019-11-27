
locals {
  output_path = "${var.output_path != "" ? var.output_path : "${path.cwd}/.terraform/${var.name}.zip"}"
}
