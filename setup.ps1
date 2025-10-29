# ============================================================
# Auto Refresh Rate Switcher - Setup Script
# (version without changing ExecutionPolicy)
# ============================================================

# This script:
#  - Creates installation folder
#  - Downloads the repo zip from GitHub
#  - Extracts files and copies them to C:\Program Files\QRes
#  - Registers the scheduled task from included XML
#  - Cleans up temporary files
#
# NOTE: This script does NOT change the system's PowerShell execution policy.
# The qres.vbs uses -ExecutionPolicy Bypass so the scheduled task will still run.
# Run this script as Administrator.

# 1. Create install folder
$ProgramFilesPath = ${env:ProgramFiles}
$installPath = "$ProgramFilesPath\QRes"
Write-Host "Creating folder at $installPath..."
New-Item -ItemType Directory -Path $installPath -Force | Out-Null

# 2. Download repo zip
$tempZip = "$env:TEMP\auto-refreshrate.zip"
$repoUrl = "https://github.com/xInevitable/auto-refreshrate-switcher-on-battery/archive/refs/heads/main.zip"
Write-Host "Downloading repository from $repoUrl ..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $repoUrl -OutFile $tempZip -UseBasicParsing -ErrorAction Stop

# 3. Extract repo
$tempExtract = "$env:TEMP\auto-refreshrate"
Write-Host "Extracting archive to $tempExtract ..."
if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }
Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

# 4. Move files to install folder
$repoMain = Join-Path $tempExtract "auto-refreshrate-switcher-on-battery-main"
if (-not (Test-Path $repoMain)) {
    Write-Error "Expected folder $repoMain not found. Extraction may have failed."
    exit 1
}
Write-Host "Copying files to $installPath ..."
Copy-Item -Path "$repoMain\*" -Destination $installPath -Recurse -Force

# 5. Import Task Scheduler XML
$taskName = "AutoRefreshRate"
$taskXml = Join-Path $installPath "Auto RefreshRate Switch.xml"
if (-not (Test-Path $taskXml)) {
    Write-Error "Task XML not found at $taskXml. Aborting."
    exit 1
}
Write-Host "Registering scheduled task '$taskName' ..."
# If a task with the same name exists, remove it first
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Write-Host "Existing task found. Removing old task ..."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
}
$xmlText = Get-Content -Path $taskXml -Raw
$TaskUser = "$env:UserDomain\$env:UserName"
Register-ScheduledTask -Xml $xmlText -TaskName $taskName -User $TaskUser -Force


# 6. Clean up temp files
Write-Host "Cleaning up temporary files..."
Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
$InstalledScript = "C:\Program Files\QRes\setup.ps1"
if (Test-Path $InstalledScript) {
    Remove-Item $InstalledScript -Force
}
Write-Host ""
Write-Host "✅ Setup complete!"
Write-Host "Files installed at: $installPath"
Write-Host "Scheduled task: '$taskName'"
Write-Host "Note: This script did NOT change ExecutionPolicy. qres.vbs runs PowerShell with -ExecutionPolicy Bypass."
