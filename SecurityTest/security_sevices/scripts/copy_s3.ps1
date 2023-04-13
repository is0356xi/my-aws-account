Param(
    [Parameter(mandatory=$true)][String]$src_file_path,
    [Parameter(mandatory=$true)][String]$profile
)

. ../../scripts/exec_cfn_cli.ps1 $src_file_path "tmp-stack-name" $profile

copy_to_s3 $src_file_path $profile