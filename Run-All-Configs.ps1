# Order of config files:
#   (UnInstall-VCPKG.json)                Check VCPKG In Config       VCPKG status Unknown    | Expected Uninstall VCPKG 
#   (No_VCPKG_in_Config.json)             Check VCPKG not in config   VCPKG not installed     | Expected Install VCPKG 
#   (Install-VCPKG.json)                  Check VCOJG In config       VCPKG already installed | Expected change to NoAction 
#   (NoAction-VCPKG+Install-GLFW3.json)   Check VCPKG not in config   VCPKG already installed | Expected Installs other programs 
#                                         Check VCPKG In Config       VCPKG already installed | Expected 




# Define list of config files
$configFiles = @(
    
    #Set to uninstalled as VCPKG status could be unknown prior to testing
    "VCPKG_Installed_Uninstall.json",
   
    # Not Installed VCPKG Section
    "VCPKG_Not_Installed_NoPrograms.json",
    "VCPKG_Not_Installed_NoAction.json",
    "VCPKG_Not_Installed_Uninstall.json",
    "VCPKG_Not_Installed_NA.json",
    #Should Install due to Install Others logic
    "VCPKG_Not_Installed_Install_Others_in_config.json",
    "VCPKG_Not_Installed_No_Config_Install_Programs.json",

    # Installed VCPKG Section
    "VCPKG_Installed_Install.json",
    "VCPKG_Installed_NoAction.json",
    "VCPKG_Installed_NA.json",
    "VCPKG_Installed_Install_with_other_programs_in_config.json",
    "VCPKG_Installed_NoAction_with_other_programs_in_config.json",
    "VCPKG_Installed_Uninstall_with_other_programs_in_config.json"
    
     #Prep for standard install check
    "VCPKG_Uninstalled_Install.json",
    "VCPKG_Installed_Uninstall.json",
    #Leave uninstalled post tests
    "VCPKG_Uninstalled_Install.json"
)

# Define the path to the Configs folder
$configFolderPath = Join-Path $PSScriptRoot "Configs"

# Get all JSON files in the Configs folder
$configFiles = Get-ChildItem -Path $configFolderPath -Filter "*.json"

# Path to your main install script
$scriptPath = Join-Path $PSScriptRoot "ReworkJsonScript.ps1"

# Loop through each config file and run the test script
foreach ($config in $configFiles) {
    Write-Host "`nRunning with config: $($config.Name)" -ForegroundColor Cyan
    & $scriptPath -ConfigName $config.FullName
}