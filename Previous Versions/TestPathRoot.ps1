$scriptPath = $MyInvocation.MyCommand.Path
$driveLetter = Split-Path $scriptPath -Qualifier
$testCombine = (Split-Path $MyInvocation.MyCommand.Path -Qualifier) + "\Dev"

write-host "Script Path" $scriptPath
write-host "Drive letter" $driveLetter
write-host "Test Combine" $testCombine