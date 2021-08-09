$connection = Get-AutomationConnection -Name AzureRunAsConnection

Connect-AzAccount -ServicePrincipal `
    -Tenant $connection.TenantID `
    -ApplicationId $connection.ApplicationID `
    -CertificateThumbprint $connection.CertificateThumbprint

$Hostpools = Get-AzWvdHostPool

foreach($Hostpool in $Hostpools) {
    $HostpoolRg = $Hostpool.Id.Split("/")[4]
    
    $sessionhosts = Get-AzWvdSessionHost -HostPoolName $Hostpool.Name -ResourceGroupName $HostpoolRg

    foreach($sessionhost in $sessionhosts) {
        $sessionhostName = $sessionhost.Name.Split("/")[1]
        $sessionhostRg = $sessionhost.Name.Split("/")[0]
        
        if($sessionhost.Status -eq "Available" -and $sessionhost.AllowNewSession -eq $true) {
            Write-Output "Processing VM $($sessionhostName)"
            Write-Output "$($sessionhostName): $($sessionhost.Session) User Sessions"
            if($sessionhost.Session -lt 1) {
                Stop-AzVM -Name $sessionhostName -ResourceGroupName $sessionhostRg -Force

                Write-Output "Stopping VM $($sessionhostName)"
            }
        } else {
            Write-Output "VM $($sessionhostName) not available or DrainMode is set to on"
        }
    }
}
