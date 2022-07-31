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

Write-Output "Create App Pool Credential"
[System.Security.SecureString]$PasswordService = ConvertTo-SecureString $app_pool_password_service -AsPlainText -Force
$app_pool_credential = New-Object System.Management.Automation.PSCredential($app_pool_user_service, $PasswordService)
$set_app_pool_secret = $app_pool_credential.GetNetworkCredential().Password

Write-Output "Starting Deploy WebApp"

$script = {
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

    # create app pool if it doesn't exist
    if (Get-IISAppPool -Name $app_pool_name)
    {
        Write-Output "The App Pool $app_pool_name already exists"
    }
    else
    {
        Write-Output "Creating app pool $app_pool_name"
        $app_pool = New-WebAppPool -Name $app_pool_name
        $app_pool.autoStart = $true
        $app_pool.managedPipelineMode = "Integrated"
        $app_pool | Set-Item
        Write-Output "App pool $app_pool_name has been created"
    }

    # create the folder if it doesn't exist
    if (Test-path $physical_path)
    {
        Write-Output "The folder $physical_path already exists"
    }
    else
    {
        New-Item -ItemType Directory -Path $physical_path -Force
        Write-Output "Created folder $physical_path"
    }

    # Run as the user(set service account)
    if (($app_pool_user_service.ToString() -eq "") -or ($app_pool_password_service.ToString() -eq ""))
    {
        Write-Output "Do not set property for $app_pool_name"
    }
    else
    {
        Write-Output "Set property for $app_pool_name"
        Set-ItemProperty IIS:\AppPools\$app_pool_name -name processModel -value @{userName=$app_pool_user_service;password=$set_app_pool_secret;identitytype=3}
    }

    # Create New WebApplication
    New-WebApplication "$app_name" -Site "$website_name" -ApplicationPool "$app_pool_name"  -PhysicalPath "$physical_path" -Force;

    Write-Output "Deploy WebApp sucessfully"
}

Invoke-Command -ComputerName $server `
    -Credential $credential `
    -UseSSL `
    -SessionOption $so `
    -ScriptBlock $script

Write-Output "IIS Site Created"
