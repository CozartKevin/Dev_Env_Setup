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
$folderMapping = @{
    "BUILD_TOOLS" = "$DEV_ROOT\build_tools"
    "LIBRARIES" = "$DEV_ROOT\libraries"
    "TOOLS" = "$DEV_ROOT\tools"
    "AUDIO_LIB" = "$DEV_ROOT\libraries\audio"
    "EMBEDDED_LIB" = "$DEV_ROOT\libraries\embedded"
    "GRAPHICS_LIB" = "$DEV_ROOT\libraries\graphics"
    "NETWORKING_LIB" = "$DEV_ROOT\libraries\networking"
}

# ActionType enum (Install, Uninstall, NoAction)
enum ActionType {
    Install
    Uninstall
    NoAction
    CleanUp
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
                    Write-Host "Running: $finalCmd"
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $finalCmd -WorkingDirectory $installPath -Wait -NoNewWindow
                }
            }

            Write-Host "$ProgramName installed successfully."
        } catch {
            Write-Host "Error installing ${ProgramName}: $_"
        }

    } elseif ($Action -eq [ActionType]::Uninstall) {
        Write-Host "Uninstalling $ProgramName..."
        try {
            if ($ProgramName -eq "vcpkg") {
                # Handle vcpkg uninstallation separately
                Write-Host "Removing vcpkg folder and related files..."
                Remove-Item -Path "$installPath" -Recurse -Force
                Write-Host "$ProgramName uninstalled successfully."
            } else {
                # Default uninstallation process using vcpkg uninstall command
                $uninstallCommand = ".\\vcpkg\\vcpkg remove $ProgramName"
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $uninstallCommand -WorkingDirectory $installPath -Wait -NoNewWindow
                Write-Host "$ProgramName uninstalled successfully."
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
        Write-Host "No action taken for $ProgramName."
    }
}

foreach ($program in $config.Programs) {
    $programName = $program.Name
    $installCommand = $program.Command
    $installLocation = $program.InstallLocation
    $actionString = $program.Action

    # Validate ActionType
    if ([string]::IsNullOrEmpty($actionString) -or -not [enum]::IsDefined([ActionType], $actionString)) {
        Write-Host "Invalid or missing action '$actionString' for program '$programName'. Skipping program."
        continue
    }

    # Initialize $action properly
    $action = [ActionType]::NoAction

    # Parse ActionType
    if ([ActionType]::TryParse($actionString, $true, [ref]$action)) {
        Write-Host "Parsed Action: $action"
    } else {
        Write-Host "Invalid Action: $actionString"
    }

    # Validate InstallLocation
    if (-not $folderMapping.ContainsKey($installLocation)) {
        Write-Host "Invalid install location '$installLocation' for program '$programName'. Skipping program."
        continue
    }

    # Execute program management
    if ($action -ne [ActionType]::NoAction) {
        Manage-Program -ProgramName $programName -InstallCommand $installCommand -Action $action -InstallLocation $installLocation
    } else {
        Write-Host "NoAction Flag: Skipping Management of:" $programName
    }
}
