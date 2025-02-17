# ========================================
# 1. Variable Initialization
# ========================================

# Sets "_dev" folder path on root drive letter of the drive where the script was run from
$DEV_ROOT = (Split-Path $MyInvocation.MyCommand.Path -Qualifier) + "\_dev"
# Alternative default of C drive for root folder placement.  comment the above line and uncomment below for default C location
# $DEV_ROOT = "C:\_dev"



# ========================================
# 2. Action Type Enum Definition
# ========================================
Enum ActionType {
    NoAction = 0
    Install = 1
    Uninstall = -1
}

enum DevFolders {
    DEV_ROOT = (Split-Path $MyInvocation.MyCommand.Path -Qualifier) + "\_dev"
    BUILD_TOOLS = "$DEV_ROOT\build_tools"
    LIBRARIES = "$DEV_ROOT\libraries"
    TOOLS = "$DEV_ROOT\tools"
    AUDIO_LIB = "$DEV_ROOT\libraries\audio"
    EMBEDDED_LIB = "$DEV_ROOT\libraries\embedded"
    GRAPHICS_LIB = "$DEV_ROOT\libraries\graphics"
    NETWORKING_LIB = "$DEV_ROOT\libraries\networking"
}



# ========================================
# 3. Function to Ensure Administrative Privileges
# ========================================
function Ensure-AdminPrivileges {
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "This script requires administrative privileges."
        $currentScript = $MyInvocation.MyCommand.Path
        $arguments = $MyInvocation.Line.Substring($currentScript.Length)
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $currentScript $arguments" -Verb RunAs
        exit
    }
}

# Ensure that script is running with administrative privileges
Ensure-AdminPrivileges

# ========================================
# 4. Function to Ensure Powershell Env Path
# ========================================
function Verify-Powershell_EnvironmentVar {
    $powershell_Path = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
    $NewPath = "C:\Windows\System32\WindowsPowerShell\v1.0\"

    if ($powershell_Path -notlike "*$NewPath*") {
        [System.Environment]::SetEnvironmentVariable(
            "PATH",
            $NewPath + ";" + $powershell_Path.TrimEnd(';'),
            [System.EnvironmentVariableTarget]::Machine
        )
        Write-Host "Path added successfully. Restarting script."
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $PSCommandPath" -RedirectStandardOutput output.log -RedirectStandardError error.log
    } else {
        Write-Host "Path already exists in PATH."
    }
}

Verify-Powershell_EnvironmentVar

# ========================================
# 5. Folder Creation
# ========================================
Write-Host "Creating development folder structure..."

function Ensure-Directory {
    param (
        [string]$DirectoryPath
    )

    if (-not (Test-Path $DirectoryPath)) {
        try {
            New-Item -ItemType Directory -Force -Path $DirectoryPath
        } catch {
            Write-Host "Error creating directory ${DirectoryPath}: $_"
            exit 1
        }
    } else {
        Write-Host "Directory already exists: $DirectoryPath"
    }
}

try {
    Ensure-Directory -DirectoryPath $DEV_ROOT
    Ensure-Directory -DirectoryPath [DevFolders]::BUILD_TOOLS
    Ensure-Directory -DirectoryPath [DevFolders]::TOOLS
    Ensure-Directory -DirectoryPath [DevFolders]::AUDIO_LIBRARIES
    Ensure-Directory -DirectoryPath [DevFolders]::EMBEDDED_LIBRARIES
    Ensure-Directory -DirectoryPath [DevFolders]::GRAPHICS_LIBRARIES
    Ensure-Directory -DirectoryPath [DevFolders]::NETWORKING_LIBRARIES
} catch {
    Write-Host "Error during folder structure creation: $_"
    exit 1
}

