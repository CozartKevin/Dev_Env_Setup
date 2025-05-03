$isDebugMode = $true  # Change this to $false to disable debugging output

function Debug-Write {
    param (
        [string]$message
    )

    if ($isDebugMode) {
        Write-Host "DEBUG: $message"
    }
}

# Path to the JSON configuration file (relative to script's location)
$configPath = (Split-Path $MyInvocation.MyCommand.Path -Parent) + "\programs-config_Test.json"

# Validate if JSON file exists
if (-not (Test-Path -Path $configPath)) {
    Write-Host "Configuration file $configPath not found. Exiting..."
    exit
}

# Load the JSON configuration
try {
    $config = Get-Content -Path $configPath | ConvertFrom-Json
} catch {
    Write-Host "Error loading configuration file ${configPath}: $_"
    exit
}

# Validate JSON structure
if (-not $config.Programs -or $config.Programs.GetType().Name -ne 'Object[]') {
    Write-Host "Invalid or missing 'Programs' section in configuration file. Exiting..."
    exit
}

#check for VCPKG installation
$vcpkgConfig = $config.Programs | Where-Object { $_.Name -eq "vcpkg" }

if ($vcpkgConfig) {
    # Check if vcpkgConfig has at least one result, then access its properties
    Debug-Write "vcpkgConfig: Name = $($vcpkgConfig.Name), Action = $($vcpkgConfig.Action)"
} else {
    Debug-Write "vcpkgConfig not found in the config."
}

# ========================================
# 1. Variable Initialization
# ========================================
$DEV_ROOT = (Split-Path $MyInvocation.MyCommand.Path -Qualifier)

# Initialize folder mappings dynamically from the configuration
$folderMapping = @{
    # Define folder mappings here, or load from the config dynamically
}
foreach ($mapping in $config.FolderMappings) {
    $folderMapping[$mapping.Key] = Join-Path -Path $DEV_ROOT -ChildPath $mapping.Path
}


# ActionType enum (Install, Uninstall, NoAction)
enum ActionType {
    Install
    Uninstall
    NoAction
    Clean
    Update
    Validate
}

function Ensure-FolderExists {
    param (
        [string]$folderPath
    )

    if (-not (Test-Path -Path $folderPath)) {
        Write-Host "Directory $folderPath does not exist. Creating..."
        try {
            New-Item -Path $folderPath -ItemType Directory -Force
            Write-Host "Directory $folderPath created successfully."
        } catch {
            Write-Host "Error creating directory ${folderPath}: $_"
        }
    }
}


