# Detect power state and adjust refresh rate using QRes

try {
    $ac = (Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus).PowerOnline
    $QResPath = "C:\Program Files\QRes\QRes.exe"
	if ($ac -eq $true) {
        Start-Process -FilePath $QResPath -ArgumentList "/r:120" -WindowStyle Hidden
    } else {
        Start-Process -FilePath $QResPath -ArgumentList "/r:60"  -WindowStyle Hidden
    }
} catch {
   # ignore
}
