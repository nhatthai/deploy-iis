# Deploy Web Application in IIS
This action will be deploy the Web App on IIS Website. It is using the Powershell

### Usage
+ The app_name, app_pool_name, physical_path are required.
+ The website_name, user_service, password_service default are empty.

```
- name: Deploy WebAPI with PowerShell
      uses: nhatthai/deploy=webapp-iis@0.0.3
      with:
        app_name: '${{ env.app_name }}'
        app_pool_name: '${{ env.app_pool_name }}'
        physical_path: '${{ env.physical_path }}'
        website_name: ''
        user_service: ''
        password_service: ''
```
