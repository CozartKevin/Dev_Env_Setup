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

# No changes below unless modifying script functionality

# ========================================
# 2. Action Type Enum Definition
# ========================================
Enum ActionType {
    NoAction = 0
    Install = 1
    Uninstall = -1
}

# ========================================
# 3. Folder Creation
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
# 4. Helper Function Definitions
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
# 5. Installation/Uninstallation Logic
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
        # Add vcpkg to PATH for easier access
        [System.Environment]::SetEnvironmentVariable("PATH", "$BUILD_TOOLS\vcpkg;" + [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine), [System.EnvironmentVariableTarget]::Machine)
        $installedItems += "vcpkg installed"
    } catch {
        Write-Host "Error installing vcpkg: $_"
        throw "vcpkg installation failed. Halting execution."
    }
}

# Install or Uninstall Libraries (Graphics Libraries)
if ($GlfwAction -eq [ActionType]::Install) { InstallOrUninstall-Library -LibraryName "GLFW" -LibraryPath $GRAPHICS_LIBRARIES -Command "glfw3" -Action $GlfwAction }
if ($GlmAction -eq [ActionType]::Install) { InstallOrUninstall-Library -LibraryName "GLM" -LibraryPath $GRAPHICS_LIBRARIES -Command "glm" -Action $GlmAction }
if ($VulkanAction -eq [ActionType]::Install) { InstallOrUninstall-Library -LibraryName "Vulkan" -LibraryPath $GRAPHICS_LIBRARIES -Command "vulkan" -Action $VulkanAction }

# Install or Uninstall Libraries (Audio Libraries)
if ($PortAudioAction -eq [ActionType]::Install) { InstallOrUninstall-Library -LibraryName "PortAudio" -LibraryPath $AUDIO_LIBRARIES -Command "portaudio" -Action $PortAudioAction }
if ($JUCEAction -eq [ActionType]::Install) { InstallOrUninstall-Library -LibraryName "JUCE" -LibraryPath $AUDIO_LIBRARIES -Command "juce" -Action $JUCEAction }

# Install or Uninstall Libraries (Networking Libraries)
if ($CurlAction -eq [ActionType]::Install) { InstallOrUninstall-Library -LibraryName "cURL" -LibraryPath $NETWORKING_LIBRARIES -Command "curl" -Action $CurlAction }
if ($NlohmannJsonAction -eq [ActionType]::Install) { InstallOrUninstall-Library -LibraryName "nlohmann-json" -LibraryPath $NETWORKING_LIBRARIES -Command "nlohmann-json" -Action $NlohmannJsonAction }

# Install or Uninstall Libraries (Embedded Libraries)
if ($Esp32IdfAction -eq [ActionType]::Install) { InstallOrUninstall-Library -LibraryName "ESP32 IDF" -LibraryPath $EMBEDDED_LIBRARIES -Command "esp32-idf" -Action $Esp32IdfAction }
if ($FreeRTOSAction -eq [ActionType]::Install) { InstallOrUninstall-Library -LibraryName "FreeRTOS" -LibraryPath $EMBEDDED_LIBRARIES -Command "freertos" -Action $FreeRTOSAction }

# Install or Uninstall Tools (General Tools)
if ($PythonAction -eq [ActionType]::Install) {
    Write-Host "Installing Python..."
    try {
        if (!(Test-Path "$TOOLS\Python")) {
            Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.11.6/python-3.11.6-amd64.exe" -OutFile "$TOOLS\python-installer.exe"
            Start-Process -FilePath "$TOOLS\python-installer.exe" -ArgumentList "/quiet InstallAllUsers=1 TargetDir=$TOOLS\Python" -Wait
            Remove-Item "$TOOLS\python-installer.exe"
            $installedItems += "Python installed"
        }
    } catch {
        Write-Host "Error installing Python: $_"
    }
}

if ($GitAction -eq [ActionType]::Install) {
    Write-Host "Installing Git..."
    try {
        if (!(Test-Path "$TOOLS\Git")) {
            Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/latest/download/Git-2.42.0-64-bit.exe" -OutFile "$TOOLS\git-installer.exe"
            Start-Process -FilePath "$TOOLS\git-installer.exe" -ArgumentList "/VERYSILENT /DIR=$TOOLS\Git" -Wait
            Remove-Item "$TOOLS\git-installer.exe"
            $installedItems += "Git installed"
        }
    } catch {
        Write-Host "Error installing Git: $_"
    }
}

# ========================================
# 6. Installation Report
# ========================================
Write-Host "Installation Report:"
if ($installedItems.Count -eq 0) {
    Write-Host "No libraries or tools were installed."
}
