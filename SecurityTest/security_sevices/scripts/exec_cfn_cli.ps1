Param(
    [Parameter(mandatory=$true)][String]$template_file_path,
    [Parameter(mandatory=$true)][String]$stack_name,
    [String]$profile = "default",
    [String]$region = "ap-northeast-1"
)

function stack_deploy(){
    # スタックデプロイ時のパラメータを抽出
    $parameters = cat ./templates/parameters.cfg
    
    # aws cloudformationコマンドでスタックデプロイ
    aws --region $region --profile $profile `
        cloudformation deploy `
        --template-file $template_file_path `
        --stack-name $stack_name `
        --parameter-overrides $parameters `
        --capabilities CAPABILITY_NAMED_IAM # IAMリソースの作成を許可 

    # スタックデプロイのステータスをreturn
    $status = $?  # $?=直前のコマンドのステータスが格納されている
    return $status
}

function copy_to_s3($template_file_path, $profile){
    # テンプレートファイルを保存するS3バケット名を入力
    echo "Specify the S3 bucket-name to store your file"
    $dst_bucket_name = Read-Host "s3 bucket-name -->"

    # aws s3 copyの実行
    aws s3 cp --profile $profile $template_file_path "s3://${dst_bucket_name}"
    $s3_status = $?

    # copyに成功した場合、コピー先URLを表示
    if ($s3_status -eq "True"){
        echo "----------------------------------"
        $file_name = $template_file_path.Split("\")[-1]

        # リージョン別でURLが異なる
        if ($region -eq "us-east-1"){
            echo "*** S3-URL = https://${dst_bucket_name}.s3.amazonaws.com/${file_name} ***"
        }
        else{
            echo "*** S3-URL = https://${dst_bucket_name}.s3.${region}.amazonaws.com/${file_name} ***"
        }
    }
}

function deploy(){
    # エラー発生時の中断を回避
    $ErrorActionPreference = "Contivue"

    # 子スタックのデプロイを実行
    echo "Deploying ..."
    $deploy_status = stack_deploy
    echo "*** deploy-status = $deploy_status"

    # デプロイが成功した場合、テンプレートファイルをS3に保存
    if ($deploy_status -eq "True"){
        $s3_status = copy_to_s3 $template_file_path $profile
        echo $s3_status
    }
}

function delete (){
    aws --region $region --profile $profile cloudformation delete-stack --stack-name $stack_name
    echo $?
}

function main(){
    $type = Read-Host "deploy or delete or external?"

    if ($type -eq "deploy"){
        deploy
    }
    elseif ($type -eq "delete") {
        delete
    }
    elseif ($type -eq "external"){
        echo "Called by External Script."
    }
}


$Env:aws_cli_file_encoding="UTF-8"
main