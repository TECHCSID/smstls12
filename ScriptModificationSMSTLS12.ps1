###### Config PROD ######
#$SMSWatcherFolder = "E:\FrameWork.CSID\Services\SMSWatcher\"#
##### #####

$SMSWatcherFolder = "E:\FrameWork.CSID\Services\SMSWatcher\"
$SMSWatcherConfigFile = "GenApi.iNot.SmsServiceWindows.exe.config"

$SmsWatcherConfigFullPath = $SMSWatcherFolder + $SMSWatcherConfigFile
if (Test-Path $SmsWatcherConfigFullPath -PathType leaf) {
    [xml]$SMSWatcherConfig = Get-Content($SmsWatcherConfigFullPath)

    $config = $SMSWatcherConfig.configuration

    $runtime = $config.runtime

    if ($null -eq $runtime) {
        $addRuntime = $SMSWatcherConfig.CreateNode("element", "runtime", "")
        $addAppContextSwitchOverrides = $SMSWatcherConfig.CreateNode("element", "AppContextSwitchOverrides", "")
        $addAppContextSwitchOverrides.SetAttribute("value", "Switch.System.Net.DontEnableSystemDefaultTlsVersions=false")
        $addRuntime.AppendChild($addAppContextSwitchOverrides)
        $config.AppendChild($addRuntime)

        Write-Output "SMS Watcher Config file has been changed"

        $SMSWatcherConfig.Save($SmsWatcherConfigFullPath)
    
        $svcName = "GenApi.iNot.SmsServiceWindows.exe"
        $services = Get-WmiObject win32_service | Where-Object { $_.PathName -like "*$svcName*" } 
    
        foreach ($svc in $services) {
        
            Write-Output "---------------------------------------"
            Write-Output "Name=$($svc.Name)"
            Write-Output "DisplayName=$($svc.DisplayName)"
            Write-Output "State=$($svc.State)"
            Write-Output "PathName=$($svc.PathName)"
    
            Stop-Service -Name $svc.Name 
            $tempSvc = Get-Service -Name $svc.Name
            if ($tempSvc.Status -ne "Stopped") {
                Write-Output "Could not stop service $($svc.Name)"
            }
            else {
                Write-Output "Successfully stopped service $($svc.Name)"
            }
    
            Start-Service -Name $svc.Name
            $tempSvc = Get-Service -Name $svc.Name
            if ($tempSvc.Status -eq "Running") {
                Write-Output "Service $($svc.Name) Restarted"
            }
            else {
                Write-Output "Cannot restart $($svc.Name)"
            }
        }
    
        if (($services | Measure-Object).Count -le 0) {
            Write-Output "Couldn't find any inot sms watcher services"
        }
    } else {
        Write-Output "All good : you can go away !"
    }
}
else {
    Write-Output "Couldn't find any sms watcher config file"
}