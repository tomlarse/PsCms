function New-AcanoSSHSession {
    Param (
        [parameter(Mandatory=$true)]
        [string]$ServerAddress,
        [parameter(Mandatory=$false)]
        [string]$Port = $null,
        [parameter(Mandatory=$true)]
        [PSCredential]$Credential
    )

    $script:ServerAddress = $ServerAddress
    $script:ServerPort = $Port
    $script:ServerCredential = $Credential

    Open-AcanoSSHSession

}

function Open-AcanoSSHSession {
    if (($Script:ServerAddress -eq $null) -or ($Script:ServerAddress -eq "")) {
        throw "No server address has been set. Run New-AcanoSSHSession to configure the SSH connection first."
    }
    else {
        $SessionExists = $false
        foreach ($SSHSession in (Get-SSHSession)) {
            if ($SSHSession.Host -eq $Script:ServerAddress){
                $SessionExists = $true
                $SessionId = $SSHSession.SessionId
            }
        }
        
        if ($SessionExists) {
            # Need to remove existing session first
            Remove-SSHSession $SessionId
        }

        $Script:ServerAddress
        $script:ServerPort

        if ($script:ServerPort -ne "")
        {
            $Script:SSHSessionId = (New-SSHSession -ComputerName $Script:ServerAddress -Port $script:ServerPort -Credential $Script:ServerCredential).SessionId        
        }
        else {
            $Script:SSHSessionId = (New-SSHSession -ComputerName $Script:ServerAddress -Credential $Script:ServerCredential).SessionId
        }
    }
}