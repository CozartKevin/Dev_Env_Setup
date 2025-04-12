
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

    # If the action is to install, check if it's already installed
    if ($vcpkgConfig.Action.ToLower() -eq "install") {
        $vcpkgInstallLocation = $folderMapping[$vcpkgConfig.InstallLocation]
        $vcpkgExecutable = Join-Path -Path $vcpkgInstallLocation -ChildPath "vcpkg\vcpkg.exe"

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
    

    }
} else {
    Write-Host "VCPKG is not listed in the config. Adding it for installation."

    # Add VCPKG config to the programs list
    $vcpkgInstallLocation = $folderMapping.Values[0] + "\vcpkg"
    $vcpkgConfig = New-Object PSObject -property @{
        Name = "vcpkg"
        Action = "install"
        InstallCommand = "git clone https://github.com/microsoft/vcpkg.git"
        InstallLocation = $vcpkgInstallLocation
    }

    $config.Programs += $vcpkgConfig

    # Install VCPKG
    Manage-Program -ProgramName "vcpkg" -InstallCommand $vcpkgConfig.InstallCommand -Action ([ActionType]::Install) -InstallLocation $vcpkgInstallLocation
}