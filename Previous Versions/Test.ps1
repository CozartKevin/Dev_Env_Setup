$path2 = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)

if ($path2 -notlike "*$BUILD_TOOLS\vcpkg*") {
    # Add vcpkg to PATH for easier access
    [System.Environment]::SetEnvironmentVariable("PATH", "$BUILD_TOOLS\vcpkg;" + $path, [System.EnvironmentVariableTarget]::Machine)
    $installedItems += "vcpkg installed"
    write-host "if"
} else {
    $installedItems += "vcpkg already in PATH"
    write-host "Else"
}