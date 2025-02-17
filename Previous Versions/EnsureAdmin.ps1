# ========================================
# 1. Variable Initialization
# ========================================

# Default Action for all libraries set to NoAction (do nothing)  
# Modify these to Install, Uninstall or NoAction to inform script on what you would like done
$VcpkgAction = [ActionType]::Install
$GlfwAction = [ActionType]::NoAction
$GlmAction = [ActionType]::NoAction
$VulkanAction = [ActionType]::NoAction
$PortAudioAction = [ActionType]::NoAction
$JUCEAction = [ActionType]::NoAction
$CurlAction = [ActionType]::NoAction
$NlohmannJsonAction = [ActionType]::NoAction
$Esp32IdfAction = [ActionType]::NoAction
$FreeRTOSAction = [ActionType]::NoAction
$PythonAction = [ActionType]::NoAction
$GitAction = [ActionType]::NoAction

# Sets "_dev" folder path on root drive letter of the drive where the script was run from
$DEV_ROOT = (Split-Path $MyInvocation.MyCommand.Path -Qualifier) + "\_dev"
# Alternative default of C drive for root folder placement
# $DEV_ROOT = "C:\_dev"

# Purpose-Specific Subfolders
$BUILD_TOOLS = "$DEV_ROOT\build_tools"
$LIBRARIES = "$DEV_ROOT\libraries"
$TOOLS = "$DEV_ROOT\tools"

# Subfolders for Libraries
$AUDIO_LIBRARIES = "$LIBRARIES\audio"
$EMBEDDED_LIBRARIES = "$LIBRARIES\embedded"
$GRAPHICS_LIBRARIES = "$LIBRARIES\graphics"
$NETWORKING_LIBRARIES = "$LIBRARIES\networking"

# ========================================
# 2. Action Type Enum Definition
# ========================================
Enum ActionType {
    NoAction = 0
    Install = 1
    Uninstall = -1
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
# 3. Function to Ensure Powershell Env Path
# ========================================
function Verify-Powershell_EnvironmentVar {
    $powershell_Path = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
    $NewPath = "C:\Windows\System32\WindowsPowerShell\v1.0\"

# Check if the new path is part of PATH
if ($powershell_Path -notlike "*$NewPath*") {
    [System.Environment]::SetEnvironmentVariable(
        "PATH",
        $NewPath + ";" + $powershell_Path.TrimEnd(';'),
        [System.EnvironmentVariableTarget]::Machine
    )
    Write-Host "Path added successfully. Restarting Script"

    Write-Host "Script Path: $($MyInvocation.MyCommand.Definition)"


   Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $PSCommandPath " -RedirectStandardOutput output.log -RedirectStandardError error.log


} else {
    Write-Host "Path already exists in PATH."
}

}

# Ensure that the system has Powershell set as a %PATH% Environement Var for running certain install bats
Verify-Powershell_EnvironmentVar



# ========================================
# 4. Folder Creation
# ========================================
Write-Host "Creating development folder structure..."

# Helper function to create directories only if they do not exist
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
    # Call the helper function for each folder
    Ensure-Directory -DirectoryPath $DEV_ROOT
    Ensure-Directory -DirectoryPath $BUILD_TOOLS
    Ensure-Directory -DirectoryPath $TOOLS
    Ensure-Directory -DirectoryPath $AUDIO_LIBRARIES
    Ensure-Directory -DirectoryPath $EMBEDDED_LIBRARIES
    Ensure-Directory -DirectoryPath $GRAPHICS_LIBRARIES
    Ensure-Directory -DirectoryPath $NETWORKING_LIBRARIES

    Write-Host ""  # Blank line for spacing before next section
} catch {
    Write-Host "Error during folder structure creation: $_"
    exit 1
}

# ========================================
# 5. Helper Function Definitions
# ========================================
# Function to Install or Uninstall Libraries
function InstallOrUninstall-Library {
    param (
        [string]$LibraryName,
        [string]$LibraryPath,
        [string]$Command,
        [ActionType]$Action
    )

    if ($Action -eq [ActionType]::Install) {
        Write-Host "Installing $LibraryName..."
        try {
            & "$BUILD_TOOLS\vcpkg\vcpkg" install $Command --overlay-triplets="$LibraryPath"
            $installedItems += "$LibraryName installed"
        } catch {
            Write-Host "Error installing ${LibraryName}: $_"
        }
    }
    elseif ($Action -eq [ActionType]::Uninstall) {
        Write-Host "Uninstalling $LibraryName..."
        try {
            & "$BUILD_TOOLS\vcpkg\vcpkg" remove $Command --overlay-triplets="$LibraryPath"
            $installedItems += "$LibraryName uninstalled"
        } catch {
            Write-Host "Error uninstalling ${LibraryName}: $_"
        }
    }
    else {
        Write-Host "No action taken for $LibraryName."
    }
}

# ========================================
# 6. Installation/Uninstallation Logic
# ========================================
# Initialize the installed items list
$installedItems = @()

# Install or Uninstall Build Tools (e.g., vcpkg)
if ($VcpkgAction -eq [ActionType]::Install) {
    Write-Host "Installing vcpkg..."
    try {
        if (!(Test-Path "$BUILD_TOOLS\vcpkg")) {
            git clone https://github.com/microsoft/vcpkg.git "$BUILD_TOOLS\vcpkg"
            & "$BUILD_TOOLS\vcpkg\bootstrap-vcpkg.bat"

        }
        
        $VCPKG_Path = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)

      if( $VCPKG_Path -notlike "*$BUILD_TOOLS\vcpkg*") {
        # Add vcpkg to PATH for easier access
        [System.Environment]::SetEnvironmentVariable("PATH", "$BUILD_TOOLS\vcpkg;" + [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine), [System.EnvironmentVariableTarget]::Machine)
       }

        $installedItems += "vcpkg installed"
    } catch {
        Write-Host "Error installing vcpkg: $_"
        throw "vcpkg installation failed. Halting execution."
    }
}

# Continue with the rest of the install/uninstall logic...

# ========================================
# 7. Installation Report
# ========================================
Write-Host "Installation Report:"
if ($installedItems.Count -eq 0) {
    Write-Host "No libraries or tools were installed."
}

Read-Host -Prompt "Press Enter to continue"
