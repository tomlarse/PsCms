function Acano-GET {
    Param (
        [parameter(Mandatory=$true)]
        [string]$NodeLocation
    )

    $webclient = New-Object System.Net.WebClient
    $credCache = new-object System.Net.CredentialCache
    $credCache.Add($script:APIAddress, "Basic", $script:creds)

    $webclient.Headers.Add(“user-agent”, “Windows Powershell WebClient”)
    $webclient.Credentials = $credCache

    [xml]$doc = $webclient.DownloadString($script:APIAddress+$NodeLocation)

    return $doc
}

function New-AcanoSession {
    Param (
        [parameter(Mandatory=$true)]
        [string]$APIAddress,
        [string]$Port = $null,
        [parameter(Mandatory=$true)]
        [PSCredential]$Credential
    )

    if ($Port -ne $null){
        $script:APIAddress = "https://"+$APIAddress+":"+$Port+"/"
    } else {
        $script:APIAddress = "https://"+$APIAddress+"/"
    }

    $script:creds = $Credential
}