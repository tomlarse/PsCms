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
        if ($sshresult.Contains("No configuration for interface")) {
            break
        }
        else {
            $ifacelist += $iface
        }
    }

    ## If this is an Acano Server, it has admin iface too. 
    $sshresult = (Invoke-SSHCommand -Command "iface admin" -SessionId $Script:SSHSessionid).Output
    if ((-not $sshresult.Contains("No configuration for interface")) -and (-not $sshresult.Contains("Unrecognized interface"))) {
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

        $macadress = ($sshresult | Select-String -Pattern "Mac address" -SimpleMatch).Line
        $autoneg = ($sshresult | Select-String -Pattern "Auto-Negotiation" -SimpleMatch).Line
        
        if ($sshresult | Select-String -Pattern "Speed" -SimpleMatch -Quiet) {
            $speed = ($sshresult | Select-String -Pattern "Speed" -SimpleMatch).Line
            $duplex = ($sshresult | Select-String -Pattern "Duplex" -SimpleMatch).Line
        }
        else {
            ## Speed and duplex null
            $speed = ""
            $duplex = ""
        }
        
        $MTU = ($sshresult | Select-String -Pattern "MTU" -SimpleMatch).Line

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
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$true)]
        [string]$MTU
    )

    $sshresult = (Invoke-SSHCommand -Command "iface $Identity mtu $MTU" -SessionId $Script:SSHSessionId).Output

    Get-AcanoIface $Identity

}

function Get-AcanoIpv4 {
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

    $ipv4output = @()

    foreach ($iface in $ifaces) {
        $sshresult = (Invoke-SSHCommand -Command "ipv4 $iface" -SessionId $script:SSHSessionId).Output
        $ipv4obj = New-Object System.Object

        $ipv4obj | Add-Member -MemberType NoteProperty -Name Identity -Value $iface

        if (-not ($sshresult | Select-String -Pattern "No observed values for interface" -quiet)) {
            $ipaddress = ($sshresult | Select-String -Pattern "address" -SimpleMatch).Line[0]
            $prefixlength = ($sshresult | Select-String -Pattern "prefixlen" -SimpleMatch).Line
            $gateway = ($sshresult | Select-String -Pattern "gateway" -SimpleMatch).Line[0]
            $macadress = ($sshresult | Select-String -Pattern "macaddress" -SimpleMatch).Line
            $default = ($sshresult | Select-String -Pattern "default" -SimpleMatch).Line        
            $dhcp = ($sshresult | Select-String -Pattern "dhcp" -SimpleMatch).Line
            $enabled = ($sshresult | Select-String -Pattern "enabled" -SimpleMatch).Line

            $rawroutes = $sshresult | select -Skip ($sshresult | Select-String -Pattern "source" -SimpleMatch).LineNumber[0]
            $routes = @()
            
            foreach ($rawroute in $rawroutes) {
                $temparray = $rawroute.Split(" ")
                $route = @()
                foreach ($temp in $temparray) {
                    if ($temp -ne "") {
                        $route += $temp
                    }
                }
                $routeobj = New-Object System.Object
                $routeobj | Add-Member -MemberType NoteProperty -Name Source -Value $route[0]
                $routeobj | Add-Member -MemberType NoteProperty -Name Destination -Value $route[1]
                $routeobj | Add-Member -MemberType NoteProperty -Name Gateway -Value $route[2]
                $routeobj | Add-Member -MemberType NoteProperty -Name Global -Value $route[3]
                $routes += $routeobj
            }

            $ipv4obj | Add-Member -MemberType NoteProperty -Name IpAddress -Value $ipaddress.Substring($ipaddress.LastIndexOf(' ')+1)
            $ipv4obj | Add-Member -MemberType NoteProperty -Name Gateway -Value $gateway.Substring($gateway.LastIndexOf(' ')+1)
            $ipv4obj | Add-Member -MemberType NoteProperty -Name PrefixLength -Value $prefixlength.Substring($prefixlength.LastIndexOf(' ')+1)
            $ipv4obj | Add-Member -MemberType NoteProperty -Name Macaddress -Value $macadress.Substring($macadress.LastIndexOf(' ')+1)
            $ipv4obj | Add-Member -MemberType NoteProperty -Name default -Value $default.Substring($default.LastIndexOf(' ')+1)
            $ipv4obj | Add-Member -MemberType NoteProperty -Name dhcp -Value $dhcp.Substring($dhcp.LastIndexOf(' ')+1)
            $ipv4obj | Add-Member -MemberType NoteProperty -Name enabled -Value $enabled.Substring($enabled.LastIndexOf(' ')+1)
            $ipv4obj | Add-Member -MemberType NoteProperty -Name Routes -Value $routes
        }
        else {
            ## Interface has dhcp set and hasn't recieved an address, or isn't connected. This is lazy and should be fixed at some point, nonetheless:
            $ipv4obj | Add-Member -MemberType NoteProperty -Name IpAddress -Value "Ip address not observed"
        }
              
        $ipv4output += $ipv4obj
    }

    return $ipv4output
}

function Set-AcanoIpv4 {
    [CmdletBinding(DefaultParameterSetName="ChangeIPAddress")]
    Param (
        [parameter(ParameterSetName="ChangeIPAddress",Mandatory=$true,Position=1)]
        [parameter(ParameterSetName="ChangeDHCP",Mandatory=$true,Position=1)]
        [parameter(ParameterSetName="EnableDisableIf",Mandatory=$true,Position=1)]
        [parameter(ParameterSetName="DefaultIf",Mandatory=$true,position=1)]
        [string]$Identity,
        [parameter(ParameterSetName="ChangeIPAddress",Mandatory=$true)]
        [string]$IpAddress,
        [parameter(ParameterSetName="ChangeIPAddress",Mandatory=$true)]
        [string]$PrefixLength,
        [parameter(ParameterSetName="ChangeIPAddress",Mandatory=$true)]
        [string]$Gateway,
        [parameter(ParameterSetName="ChangeDHCP",Mandatory=$true)]
        [switch]$EnableDHCP,
        [parameter(ParameterSetName="EnableDisableIf",Mandatory=$true)]
        [ValidateSet("true","false")]
        [string]$Enabled,
        [parameter(ParameterSetName="DefaultIf",Mandatory=$true)]
        [switch]$Default
    )

    If ($PSCmdlet.ParameterSetName -eq 'ChangeIpAddress') {
        Invoke-SSHCommand -Command "ipv4 $Identity add $IpAddress/$PrefixLength $Gateway" -SessionId $Script:SSHSessionId | Out-Null
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'ChangeDHCP') {
        Invoke-SSHCommand -Command "ipv4 $Identity dhcp" -SessionId $Script:SSHSessionId | Out-Null
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'EnableDisableIf') {
        if ($Enabled -eq "true") {
            Invoke-SSHCommand -Command "ipv4 $Identity enable" -SessionId $Script:SSHSessionId | Out-Null
        }
        else {
            Invoke-SSHCommand -Command "ipv4 $Identity disable" -SessionId $Script:SSHSessionId | Out-Null
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'DefaultIf') {
        Invoke-SSHCommand -Command "ipv4 $Identity default" -SessionId $Script:SSHSessionId | Out-Null
    }

    Get-AcanoIpv4 -Identity $Identity
}