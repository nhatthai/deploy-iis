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


$script = {
    Write-Output "Create Default values"

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

    Write-Output "Create Application Pool"
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
}

Write-Output "Starting Deploy WebApp"

Invoke-Command -ComputerName $server -Credential $credential -UseSSL -SessionOption $so -ScriptBlock $script

Write-Output "IIS Site Created"