function Manage-Program {
    param (
        [string]$ProgramName,
        [string]$InstallCommand,
        [ActionType]$Action,
        [string]$InstallLocation
    )

    Debug-Write "Managing Program: $ProgramName with Action: $Action"

    if (-not $folderMapping.ContainsKey($InstallLocation)) {
        Write-Host "Invalid install location '$InstallLocation' for program '$ProgramName'. Skipping."
        return
    }

    $installPath = $folderMapping[$InstallLocation]
    Debug-Write "Install Path: $installPath"
    Ensure-FolderExists -folderPath $installPath

    switch ($Action) {
        [ActionType]::Install {
            Write-Host "Installing $ProgramName..."
            try {
                $commands = $InstallCommand -split ';'
                foreach ($cmd in $commands) {
                    $trimmedCmd = $cmd.Trim()
                    Debug-Write "Trimmed Command: $trimmedCmd"
                    if ($trimmedCmd -ne "") {
                        $finalCmd = $trimmedCmd.Replace('\$InstallPath', "`"$installPath`"")
                        try {
                            Debug-Write "Running command: $finalCmd"
                            Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $finalCmd -WorkingDirectory $installPath -Wait -NoNewWindow
                        } catch {
                            Write-Host "Error executing command: $finalCmd - $_"
                        }
                    }
                }
                Write-Host "$ProgramName installed successfully."
            } catch {
                Write-Host "Error installing ${ProgramName}: $_"
            }
        }
        [ActionType]::Uninstall {
            Write-Host "Uninstalling $ProgramName..."
            try {
                $programPath = Join-Path -Path $installPath -ChildPath $ProgramName
                if (Test-Path $programPath) {
                    if ($ProgramName -eq "vcpkg") {
                        Write-Host "Removing vcpkg folder and related files..."
                        Remove-Item -Path "$installPath\$ProgramName" -Recurse -Force
                        Write-Host "$ProgramName uninstalled successfully."
                    } else {
                        $uninstallCommand = ".\\vcpkg\\vcpkg remove $ProgramName"
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $uninstallCommand -WorkingDirectory $installPath -Wait -NoNewWindow
                        Write-Host "$ProgramName uninstalled successfully."
                    }
                } else {
                    Write-Host "Program '$ProgramName' not found at '$programPath'. Skipping uninstallation."
                }
            } catch {
                Write-Host "Error uninstalling ${ProgramName}: $_"
            }
        }
        [ActionType]::Clean {
            Write-Host "Cleaning up all installed programs..."
            if (Test-Path "$installPath\\vcpkg") {
                Remove-Item -Path "$installPath\\vcpkg" -Recurse -Force
                Write-Host "vcpkg and its packages removed successfully."
            }
        }
        [ActionType]::NoAction {
            Write-Host "No action taken for $ProgramName. Skipping."
        }
        default {
            Write-Host "Invalid action for $ProgramName. Skipping."
        }
    }
}

# Action map (string to ActionType enum)
$actionMap = @{
    "install"    = [ActionType]::Install
    "uninstall"  = [ActionType]::Uninstall
    "update"     = [ActionType]::Update
    "clean"      = [ActionType]::Clean
    "validate"   = [ActionType]::Validate
    "noaction"   = [ActionType]::NoAction
}


# Check if VCPKG is listed in the config
$vcpkgConfig = $config.Programs | Where-Object { $_.Name -eq "vcpkg" }

# Define the first folder path from folderMappings (fallback location if VCPKG is not in the config)
$firstFolderPath = $config.folderMappings.PSObject.Properties.Value[0]

# If VCPKG is listed in the config, check if it needs to be installed
if ($vcpkgConfig) {
    Write-Host "VCPKG is listed in the config."

    # If the action is to install, check if it's already installed
    if ($vcpkgConfig.Action.ToLower() -eq "install") {
        Debug-Write "Action set to Install for VCPKG"
        # Use the install location specified in the config (if present) plus \vcpkg to find the .exe
        $vcpkgInstallLocation = $folderMapping[$vcpkgConfig.InstallLocation]

        $vcpkgExecutable = Join-Path -Path $vcpkgInstallLocation -ChildPath "vcpkg\vcpkg.exe"
        Debug-Write "vcpkgExecutable: $vcpkgExecutable"

        if (-not (Test-Path $vcpkgExecutable)) {
            Write-Host "VCPKG is not installed. Installing..."

            # Proceed with installing VCPKG
            Manage-Program -ProgramName "vcpkg" -InstallCommand $vcpkgConfig.InstallCommand -Action ([ActionType]::Install) -InstallLocation $config.FolderMappings[$vcpkgInstallLocation]
        } else {
            Write-Host "VCPKG is already installed at $vcpkgExecutable. Skipping VCPKG installation."
        }
    }
} else {
    # If VCPKG is not listed in the config, we add it for installation
    Write-Host "VCPKG is not listed in the config. Adding it for installation."

    # Use the first folder path as the default install location
    $vcpkgInstallLocation = "$firstFolderPath\vcpkg"
    $vcpkgConfig = New-Object PSObject -property @{
        Name = "vcpkg"
        Action = "install"
        InstallCommand = "git clone https://github.com/microsoft/vcpkg.git"
        InstallLocation = $vcpkgInstallLocation
    }

    # Add VCPKG config to the programs list
    $config.Programs += $vcpkgConfig

    # Install VCPKG
    Manage-Program -ProgramName "vcpkg" -InstallCommand $vcpkgConfig.InstallCommand -Action ([ActionType]::Install) -InstallLocation $vcpkgInstallLocation
}


foreach ($program in $config.Programs) {
    $programName = $program.Name
    $installCommand = $program.Command
    $installLocation = $program.InstallLocation
    $actionString = $program.Action

    # Normalize action string to lowercase
    $normalizedActionString = $actionString.ToLower()

    if ($actionMap.ContainsKey($normalizedActionString)) {
        $action = $actionMap[$normalizedActionString]
    } else {
        Write-Host "Invalid or missing action '$normalizedActionString' for program '$programName'. Skipping program."
        continue
    }

    if ($action -ne [ActionType]::NoAction) {
        Manage-Program -ProgramName $programName -InstallCommand $installCommand -Action $action -InstallLocation $installLocation
    } else {
        Write-Host "NoAction Flag: Skipping Management of $programName"
    }
}
