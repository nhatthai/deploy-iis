Param(
    [parameter(Mandatory = $true)]
    [string]$server,
    [parameter(Mandatory = $true)]
    [string]$app_name,
    [parameter(Mandatory = $true)]
    [string]$app_pool_name,
    [parameter(Mandatory = $true)]
    [string]$physical_path,
    [parameter(Mandatory = $true)]
    [string]$deploy_user_id,
    [parameter(Mandatory = $true)]
    [string]$deploy_user_secret,
    [string]$website_name = "",
    [string]$app_pool_user_service = "",
    [string]$app_pool_password_service = ""
)

# Import module for creating webapp on IIS
Import-Module WebAdministration;

Write-Output "Create Credential"

[System.Security.SecureString]$SecurePassword = ConvertTo-SecureString $deploy_user_secret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($deploy_user_id, $SecurePassword)
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

if (($app_pool_user_service.Length -gt 0) -and ($app_pool_password_service.Length -gt 0)) {
    Write-Output "Create App Pool Credential"
    [System.Security.SecureString]$PasswordService = ConvertTo-SecureString $app_pool_password_service -AsPlainText -Force
    $app_pool_credential = New-Object System.Management.Automation.PSCredential($app_pool_user_service, $PasswordService)
    $set_app_pool_secret = $app_pool_credential.GetNetworkCredential().Password
}

Write-Output "Set Default values"

# set Default value
if ($physical_path.ToString() -eq "")
{
    $physical_path = "C:\inetpub\wwwroot\";
}

# set Default value
if ($website_name.ToString() -eq "")
{
    $website_name = "Default Web Site";
}

$script = {
    Write-Output "Create Application Pool"

    # create app pool if it doesn't exist
    if (Get-IISAppPool -Name $Using:app_pool_name)
    {
        Write-Output "The App Pool $Using:app_pool_name already exists"
    }
    else
    {
        Write-Output "Creating app pool $Using:app_pool_name"
        $app_pool = New-WebAppPool -Name $Using:app_pool_name
        $app_pool.autoStart = $true
        $app_pool.managedPipelineMode = "Integrated"
        $app_pool | Set-Item
        Write-Output "App pool $Using:app_pool_name has been created"
    }

    Write-Output "Create folder for Web App"
    # create the folder if it doesn't exist
    if (Test-path $Using:physical_path)
    {
        Write-Output "The folder $Using:physical_path already exists"
    }
    else
    {
        New-Item -ItemType Directory -Path $Using:physical_path -Force
        Write-Output "Created folder $Using:physical_path"
    }

    # Run as the user(set service account)
    if (($Using:app_pool_user_service.Length -gt 0) -and ($Using:app_pool_password_service.Length -gt 0))
    {
        Write-Output "Set property for $Using:app_pool_name"
        Set-ItemProperty IIS:\AppPools\MySite -Name "managedRuntimeVersion" -Value "v4.0"
        Set-ItemProperty IIS:\AppPools\$Using:app_pool_name -name processModel -value @{userName=$Using:app_pool_user_service;password=$Using:app_pool_password_service;identitytype=3}
    }
    else
    {
        Write-Output "Do not set property for $Using:app_pool_name"
    }

    # Create New WebApplication
    New-WebApplication "$Using:app_name" -Site "$Using:website_name" -ApplicationPool "$Using:app_pool_name"  -PhysicalPath "$Using:physical_path" -Force;

    Write-Output "Deploy WebApp sucessfully"
}

Invoke-Command -ComputerName $server -Credential $credential -UseSSL -SessionOption $so -ScriptBlock $script

Write-Output "IIS Site Created"
