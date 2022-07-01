Param(
    [parameter(Mandatory = $true)]
    [string]$website_name,
    [parameter(Mandatory = $true)]
    [string]$app_name,
    [parameter(Mandatory = $true)]
    [string]$app_pool_name,
    [parameter(Mandatory = $true)]
    [string]$physical_path,
    [parameter(Mandatory = $false)]
    [string]$user_service,
    [parameter(Mandatory = $false)]
    [SecureString]$password_service
)

# Import module for creating webapp on IIS
Import-Module WebAdministration;

if ($physical_path.ToString() -eq "")
{
    $physical_path = "C:\inetpub\wwwroot\";
}

if (website_name.ToString() -eq "")
{
    $website_name = "Default Web Site";
}

# create app pool if it doesn't exist
if (Get-IISAppPool -Name $Using:app_pool_name) {
    Write-Output "The App Pool $Using:app_pool_name already exists"
}
else {
    Write-Output "Creating app pool $Using:app_pool_name"
    $app_pool = New-WebAppPool -Name $Using:app_pool_name
    $app_pool.autoStart = $true
    $app_pool.managedPipelineMode = "Integrated"
    $app_pool | Set-Item
    Write-Output "App pool $Using:app_pool_name has been created"
}

 # create the folder if it doesn't exist
if (Test-path $Using:physical_path) {
    Write-Output "The folder $Using:physical_path already exists"
}
else {
    New-Item -ItemType Directory -Path $Using:physical_path -Force
    Write-Output "Created folder $Using:physical_path"
}

# Create New WebApplication
New-WebApplication $app_name -Site $website_name -ApplicationPool $app_pool_name  -PhysicalPath $physical_path;

Write-Output "Deploy WebApp sucessfully"