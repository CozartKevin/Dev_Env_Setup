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

# ========================================
# 1. Variable Initialization
# ========================================
$DEV_ROOT = (Split-Path $MyInvocation.MyCommand.Path -Qualifier) + "\_dev"

# Initialize folder mappings dynamically from the configuration
$folderMapping = @{}
foreach ($mapping in $config.FolderMappings) {
    $folderMapping[$mapping.Key] = Join-Path -Path $DEV_ROOT -ChildPath $mapping.Path
    
}

# ActionType enum (Install, Uninstall, NoAction)
enum ActionType {
    Install
    Uninstall
    NoAction
    CleanUp
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

    if (-not $folderMapping.ContainsKey($InstallLocation)) {
        Write-Host "Invalid install location '$InstallLocation' for program '$ProgramName'. Skipping."
        return
    }

    $installPath = $folderMapping[$InstallLocation]
    Write-Host "Install Path: $installPath"
    Ensure-FolderExists -folderPath $installPath

    if ($Action -eq [ActionType]::Install) {
        Write-Host "Installing $ProgramName..."
        try {
            $commands = $InstallCommand -split ';'

            foreach ($cmd in $commands) {
                $trimmedCmd = $cmd.Trim()
                Write-Host "Trimmed Command: " $trimmedCmd
                if ($trimmedCmd -ne "") {
                    # If command contains placeholder, replace with actual path
                    $finalCmd = $trimmedCmd.Replace('\$InstallPath', "`"$installPath`"")
                    try {
                        Write-Host "Running: $finalCmd"
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

    } elseif ($Action -eq [ActionType]::Uninstall) {
        Write-Host "Uninstalling $ProgramName..."
        try {
            # Check if the program exists before attempting to uninstall
            $programPath = Join-Path -Path $installPath -ChildPath $ProgramName
            if (Test-Path $programPath) {
                if ($ProgramName -eq "vcpkg") {
                    # Handle vcpkg uninstallation separately
                    Write-Host "Removing vcpkg folder and related files..."
                    Remove-Item -Path "$installPath\$ProgramName" -Recurse -Force
                    Write-Host "$ProgramName uninstalled successfully."
                } else {
                    # Default uninstallation process using vcpkg uninstall command
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

    } elseif ($Action -eq [ActionType]::CleanUp) {
        Write-Host "Cleaning up all installed programs..."

        # Cleanup vcpkg and its packages
        if (Test-Path "$installPath\\vcpkg") {
            Remove-Item -Path "$installPath\\vcpkg" -Recurse -Force
            Write-Host "vcpkg and its packages removed successfully."
        }

        # Additional cleanup logic for other installed programs can be added here

    } else {
if ($action -eq [ActionType]::NoAction) {
    Write-Host "No action taken for $programName. Skipping program management."
}

        Write-Host "No action taken for $ProgramName."
    }
}


# Dictionary to map lowercase action strings to ActionType enum values
$actionMap = @{
    "install"    = [ActionType]::Install
    "uninstall"  = [ActionType]::Uninstall
    "update"     = [ActionType]::Update
    "clean"      = [ActionType]::Clean
    "validate"   = [ActionType]::Validate
    "noaction"   = [ActionType]::NoAction
}

foreach ($program in $config.Programs) {
    $programName = $program.Name
    $installCommand = $program.Command
    $installLocation = $program.InstallLocation
    $actionString = $program.Action

    # Normalize action string to lowercase
    $normalizedActionString = $actionString.ToLower()

    # DEBUG: Write-Host "Pre Validate Action Type | Program Name: " $programName "| Install Command: " $installCommand "| Install Location: " $installLocation "| Action String: " $normalizedActionString

    # Validate ActionType using the dictionary
    if ($actionMap.ContainsKey($normalizedActionString)) {
        $action = $actionMap[$normalizedActionString]
    } else {
        Write-Host "Invalid or missing action '$normalizedActionString' for program '$programName'. Skipping program."
        continue
    }

    # DEBUG: Write-Host "Post Validate Action Type | Program Name: " $programName "| Install Command: " $installCommand "| Install Location: " $installLocation "| Action String: " $normalizedActionString

    # Validate InstallLocation
    if (-not $folderMapping.ContainsKey($installLocation)) {
        Write-Host "Invalid install location '$installLocation' for program '$programName'. Skipping program."
        continue
    }

    # Execute program management if action is not NoAction
    if ($action -ne [ActionType]::NoAction) {
        Manage-Program -ProgramName $programName -InstallCommand $installCommand -Action $action -InstallLocation $installLocation
    } else {
        Write-Host "NoAction Flag: Skipping Management of:" $programName
    }
}
