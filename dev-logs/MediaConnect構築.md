# 構築手順

## 事前準備
- ```.\terraform_src\terraform.tfvars```を作成し、profile_nameを追加

```sh:
profile_name = "<AWS CLIのプロファイル名>"
```



## ①MediaConnect Flowを作成
- CloudFormation

```sh:
cd MediaConnect
.\scripts\Deploy_MediaConnect.ps1 <profile-name>
CreateFlow or AddOutput: CreateFlow
```

## ②VPCInterfaceを使用するためのリソース作成
- Terraform
  - VGW, VPC, Subnet, SecurityGroup, IAM Role

```sh:
cd .\terraform_src
terraform apply --auto-approve

# Error: AWS SDK Go Service Operation Incompleteが発生した場合、もう一度実行
terraform apply --auto-approve
```

## ③FlowにOutputを追加
- CloudFormation

```sh:
cd ../
.\scripts\Deploy_MediaConnect.ps1 <profile-name>
CreateFlow or AddOutput: AddOutput
```

-------------------------
# 削除

## CloudFormation Stack

```sh:
.\scripts\Deploy_MediaConnect.ps1 <profile-name>
CreateFlow or AddOutput: delete
```


## Terraform

```sh:
cd .\terraform_src
terraform destroy --auto-approve
```