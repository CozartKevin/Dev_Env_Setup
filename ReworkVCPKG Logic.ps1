#
# We only care about the action if it is in the config.  
#     If it ins't in the config we check if it is installed.
#         not in config --> Installed or not installed
            Not installed -> Install
            installed -> ignore
#
#
#
#
#
#
#  Is it in the config? means we have more options.  6 right? in conf install uninstalled, not in conf install uninstalled
#
# Check if VCPKG is installed
#   If it is:
#      Verify command action isn't install
#                if action is install: Set Action to NoAction
#                if action isn't install: continue with script
#
#   If  VCPKG is not installed:
#      Verify Command action isn't uninstall
#                if action is uninstall: Set action to NOAction
#                if action is install: continue with script
#                if action is clean: Continue with script
#                if action is update: (Figure out how to update VCPKG and implement in normal manage program program loop
#                if action is Validate: (Figure out how to validate VCPKG  and implment in normal manage program loop
#                 if action is NoAction: Continue with script
#
#
#
# Check if VCPKG is listed in the config and handle installation logic only once
$vcpkgConfig = $config.Programs | Where-Object { $_.Name -eq "vcpkg" }



if ($vcpkgConfig) {
    Debug-Write "VCPKG is listed in the config."
    
    $vcpkgInstallRoot = $folderMapping[$vcpkgConfig.InstallLocation]
    $vcpkgExecutable = Join-Path -Path $vcpkgInstallRoot -ChildPath "vcpkg\vcpkg.exe"

    # If the action is to install, check if it's already installed
    if ($vcpkgConfig.Action.ToLower() -eq "install") {
        
        if (-not (Test-Path $vcpkgExecutable)) {
            Write-Host "VCPKG is not installed. Installing..."
            Manage-Program -ProgramName "vcpkg" -InstallCommand $vcpkgConfig.InstallCommand -Action ([ActionType]::Install) -InstallLocation $vcpkgInstallLocation
        } else {
             Write-Host "VCPKG is already installed at $vcpkgExecutable. Skipping VCPKG installation."
            # Change the action for vcpkg to NoAction in the global config
            $config.Programs | Where-Object { $_.Name -eq "vcpkg" } | ForEach-Object { $_.Action = "noaction" }
       # Save the updated config back to the file
            try {
                $config | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Force
                Write-Host "Configuration updated and saved successfully."
            } catch {
                Write-Host "Error saving configuration file: $_"
            }
        }
    } elseif ($vcpkgConfig.Action.ToLower() -eq "uninstall"){
            
         if (-not (Test-Path $vcpkgExecutable)) {
          Write-Host "VCPKG isn't installed and is set to be uninstalled.  Setting to install as VCPKG is required for other program installs."
          # Change the action for vcpkg to install in the global config
          $config.Programs | Where-Object { $_.Name -eq "vcpkg" } | ForEach-Object { $_.Action = "install" }
         }

    }
} else {
    Write-Host "VCPKG is not listed in the config. Adding it for installation."

    # Add VCPKG config to the programs list
    $vcpkgInstallRoot = $folderMapping.Values[0] + "\vcpkg" #Default location of first folderMapping folder for VCPKG install
    $vcpkgExecutable = Join-Path -Path $vcpkgInstallRoot -ChildPath "vcpkg\vcpkg.exe"
    

    if (-not (Test-Path $vcpkgExecutable)) {
    Write-Host "VCPKG is not installed and not in the config.  Adding to the config"
    $vcpkgConfig = New-Object PSObject -property @{
        Name = "vcpkg"
        Action = "install"
        InstallCommand = "git clone https://github.com/microsoft/vcpkg; .\\vcpkg\\bootstrap-vcpkg.bat"
        InstallLocation = $vcpkgInstallLocation
    }

    $config.Programs += $vcpkgConfig

    # Install VCPKG  Install not needed here as added to the config before foreeach loop that manages program installs
    # Manage-Program -ProgramName "vcpkg" -InstallCommand $vcpkgConfig.InstallCommand -Action ([ActionType]::Install) -InstallLocation $vcpkgInstallLocation
     
     } else { 

     #If installed and not in the config then ignore and continue on.

     }     

}