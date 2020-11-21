# 目标：通过 PowerShell 安装多版本Php
#
# # 1.执行脚本
# bin/readme
#
# # 2.执行脚本
# bin/install

Trap {
    Write-Host "Error in $Version" -Fore Red
}

$Version = "N/A"

$Scope = "CurrentUser"

# $Scope2 = "User"

$Versions = @("5.6", "7.0", "7.1", "7.2", "7.3", "7.4")

$Extensions = @("bz2", "curl", "fileinfo", "gd", "gettext", "gmp", "intl", "imap", "ldap", "mbstring", "exif", "mysqli", "odbc", "openssl", "pdo_mysql", "pdo_odbc", "pdo_pgsql", "pdo_sqlite", "pgsql", "shmop", "soap", "sockets", "sodium", "sqlite3", "tidy", "xmlrpc", "xsl")

$CurrentPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ParentPath = Split-Path -Parent $CurrentPath
$PhpPath = Join-Path $ParentPath "php"
$CachePath = Join-Path $ParentPath "cache"

If ($args.count -Eq 0) {
    $myArgs = $Versions
} Else {
    $myArgs = $args
}

Foreach ($Version In $myArgs) {
    If ($Version -Eq $myArgs[0]) {
        If (-Not (Get-Module -Name PhpManager)) {
            Write-Host "Install Php Manager"
            Install-Module -Name PhpManager -Scope $Scope -Force
        }
        
        If ((Get-ExecutionPolicy) -ne "RemoteSigned") {
            Write-Host "Set Execution Policy"
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope $Scope -Force
        }
        
        If (Get-Php) {
            Write-Host "Uninstall Php"
            Uninstall-Php -ConfirmAuto
        }
        
        Write-Host "Set Php Download Cache"
        Set-PhpDownloadCache -Path $CachePath -Persist $Scope
        
        Write-Host "Initialize Php Switcher"
        Initialize-PhpSwitcher -Alias $PhpPath -Scope $Scope -Force
    }
    
    If ($Version -Eq $myArgs[-1]) {
        $IsLast = $True
    } Else {
        $IsLast = $False 
    }

    If ($Version -Eq 7) {
        $Version = "7.0"
    }

    If ($Version -NotIn $Versions) {
        Continue
    }

    $Path = $PhpPath + $Version

    Write-Host "Install Php $Version"
    Install-Php -Version $Version -Architecture x64 -ThreadSafe $False -Path $Path -TimeZone Asia/Shanghai -InitialPhpIni Development -Force

    If ($Version -ge "7.0") {
        Write-Host "Enable opcache"
        Enable-PhpExtension -Extension opcache -Path $Path
    }

    If ($Version -ge "7.0") {
        Write-Host "Install xdebug"
        Install-PhpExtension -Extension xdebug -Path $Path
    }

    # If ($Version -ge "7.0") {
    #     Write-Host "Install imagick"
    #     Install-PhpExtension -Extension imagick -Path $Path
    # }

    Foreach ($Extension In $Extensions) {
        If ($Version -le "7.1" -and $Extension -eq "sodium") {
            Continue
        }

        If ($Version -le "5.6" -and $Extension -In $Extensions) {
            Continue
        }

        Write-Host "Enable $Extension"
        Enable-PhpExtension -Extension $Extension -Path $Path
    }

    If ($Version -ge "7.0") {
        #     Write-Host "Install Composer"
        #     Install-Composer -Path $Path -PhpPath $Path -Scope $Scope2 -NoAddToPath
        Write-Host "Install composer"
        $ComposerPhar = Join-Path $Path "composer.phar"
        Invoke-WebRequest -Uri "https://mirrors.aliyun.com/composer/composer.phar" -OutFile $ComposerPhar
        $ComposerBat = Join-Path $Path "composer.bat"
        $PhpExe = Join-Path $PhpPath "php.exe"
        Write-Output "@echo off" > $ComposerBat
        Write-Output "setlocal disabledelayedexpansion" >> $ComposerBat
        Write-Output "" >> $ComposerBat
        Write-Output "`"$PhpExe`" `"%~dpn0.phar`" %*" >> $ComposerBat
    }

    If ($Version -ge "5.6") {
        Write-Host "Update CA"
        Update-PhpCAInfo -Path $Path
    }

    Write-Host "Add Php Switcher"
    Add-PhpToSwitcher -Name $Version -Path $Path

    If ($IsLast) {
        Write-Host "Switcher PHP $Version"
        Switch-Php $Version

        composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

        Write-Host "------ Done ------"
    } Else {
        Write-Host "------ Next ------"
    }
}