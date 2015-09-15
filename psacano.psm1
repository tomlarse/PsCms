function Acano-GET {
<#
.SYNOPSIS

General connection to the Acano Server
.DESCRIPTION

Used by the other Cmdlets in the module
.PARAMETER NodeLocation

The location of the API node being accessed. 

#>
    Param (
        [parameter(Mandatory=$true)]
        [string]$NodeLocation
    )

    $webclient = New-Object System.Net.WebClient
    $credCache = new-object System.Net.CredentialCache
    $credCache.Add($script:APIAddress, "Basic", $script:creds)

    $webclient.Headers.Add("user-agent", "Windows Powershell WebClient")
    $webclient.Credentials = $credCache

    [xml]$doc = $webclient.DownloadString($script:APIAddress+$NodeLocation)

    return $doc
}

function New-AcanoSession {
<#
.SYNOPSIS

Initializes the connection to the Acano Server
.DESCRIPTION

This Cmdlet should be run when connecting to the server
.PARAMETER APIAddress

The FQDN or IP address of the Acano Server
.PARAMETER Port

The port number the API listens to. Will default to port 443 if this parameter is not included
.PARAMETER Credential

Credentials for connecting to the API
.EXAMPLE

$cred = Get-Credential
New-AcanoSession -APIAddress acano.contoso.com -Port 445 -Credential $cred

#>
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

function Get-AcanocoSpaces {
<#
.SYNOPSIS

Returns coSpaces currently configured on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on coSpaces
.PARAMETER Filter

Returns coSpaces that matches the filter text
.PARAMETER TenantFilter <tenantID>

Returns coSpaces associated with that tenant
.PARAMETER CallLegProfileFilter <callLegProfileID>

Returns coSpaces using just that call leg profile

.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of coSpaces beginning
at the coSpace in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanocoSpaces

Will return all coSpaces
.EXAMPLE
Get-AcanocoSpaces -Filter "Greg"

Will return all coSpaces whos name contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CallLegProfileFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/coSpaces"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($CallLegProfileFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&callLegProfileFilter=$CallLegProfileFilter"        } else {            $nodeLocation += "?callLegProfileFilter=$CallLegProfileFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Acano-GET -NodeLocation $nodeLocation).coSpaces.coSpace}function Get-AcanocoSpace {<#
.SYNOPSIS

Returns information about a given coSpace
.DESCRIPTION

Use this Cmdlet to get information on a coSpace
.PARAMETER coSpaceID

The ID of the coSpace
.EXAMPLE
Get-AcanocoSpaces -coSpaceID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the coSpace
.EXAMPLE
Get-AcanocoSpaces ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the coSpace
#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$coSpaceID    )    return (Acano-GET -NodeLocation "api/v1/coSpaces/$coSpaceID").coSpace}