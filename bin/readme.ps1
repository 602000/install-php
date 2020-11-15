# 目标：通过 PowerShell 安装多版本Php
#
# # 1.执行脚本
# bin/readme
#
# # 2.执行脚本
# bin/install

Write-Host "用下载工具下载下列两组文件到cache目录，然后执行脚本：bin/install"
Write-Host ""
Write-Host "DownloadUrl"
Write-Host "-----------"
Write-Host "https://windows.php.net/downloads/releases/archives/php-5.6.40-nts-Win32-VC11-x64.zip"
Write-Host "https://windows.php.net/downloads/releases/archives/php-7.0.33-nts-Win32-VC14-x64.zip"
Write-Host "https://windows.php.net/downloads/releases/archives/php-7.1.33-nts-Win32-VC14-x64.zip"
Get-PhpAvailableVersion -State Release | Where-Object {$_.ThreadSafe -eq $False} | Where-Object {$_.Architecture -eq "x64"} | Select-Object DownloadUrl