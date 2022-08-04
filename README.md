# Deploy Web Application in IIS
This action will be deployed a Web App on IIS Website. It is using the Powershell

### Required
+ The remote IIS server to accept WinRM management calls.
+ Inbound secure WinRm network traffic (TCP port 5986) must be allowed from the GitHub Actions Runners virtual network so that remote sessions can be received.

```
$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName <<ip-address|fqdn-host-name>>

Export-Certificate -Cert $Cert -FilePath C:\temp\<<cert-name>>

Enable-PSRemoting -SkipNetworkProfileCheck -Force

# Check for HTTP listeners
dir wsman:\localhost\listener

# If HTTP Listeners exist, remove them
Get-ChildItem WSMan:\Localhost\listener | Where -Property Keys -eq "Transport=HTTP" | Remove-Item -Recurse

# If HTTPs Listeners don't exist, add one
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint –Force

# This allows old WinRm hosts to use port 443
Set-Item WSMan:\localhost\Service\EnableCompatibilityHttpsListener -Value true

# Make sure an HTTPs inbound rule is allowed
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP

# For security reasons, you might want to disable the firewall rule for HTTP that *Enable-PSRemoting* added:
Disable-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)"
```

### Usage
+ The server(IP/ComputerName), app_name, app_pool_name, physical_path, deploy_user_id, deploy_user_secret are required.
+ The website_name, app_pool_user_service, app_pool_password_service are empty as default.
  deploy_user_id: user for accessing in the remote server
  deploy_user_secret: password for accessing in the remote server

  ```
  - name: Deploy WebAPI with PowerShell
    uses: nhatthai/iis-webapp@v0.1
    with:
      server: '${{ env.IIS_SERVER_COMPUTER_NAME }}'
      app_name: '${{ env.app_name }}'
      app_pool_name: '${{ env.app_pool_name }}'
      physical_path: '${{ env.physical_path }}'
      deploy_user_id: '${{ env.IIS_SERVER_USERNAME }}'
      deploy_user_secret: '${{ env.IIS_SERVER_PASSWORD }}'
      website_name: '${{ env.IIS_WEBSITE_NAME }}'
      app_pool_user_service: '${{ env.app_pool_user_service }}'
      app_pool_password_service: '${{ env.app_pool_password_service }}'
  ```
