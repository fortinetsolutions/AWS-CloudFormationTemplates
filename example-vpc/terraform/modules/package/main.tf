
data "external" "lambda_packager" {
  program = ["${path.module}/scripts/package.py"]

  query = {
    path          = "${var.path}"
    include_paths = "${join(",", var.include_paths)}"
    output_path   = "${local.output_path}"
  }
}
