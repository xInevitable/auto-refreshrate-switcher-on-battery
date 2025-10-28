Set objShell = CreateObject("Wscript.Shell")
objShell.Run "powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File ""C:\Program Files\QRes\qres.ps1""", 0, False
