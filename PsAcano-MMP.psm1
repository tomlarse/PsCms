function New-AcanoMMPSession {
    Param (
        [parameter(Mandatory=$true)]
        [string]$MMPAddress,
        [parameter(Mandatory=$false)]
        [string]$Port = $null,
        [parameter(Mandatory=$true)]
        [PSCredential]$Credential
    )

    $script:MMPAddress = $MMPAddress
    $script:ServerPort = $Port
    $script:ServerCredential = $Credential

    Open-AcanoSSHSession

}

function Open-AcanoSSHSession {
    if (($Script:MMPAddress -eq $null) -or ($Script:MMPAddress -eq "")) {
        throw "No server address has been set. Run New-AcanoSSHSession to configure the SSH connection first."
    }
    else {
        $SessionExists = $false
        foreach ($SSHSession in (Get-SSHSession)) {
            if ($SSHSession.Host -eq $Script:MMPAddress){
                $SessionExists = $true
                $SessionId = $SSHSession.SessionId
            }
        }
        
        if ($SessionExists) {
            # Need to remove existing session first
            Remove-SSHSession $SessionId
        }

        if ($script:ServerPort -ne "")
        {
            $Script:SSHSessionId = (New-SSHSession -ComputerName $Script:MMPAddress -Port $script:ServerPort -Credential $Script:ServerCredential).SessionId        
        }
        else {
            $Script:SSHSessionId = (New-SSHSession -ComputerName $Script:MMPAddress -Credential $Script:ServerCredential).SessionId
        }
    }
}

function Get-AcanoIfaceList {

    $possibleifaces = 'a','b','c','d'
    $ifacelist = @()

    foreach ($iface in $possibleifaces) {
        $sshresult = (Invoke-SSHCommand -Command "iface $iface" -SessionId $Script:SSHSessionid).Output
        if ($sshresult -eq "No configuration for interface") {
            break
        }
        else {
            $ifacelist += $iface
        }
    }

    ## If this is an Acano Server, it has admin iface too. 
    $sshresult = (Invoke-SSHCommand -Command "iface admin" -SessionId $Script:SSHSessionid).Output
    if ($sshresult -ne "No configuration for interface") {
        $ifacelist += 'admin'
    }

    return $ifacelist
}

Function Get-AcanoIface {
    Param (
        [parameter(Mandatory=$false,Position=1)]
        [string]$Identity
    )

    If (($Identity -eq $null) -or ($Identity -eq "")) {
        $ifaces = Get-AcanoIfaceList
    }
    else {
        $ifaces = @($Identity)
    }

    $ifaceoutput = @()

    foreach ($iface in $ifaces) {
        $ifaceobj = New-Object System.Object
        $sshresult = (Invoke-SSHCommand -Command "iface $iface" -SessionId $script:SSHSessionId).Output

        $macadress = ($sshresult | Select-String -Pattern "Mac address").ToString()
        $autoneg = ($sshresult | Select-String "Auto-Negotiation").ToString()
        $speed = ($sshresult | Select-String "Speed").ToString()
        $duplex = ($sshresult | Select-String "Duplex").ToString()
        $MTU = ($sshresult | Select-String "MTU").ToString()

        $ifaceobj | Add-Member -MemberType NoteProperty -Name Identity -Value $iface
        $ifaceobj | Add-Member -MemberType NoteProperty -Name macaddress -Value $macadress.Substring($macadress.Length-17)
        $ifaceobj | Add-Member -MemberType NoteProperty -Name autonegotiate -Value $autoneg.Substring($autoneg.LastIndexOf(' ')+1)
        $ifaceobj | Add-Member -MemberType NoteProperty -Name speed -Value $speed.Substring($speed.LastIndexOf(' ')+1)
        $ifaceobj | Add-Member -MemberType NoteProperty -Name duplex -Value $duplex.Substring($duplex.LastIndexOf(' ')+1)
        $ifaceobj | Add-Member -MemberType NoteProperty -Name MTU -Value $MTU.Substring($MTU.LastIndexOf(' ')+1)
        
        $ifaceoutput += $ifaceobj
    }

    return $ifaceoutput
}

function Set-AcanoIfaceMTU {
[CmdletBinding(DefaultParameterSetName="NoSpeed")]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$true)]
        [string]$MTU
    )

    $sshresult = (Invoke-SSHCommand -Command "iface $Identity mtu $MTU" -SessionId $Script:SSHSessionId).Output

    Get-AcanoIface $Identity

}