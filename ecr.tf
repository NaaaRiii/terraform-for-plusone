resource "aws_ecr_repository" "plusone_repo" {
  name                 = "plusone-rails"
  image_tag_mutability = "MUTABLE"

  # スキャン設定 (任意)
  image_scanning_configuration {
    scan_on_push = true
  }

}
