# Path to the JSON configuration file (relative to script's location)
$configPath = (Split-Path $MyInvocation.MyCommand.Path -Parent) + "\programs-config.json"

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

    $installPath = $folderMapping[$InstallLocation]
    Write-Host "Install Path: $installPath"
    Ensure-FolderExists -folderPath $installPath

    $modifiedInstallCommand = "$InstallCommand --install-dir $installPath"

    if ($Action -eq [ActionType]::Install) {
        Write-Host "Installing $ProgramName..."
        try {
            Start-Process -FilePath $modifiedInstallCommand -Wait
            Write-Host "$ProgramName installed successfully."
        } catch {
            Write-Host "Error installing ${ProgramName}: $_"
        }
    } elseif ($Action -eq [ActionType]::Uninstall) {
        Write-Host "Uninstalling $ProgramName..."
        try {
            Start-Process -FilePath $modifiedInstallCommand -Wait
            Write-Host "$ProgramName uninstalled successfully."
        } catch {
            Write-Host "Error uninstalling ${ProgramName}: $_"
        }
    } else {
        Write-Host "No action taken for $ProgramName."
    }
}

foreach ($program in $config.Programs) {
    $programName = $program.Name
    $installCommand = $program.Command
    $installLocation = $program.InstallLocation
    $actionString = $program.Action

# DEBUG: Write-Host "Pre Validate Action Type | Program Name: " $programName "| Install Command: " $installCommand "| Install Location: " $installLocation "| Action String: " $actionString

    # Validate ActionType
    if ([string]::IsNullOrEmpty($actionString) -or -not [enum]::IsDefined([ActionType], $actionString)) {
    Write-Host "Invalid or missing action '$actionString' for program '$programName'. Skipping program."
    continue
}


# DEBUG: Write-Host "Post Validate Action Type | Program Name: " $programName "| Install Command: " $installCommand "| Install Location: " $installLocation "| Action String: " $actionString

    # Initialize $action properly before passing as [ref]
    $action = [ActionType]::NoAction  # Default value to prevent 'null' reference issues | Good Practices 


    # Check the result of TryParse without printing it
    if ([ActionType]::TryParse($actionString, $true, [ref]$action)) {
      Write-Host "Parsed Action: $action"
    } else {
      Write-Host "Invalid Action: $actionString"
    }
    

    # TODO: Skip folder creation if NoAction
    

 
# DEBUG:  Write-Host "Poor value here: " $action

    # Validate InstallLocation
    if (-not $folderMapping.ContainsKey($installLocation)) {
        Write-Host "Invalid install location '$installLocation' for program '$programName'. Skipping program."
        continue
    }

    # Execute program management
    if ($action -ne [ActionType]::NoAction) {
    Manage-Program -ProgramName $programName -InstallCommand $installCommand -Action $action -InstallLocation $installLocation
    } else {
    Write-Host "NoAction Flag: Skipping Management of " $programName
    }
}