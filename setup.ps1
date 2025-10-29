# Requires -RunAsAdministrator
# ============================================================
# Dynamic Refresh - Setup Script
# (version without changing ExecutionPolicy)
# ============================================================

try {
    # 1. Create install folder
    $ProgramFilesPath = ${env:ProgramFiles}
    $installPath = "$ProgramFilesPath\QRes"
    Write-Host "Creating folder at $installPath..."
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    Start-Sleep -Seconds 1

    # 2. Download repo zip
    $tempZip = "$env:TEMP\dynamic-refresh.zip"
    $repoUrl = "https://github.com/xInevitable/dynamic-refresh/archive/refs/heads/main.zip"
    Write-Host "Downloading repository from $repoUrl ..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $repoUrl -OutFile $tempZip -UseBasicParsing -ErrorAction Stop
    if (!(Test-Path $tempZip)) {
        throw "Download failed — check internet connection or repo URL."
    }
    Start-Sleep -Seconds 1

    # 3. Extract repo
    $tempExtract = "$env:TEMP\dynamic-refresh"
    Write-Host "Extracting archive to $tempExtract ..."
    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
    Start-Sleep -Seconds 1

    # 4. Move files to install folder
    $repoMain = Join-Path $tempExtract "dynamic-refresh-main"
    if (-not (Test-Path $repoMain)) {
        throw "Expected folder $repoMain not found. Extraction may have failed."
    }
    Write-Host "Copying files to $installPath ..."
    Copy-Item -Path "$repoMain\*" -Destination $installPath -Recurse -Force
    Start-Sleep -Seconds 1

    # 5. Import Task Scheduler XML
    $taskName = "dynamic-refresh"
    $taskXml = Join-Path $installPath "taskschd.xml"
    if (-not (Test-Path $taskXml)) {
        throw "Task XML not found at $taskXml. Aborting."
    }
    Write-Host "Registering scheduled task '$taskName' ..."
    Start-Sleep -Seconds 1

    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Write-Host "Existing task found. Removing old task ..."
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    }

    $xmlText = Get-Content -Path $taskXml -Raw
    $TaskUser = "$env:UserDomain\$env:UserName"
    $xmlText = $xmlText -replace '\{\{ProgramFilesPath\}\}', $ProgramFilesPath
    Register-ScheduledTask -Xml $xmlText -TaskName $taskName -User $TaskUser -Force
    Start-Sleep -Seconds 1

    # 6. Clean up temp files
    Write-Host "Cleaning up temporary files..."
    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    $InstalledScript = Join-Path $installPath "setup.ps1"
    if (Test-Path $InstalledScript) {
        Remove-Item $InstalledScript -Force
    }
    Start-Sleep -Seconds 1

    Write-Host "------------------------------------------------------------------"
    Write-Host ""
    Write-Host "Setup complete!"
    Write-Host "Files installed at: $installPath"
    Write-Host "Scheduled task: '$taskName'"
    Write-Host "Note: This script did NOT change ExecutionPolicy. qres.vbs runs PowerShell with -ExecutionPolicy Bypass."
    Write-Host "Completed at: $(Get-Date -Format 'HH:mm:ss')"
}
catch {
    Write-Host ""
    Write-Host "Installation failed:"
    Write-Host $_.Exception.Message
    exit 1
}
