# 设备IP地址
# $deviceIp = "192.168.1.221"
$deviceIName = Read-Host "请输入设备名称"
$deviceIp = Read-Host "请输入设备IP"
$resolution = Read-Host "请输入分辨率"
$fps = Read-Host "请输入帧数"

# 计数器
$counter = 1
# 每次间隔，单位：秒
$delaySeconds = 60  
# 监控进程
$mPid = 12662

Write-Host "开始采集设备数据，按Ctrl+C停止..."
# HTML模板，美化展示
$htmlStart = "
<!DOCTYPE html>
<html lang=`"en`">
<head>
    <meta charset=`"UTF-8`">
    <meta name=`"viewport`" content=`"width=device-width, initial-scale=1.0`">
    <title>设备日志</title>
    <style>

          .title{
            color:black;
            font-weight: bold;
        }
        .detail{
            color: #333333;
        }
        .time{
            color: blue;
        }
        b{
        color: red;}
    </style>
</head>
<body>
    <div>
"
# 如果网页卡顿可以去掉<script>筛选
$htmlEnd = "
    <script>
        for(var i=0;i<document.getElementsByTagName(`"pre`").length;i++){
                document.getElementsByTagName(`"pre`")[i].innerHTML =  document.getElementsByTagName(`"pre`")[i].innerText
                .replace(`"[%CPU`",`"<b>[%CPU</b>`")
                .replace(`"io.agora.entfull`",`"<b>io.agora.entfull</b>`")
                .replace(`"%cpu`",`"<b>%cpu</b>`")
            }
     
    </script>
    </div>
</body>
</html>
"

$htmlTimeStart = "<pre class=`"time`">"
$htmlTimeEnd = "</pre>"

$htmlTitleStart = "<pre class=`"title`">"
$htmlTitleEnd = "</pre>"

$htmlDetailStart = "<pre id=`"detail`" class=`"detail`">"
$htmlDetailEnd = "</pre>"



try {
    $newFileName = "$deviceIName-$resolution-$fps-$deviceIp-$(Get-Date -Format "yyyyMMddHHmmss").html"
    if (Test-Path $newFileName) {
        Remove-Item $newFileName
    }
    New-Item -Path $newFileName -ItemType File -Force | Out-Null
    $currentDir = Get-Location
    # 输出文件路径
    $outputFile = "$currentDir\$newFileName"
    Write-Host "文件路径 [ $outputFile ]" 

    $mPid = adb -s $deviceIp shell pidof io.agora.entfull
    Add-Content -Path $outputFile -Value "$htmlStart" -Encoding UTF8
    while ($true) {
        Add-Content -Path $outputFile -Value "$htmlTimeStart" -Encoding UTF8
        # 获取当前时间
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        
        # 写入时间戳到文件
        Add-Content -Path $outputFile -Value "`n[$timestamp] 采集#[$counter]" -Encoding UTF8
        Add-Content -Path $outputFile -Value "$htmlTimeEnd" -Encoding UTF8

        # 内存占用率
        Add-Content -Path $outputFile -Value "$htmlTitleStart" -Encoding UTF8
        Add-Content -Path $outputFile -Value "内存占用率" -Encoding UTF8
        Add-Content -Path $outputFile -Value "$htmlTitleEnd" -Encoding UTF8

        Add-Content -Path $outputFile -Value "$htmlDetailStart" -Encoding UTF8
        adb -s $deviceIp shell dumpsys meminfo $mPid | Select-String -Pattern "TOTAL.*:" | Out-File -FilePath $outputFile -Append -Encoding UTF8 -NoNewline
        Add-Content -Path $outputFile -Value "$htmlDetailEnd" -Encoding UTF8

        # 添加空行
        Add-Content -Path $outputFile -Value "`n"

        # CPU温度
        Add-Content -Path $outputFile -Value "$htmlTitleStart" -Encoding UTF8
        Add-Content -Path $outputFile -Value "CPUTemperature" -Encoding UTF8
        Add-Content -Path $outputFile -Value "$htmlTitleEnd" -Encoding UTF8
        Add-Content -Path $outputFile -Value "$htmlDetailStart" -Encoding UTF8
        adb -s $deviceIp shell "cat /sys/class/thermal/thermal_zone*/temp" | Out-File -FilePath $outputFile -Append -Encoding UTF8 
        Add-Content -Path $outputFile -Value "$htmlDetailEnd" -Encoding UTF8
        
        # CPU频率
        Add-Content -Path $outputFile -Value "$htmlTitleStart" -Encoding UTF8
        Add-Content -Path $outputFile -Value "CPUFrequency" -Encoding UTF8
        Add-Content -Path $outputFile -Value "$htmlTitleEnd" -Encoding UTF8
        Add-Content -Path $outputFile -Value "$htmlDetailStart" -Encoding UTF8
        adb -s $deviceIp shell cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq | Out-File -FilePath $outputFile -Append -Encoding UTF8 
        Add-Content -Path $outputFile -Value "$htmlDetailEnd" -Encoding UTF8
        
        # CPU占用率 adb -s $deviceIp shell top -m 10 -d 2 -n 1
        Add-Content -Path $outputFile -Value "$htmlTitleStart" -Encoding UTF8
        Add-Content -Path $outputFile -Value "CPU占用率" -Encoding UTF8
        Add-Content -Path $outputFile -Value "$htmlTitleEnd" -Encoding UTF8
        Add-Content -Path $outputFile -Value "$htmlDetailStart" -Encoding UTF8
        Add-Content -Path $outputFile -Value "概览" -Encoding UTF8
        adb -s $deviceIp shell top -m 10 -n 1 -b | Select-String "(%cpu)|(PID USER)|io.agora.entfull" | Out-File -FilePath $outputFile -Append -Encoding UTF8 
        # Add-Content -Path $outputFile -Value "详情" -Encoding UTF8
        # adb -s $deviceIp shell top -m 10 -n 1 -b | Out-File -FilePath $outputFile -Append -Encoding UTF8 
        Add-Content -Path $outputFile -Value "$htmlDetailEnd" -Encoding UTF8

        # 添加空行
        Add-Content -Path $outputFile -Value "`n`n"

        # 在控制台显示进度
        Write-Host "[$timestamp] 第[$counter]次采集完成" 
        
        $counter++
        
        # 等待指定时间
        Start-Sleep -Seconds $delaySeconds
    }
} catch {
  $errorInfo =  $_.Exception.GetType().FullName+    $_.Exception.Message
    
    Write-Host "`n脚本异常，采集已停止。 $errorInfo"
    # Add-Content -Path $outputFile -Value "$htmlEnd" -Encoding UTF8
} finally {
    Write-Host "`n采集已停止。总共采集了 $($counter-1) 次数据。"
    # Add-Content -Path $outputFile -Value "$htmlEnd" -Encoding UTF8

}
