# Define base development folder as "dev" inside the script's directory
$DEV_ROOT = (Split-Path $MyInvocation.MyCommand.Path -Qualifier) + "\_dev"

# Purpose-Specific Subfolders
$BUILD_TOOLS = "$DEV_ROOT\build_tools"
$LIBRARIES = "$DEV_ROOT\libraries"
$TOOLS = "$DEV_ROOT\tools"

# Subfolders for Libraries
$AUDIO_LIBRARIES = "$LIBRARIES\audio"
$EMBEDDED_LIBRARIES = "$LIBRARIES\embedded"
$GRAPHICS_LIBRARIES = "$LIBRARIES\graphics"
$NETWORKING_LIBRARIES = "$LIBRARIES\networking"


# Toggle flags for each individual installation (set to $true to install, $false to skip)
# Build Tools
$InstallVcpkg = $false  # Toggle vcpkg installation

# Graphics Libraries
$InstallGlfw = $false    # Toggle GLFW graphics library
$InstallGlm = $false     # Toggle GLM graphics library
$InstallVulkan = $false  # Toggle Vulkan graphics library

# Audio Libraries
$InstallPortAudio = $false    # Toggle PortAudio library
$InstallJUCE = $false         # Toggle JUCE library

# Financial Libraries
$InstallcURL = $false         # Toggle cURL library
$Installnlohmann_json = $false # Toggle nlohmann-json library

# Embedded Libraries
$InstallEsp32Idf = $false    # Toggle ESP32 IDF library
$InstallFreeRTOS = $false    # Toggle FreeRTOS library

# General Tools
$InstallPython = $false  # Toggle Python installation
$InstallGit = $false     # Toggle Git installation

# Function to Install Libraries
function Install-Library {
    param (
        [string]$LibraryName,
        [string]$LibraryPath,
        [string]$Command
    )
    Write-Host "Installing $LibraryName..."
    try {
        & "$BUILD_TOOLS\vcpkg\vcpkg" install $Command --overlay-triplets="$LibraryPath"
    } catch {
        Write-Host "Error installing ${LibraryName}: $_"
    }
}

# Create folder structure
Write-Host "Creating development folder structure..."
try {
    New-Item -ItemType Directory -Force -Path $DEV_ROOT
    New-Item -ItemType Directory -Force -Path $BUILD_TOOLS
    New-Item -ItemType Directory -Force -Path $TOOLS
    New-Item -ItemType Directory -Force -Path $AUDIO_LIBRARIES
    New-Item -ItemType Directory -Force -Path $EMBEDDED_LIBRARIES
    New-Item -ItemType Directory -Force -Path $GRAPHICS_LIBRARIES
    New-Item -ItemType Directory -Force -Path $NETWORKING_LIBRARIES
    
} catch {
    Write-Host "Error creating folder structure: $_"
    exit 1
}

# Install Build Tools
if ($InstallVcpkg) {
    Write-Host "Installing vcpkg..."
    try {
        if (!(Test-Path "$BUILD_TOOLS\vcpkg")) {
            git clone https://github.com/microsoft/vcpkg.git "$BUILD_TOOLS\vcpkg"
            & "$BUILD_TOOLS\vcpkg\bootstrap-vcpkg.bat"
        }
        # Add vcpkg to PATH for easier access
        [System.Environment]::SetEnvironmentVariable("PATH", "$BUILD_TOOLS\vcpkg;" + [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine), [System.EnvironmentVariableTarget]::Machine)
    } catch {
        Write-Host "Error installing vcpkg: $_"
    }
}

# Install Graphics Libraries
if ($InstallGlfw) { Install-Library -LibraryName "GLFW" -LibraryPath $GRAPHICS_LIBRARIES -Command "glfw3" }
if ($InstallGlm) { Install-Library -LibraryName "GLM" -LibraryPath $GRAPHICS_LIBRARIES -Command "glm" }
if ($InstallVulkan) { Install-Library -LibraryName "Vulkan" -LibraryPath $GRAPHICS_LIBRARIES -Command "vulkan" }

# Install Audio Libraries
if ($InstallPortAudio) { Install-Library -LibraryName "PortAudio" -LibraryPath $AUDIO_LIBRARIES -Command "portaudio" }
if ($InstallJUCE) { Install-Library -LibraryName "JUCE" -LibraryPath $AUDIO_LIBRARIES -Command "juce" }

# Install Financial Libraries
if ($InstallcURL) { Install-Library -LibraryName "cURL" -LibraryPath $NETWORKING_LIBRARIES -Command "curl" }
if ($Installnlohmann_json) { Install-Library -LibraryName "nlohmann-json" -LibraryPath $NETWORKING_LIBRARIES -Command "nlohmann-json" }

# Install Embedded Libraries
if ($InstallEsp32Idf) { Install-Library -LibraryName "ESP32 IDF" -LibraryPath $EMBEDDED_LIBRARIES -Command "esp32-idf" }
if ($InstallFreeRTOS) { Install-Library -LibraryName "FreeRTOS" -LibraryPath $EMBEDDED_LIBRARIES -Command "freertos" }

# Install General Tools
if ($InstallPython) {
    Write-Host "Installing Python..."
    try {
        if (!(Test-Path "$TOOLS\Python")) {
            Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.11.6/python-3.11.6-amd64.exe" -OutFile "$TOOLS\python-installer.exe"
            Start-Process -FilePath "$TOOLS\python-installer.exe" -ArgumentList "/quiet InstallAllUsers=1 TargetDir=$TOOLS\Python" -Wait
            Remove-Item "$TOOLS\python-installer.exe"
        }
    } catch {
        Write-Host "Error installing Python: $_"
    }
}

if ($InstallGit) {
    Write-Host "Installing Git..."
    try {
        if (!(Test-Path "$TOOLS\Git")) {
            Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/latest/download/Git-2.42.0-64-bit.exe" -OutFile "$TOOLS\git-installer.exe"
            Start-Process -FilePath "$TOOLS\git-installer.exe" -ArgumentList "/VERYSILENT /DIR=$TOOLS\Git" -Wait
            Remove-Item "$TOOLS\git-installer.exe"
        }
    } catch {
        Write-Host "Error installing Git: $_"
    }
}

Write-Host "Development environment setup complete!"
