terraform {
    required_providers {
       aws = {
        source = "hashicorp/aws"
        version = "~> 4.0"
       }
    }
}

provider aws{
    # Terraformで作成されるリソースに付与されるデフォルトのタグ
    default_tags {
        tags = var.env_params.tag
    }
}