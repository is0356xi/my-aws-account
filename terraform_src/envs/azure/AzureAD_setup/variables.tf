# 環境固有の変数
variable "env_params" {
  default = {
    location            = "japaneast"
    resource_group_name = "identity"
    tag = {
      Env = "dev"
    }
  }
}

# グループのパラメータ
variable "group_params" {
  default = {
    admins = {
      display_name     = "admins"
      security_enabled = true
    }
    developers = {
      display_name     = "developers"
      security_enabled = true
    }
  }
}

# ユーザのパラメータは別ファイル:user_vars.tfで管理 (認証情報が記述されているため。)