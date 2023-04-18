Param(
    [Parameter(mandatory=$true)][String]$profile,
    [String]$region1 = "us-east-1",
    [String]$region2 = "ap-northeast-1"
)

function create_stack($template_file_path, $stack_name, $region_map){
    # リージョン情報を抽出
    $region_key = $region_map.Keys[0]
    $region_value = $region_map.Values[0]

    # スタックデプロイ時のパラメータを抽出
    $param_path = "./templates/${region_key}/parameters_mediaconnect.cfg"
    $parameters = cat $param_path
    
    # aws cloudformationコマンドでスタックデプロイ
    aws --region $region_value --profile $profile `
        cloudformation deploy `
        --template-file $template_file_path `
        --stack-name $stack_name `
        --parameter-overrides $parameters `
        --capabilities CAPABILITY_NAMED_IAM # IAMリソースの作成を許可 
}

function get_flowip($ParamPaths, $region){
    # 作成したFlowのIPアドレスを取得
    $FlowsIP = New-Object System.Collections.ArrayList
    foreach ($path in $ParamPaths) {
        $FlowsIP.Add((aws ssm get-parameter --region $region --profile $profile --name $path --query Parameter.Value --output text))
    }

    return $FlowsIP
}


function create_flow($region1, $region2){
    # リージョンをKey:Value形式にする
    $region1_map = @{
        region1 = $region1
    }
    $region2_map = @{
        region2 = $region2
    }

    # リージョン1でFlowを作成
    $region1_flow_template = ".\templates\region1\Create_Flows_MultiAZ.yaml"
    $region1_stack_name = "region1-flow-stack"
    create_stack $region1_flow_template $region1_stack_name $region1_map
    
    # リージョン1で作成したFlowのIPを取得
    $ParamPaths = "/Region1FlowPrimaryIP", "/Region1FlowSecondaryIP"
    $results = get_flowip $ParamPaths $region1
    $region1_FlowsIp = $results[-2..-1]
   
    # リージョン2でリージョン1からのInboundを許可するためのパラメータ設定
    $param_path = "./templates/region2/parameters_mediaconnect.cfg"
    foreach ($index in 1..($region1_FlowsIP.Length)){
        $flowip = $region1_FlowsIP[$index-1]
        "WhitelistCidrforSource${index}=${flowip}/32" >> $param_path
    }

    # リージョン2でFlowを作成
    $region2_flow_template = ".\templates\region2\Create_Flows_SourceFailover.yaml"
    $region2_stack_name = "region2-flow-stack"
    create_stack $region2_flow_template $region2_stack_name $region2_map

    # リージョン2で作成したFlowのIPを取得
    $ParamPaths = "/Region2FlowPrimaryIP"
    $results = get_flowip $ParamPaths $region2
    $flowip = $results[-1]

    # リージョン1からリージョン2へ出力する際のパラメータ設定
    $param_path = "./templates/region1/parameters_mediaconnect.cfg"
    "Destination=${flowip}" >> $param_path

    # リージョン2OutputのためのVPCインタフェースを作成するためにFlowArnを出力
    $FlowArn = aws cloudformation describe-stacks --profile $profile --region $region2 --stack-name $region2_stack_name --query "Stacks[0].Outputs[?OutputKey=='Region2FlowPrimaryArn'].OutputValue" --output text
    $output_path = ".\terraform_src\terraform.tfvars"
    "flow_arn = `"$FlowArn`"" >> $output_path
}


function add_output($region1, $region2){
    # リージョンをKey:Value形式にする
    $region1_map = @{
        region1 = $region1
    }
    $region2_map = @{
        region2 = $region2
    }

    # リージョン1にOutputを追加
    $region1_flow_template = ".\templates\region1\Add_Output.yaml"
    $region1_stack_name = "region1-output-stack"
    create_stack $region1_flow_template $region1_stack_name $region1_map

    # リージョン2にOutputを追加
    $region2_flow_template = ".\templates\region2\Add_Output_VpcInterface.yaml"
    $region2_stack_name = "region2-output-stack"
    create_stack $region2_flow_template $region2_stack_name $region2_map
}


function delete_stack($stack_name, $region){
    aws --region $region --profile $profile cloudformation delete-stack --stack-name $stack_name
    echo $?
}


function main(){
    $type = Read-Host "CreateFlow or AddOutput"

    if ($type -eq "CreateFlow"){
        create_flow $region1 $region2
    }
    elseif ($type -eq "AddOutput"){
        add_output $region1 $region2
    }
    elseif ($type -eq "delete") 
    {
        # 削除対象のスタック名
        $delete_stacks = "region1-flow-stack", "region1-output-stack", "region2-flow-stack", "region2-output-stack"
        
        foreach($stack_name in $delete_stacks){
            if($stack_name.Split("-")[0] -eq "region1"){
                delete_stack $stack_name $region1
            }
            else{
                delete_stack $stack_name $region2
            }
        }
    }
    else{
        echo "Not Match."
    }
}

main

