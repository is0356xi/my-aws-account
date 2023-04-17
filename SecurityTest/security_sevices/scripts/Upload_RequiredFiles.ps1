Param(
    [Parameter(mandatory=$true)][String]$dst_bucket_name,
    [Parameter(mandatory=$true)][String]$profile
)

function search_files($folder_path){
    $files = Get-ChildItem -Path $folder_path -File
    return $files
}

function copy_files($files, $dst_bucket_name, $profile){
    foreach ($file in $files) {
        # aws s3 copyの実行
        aws s3 cp --profile $profile $file "s3://${dst_bucket_name}"
        $s3_status = $?
    }
}

# テンプレートファイル群を取得
$template_folder_path = ".\templates\chirdlen\"
$files = search_files $template_folder_path

# ステートマシンファイル群を取得し、ファイルリストに追加
$statemachine_folder_path = ".\sam_src\Notification-StepFunctions\statemachine\"
$files += search_files $statemachine_folder_path

# 指定されたS3へコピー
copy_files $files $dst_bucket_name $profile