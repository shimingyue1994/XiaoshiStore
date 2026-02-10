
$logFile = Read-Host "please enter the log file path"
$lines = Get-Content $logFile
$outputFile = "$logFile.json"
New-Item -Path $outputFile -ItemType File -Force | Out-Null
Add-Content -Path $outputFile -Value "[" 
$blocks = @()
$current = @()

foreach ($line in $lines) {
    if ($line -match '^\[\d{4}-\d{2}-\d{2} ') {
        if ($current.Count -gt 0) {
            $blocks += ,@($current)
        }
        $current = @($line)
    } else {
        $current += $line
    }
}
if ($current.Count -gt 0) {
    $blocks += ,@($current)
}

$result = @()

foreach ($block in $blocks) {

    $text = $block -join "`n"

    # time
    if ($text -notmatch '\[(?<time>[\d\-:\. ]+)\]') { continue }
    $time = $Matches.time

    # TOTAL PSS
    $totalPss = $null
    if ($text -match 'TOTAL:\s+(?<pss>\d+)') {
        $totalPss = [int]$Matches.pss
    }
    # CPU 频率（标签后第一个纯数字）
    $cpuFreq = $null
    for ($i = 0; $i -lt $block.Count; $i++) {
        if ($block[$i] -match 'CPUFrequency') {
            for ($j = $i + 1; $j -lt $block.Count; $j++) {
                if ($block[$j] -match '^\d+$') {
                    $cpuFreq = [int]$block[$j]
                    break
                }
            }
        }
    }
    # CPU 温度（标签后所有 4~5 位数字，取最大）
    $cpuTemp = $null
    $temps = @()
    for ($i = 0; $i -lt $block.Count; $i++) {
        if ($block[$i] -match 'CPUTemperature') {
            for ($j = $i + 1; $j -lt $block.Count; $j++) {
                if ($block[$j] -match '^\d{4,5}$') {
                    $temps += [int]$block[$j]
                } elseif ($temps.Count -gt 0) {
                    break
                }
            }
        }
    }
    if ($temps.Count -gt 0) {
        $cpuTemp = [Math]::Round(($temps | Measure-Object -Maximum).Maximum / 1000, 2)
    }

    # CPU overview
    $cpuUser = $cpuSys = $cpuIdle = $cpuIrq = $cpuSirq = $null
    if ($text -match 'User\s+(?<user>\d+)%.*?System\s+(?<sys>\d+)%.*?IRQ\s+(?<irq>\d+)%') {
        $cpuUser = [int]$Matches.user
        $cpuSys  = [int]$Matches.sys
        $cpuIdle = [int]$Matches.idle
        $cpuIrq  = [int]$Matches.irq
        $cpuSirq = [int]$Matches.sirq
    }

    # process cpu
    $procCpu = $null
    if ($text -match '\s(?<cpu>\d+)%\s+[RS]\s+\d+\s+\d+K\s+\d+K\s+ta\s+io\.agora\.entfull') {
        $procCpu = [int]$Matches.cpu
    }

    $newData = [PSCustomObject]@{
        time = $time
        cpu  = @{
            user_percent = $cpuUser
            sys_percent  = $cpuSys
            idle_percent = $cpuIdle
            irq_percent  = $cpuIrq
            sirq_percent = $cpuSirq
            frequency_hz = $cpuFreq
            temperature_celsius = $cpuTemp
        }
        memory = @{
            total_pss_kb = $totalPss
        }
        process = @{
            name = "io.agora.entfull"
            cpu_percent = $procCpu
        }
    }

    $jsonObj = $newData | ConvertTo-Json -Depth 6

    Add-Content -Path $outputFile -Value "$jsonObj," 
}

# $result | ConvertTo-Json -Depth 6
Add-Content -Path $outputFile -Value "]" 