# ========================================
# 6. Manage Program Functionality
# ========================================
function Manage-Program {
    param (
        [string]$ProgramName,
        [string]$VcpkgCommand,
        [ActionType]$Action,
        [DevFolders]$InstallLocation
    )

    # Resolve the folder path from the enum
    $ResolvedPath = [string]$InstallLocation

    if ($Action -eq [ActionType]::Install) {
        Write-Host "Installing $ProgramName using vcpkg to $ResolvedPath..."
        try {
            # Ensure the directory exists
            if (-not (Test-Path $ResolvedPath)) {
                New-Item -ItemType Directory -Force -Path $ResolvedPath | Out-Null
                Write-Host "Created directory: $ResolvedPath"
            }

            # Execute the vcpkg install command
            Invoke-Expression $VcpkgCommand
            Write-Host "$ProgramName installed successfully."
        } catch {
            Write-Host "Error installing $ProgramName: $_"
        }
    } elseif ($Action -eq [ActionType]::Uninstall) {
        Write-Host "Uninstalling $ProgramName using vcpkg..."
        try {
            # Execute the vcpkg remove command
            Invoke-Expression "vcpkg remove $ProgramName"
            Write-Host "$ProgramName uninstalled successfully."
        } catch {
            Write-Host "Error uninstalling $ProgramName: $_"
        }
    } else {
        Write-Host "No action taken for $ProgramName."
    }
}

# ========================================
# Manage all specified programs
# ========================================

# Define the programs and their associated vcpkg install commands
$Programs = @(
    @{ Name = "vcpkg"; Command = "git clone https://github.com/microsoft/vcpkg && .\vcpkg\bootstrap-vcpkg.bat"; Action = [ActionType]::Install; InstallLocation = [DevFolders]::TOOLS },
    @{ Name = "glfw3"; Command = ".\vcpkg\vcpkg install glfw3"; Action = [ActionType]::NoAction; InstallLocation = [DevFolders]::LIBRARIES },
    @{ Name = "glm"; Command = ".\vcpkg\vcpkg install glm"; Action = [ActionType]::NoAction; InstallLocation = [DevFolders]::LIBRARIES },
    @{ Name = "vulkan"; Command = ".\vcpkg\vcpkg install vulkan"; Action = [ActionType]::NoAction; InstallLocation = [DevFolders]::LIBRARIES },
    @{ Name = "portaudio"; Command = ".\vcpkg\vcpkg install portaudio"; Action = [ActionType]::NoAction; InstallLocation = [DevFolders]::LIBRARIES },
    @{ Name = "juce"; Command = ".\vcpkg\vcpkg install juce"; Action = [ActionType]::NoAction; InstallLocation = [DevFolders]::LIBRARIES },
    @{ Name = "curl"; Command = ".\vcpkg\vcpkg install curl"; Action = [ActionType]::NoAction; InstallLocation = [DevFolders]::LIBRARIES },
    @{ Name = "nlohmann-json"; Command = ".\vcpkg\vcpkg install nlohmann-json"; Action = [ActionType]::NoAction; InstallLocation = [DevFolders]::LIBRARIES },
    @{ Name = "esp32-idf"; Command = ".\vcpkg\vcpkg install esp32-idf"; Action = [ActionType]::NoAction; InstallLocation = [DevFolders]::LIBRARIES },
    @{ Name = "freertos"; Command = ".\vcpkg\vcpkg install freertos"; Action = [ActionType]::NoAction; InstallLocation = [DevFolders]::LIBRARIES },
    @{ Name = "python3"; Command = ".\vcpkg\vcpkg install python3"; Action = [ActionType]::NoAction; InstallLocation = [DevFolders]::TOOLS },
    @{ Name = "git"; Command = "choco install git"; Action = [ActionType]::NoAction; InstallLocation = [DevFolders]::TOOLS }
)

# Iterate over each program and manage its installation/uninstallation
foreach ($Program in $Programs) {
    Manage-Program -ProgramName $Program.Name `
                   -VcpkgCommand $Program.Command `
                   -Action $Program.Action `
                   -InstallLocation $Program.InstallLocation
}



# ========================================
# 7. Example Usage of Manage-Program
# ========================================
# Example: Managing Git installation
Manage-Program -ProgramName "Git" `
               -InstallCommand "winget install --id Git.Git -e --source winget" `
               -UninstallCommand "winget uninstall --id Git.Git -e --source winget" `
               -Action $GitAction

# ========================================
# 8. Installation Report
# ========================================
Write-Host "Installation Report completed."
Read-Host -Prompt "Press Enter to continue"
