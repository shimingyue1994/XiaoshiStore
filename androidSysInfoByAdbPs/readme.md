操作指南：
1. adb connect xxx连接设备
2. 使用‘.\cpuwdouthtml.ps1’命令运行检测脚本开始检测
3. crtl+c结束检测，得到输出文件xxx.html的文件。
4. 运行hardinfofilter.ps1脚本从3中的输出文件中过滤数据，输出json文件(如果失败，就打开网页复制内容到一个txt里，然后再操作)。
5. 使用devicesInfoEcharts.html打开json文件，显示图表信息
