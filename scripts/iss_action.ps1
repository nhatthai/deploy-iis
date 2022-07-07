Param(
    [parameter(Mandatory = $true)]
    [string]$app_name,
    [parameter(Mandatory = $true)]
    [string]$app_pool_name,
    [parameter(Mandatory = $true)]
    [string]$physical_path,
    [string]$website_name = "Default Web Site"
)

# Import module for creating webapp on IIS
Import-Module WebAdministration;

if ($physical_path.ToString() -eq "")
{
    $physical_path = "C:\inetpub\wwwroot\";
}

# create app pool if it doesn't exist
if (Get-IISAppPool -Name $app_pool_name) {
    Write-Output "The App Pool $app_pool_name already exists"
}
else {
    Write-Output "Creating app pool $app_pool_name"
    $app_pool = New-WebAppPool -Name $app_pool_name
    $app_pool.autoStart = $true
    $app_pool.managedPipelineMode = "Integrated"
    $app_pool | Set-Item
    Write-Output "App pool $app_pool_name has been created"
}

 # create the folder if it doesn't exist
if (Test-path $physical_path) {
    Write-Output "The folder $physical_path already exists"
}
else {
    New-Item -ItemType Directory -Path $physical_path -Force
    Write-Output "Created folder $physical_path"
}

# Create New WebApplication
New-WebApplication "$app_name" -Site "$website_name" -ApplicationPool "$app_pool_name"  -PhysicalPath "$physical_path" -Force;

Write-Output "Deploy WebApp sucessfully"
