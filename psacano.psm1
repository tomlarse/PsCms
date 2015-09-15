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

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$coSpaceID    )    return (Acano-GET -NodeLocation "api/v1/coSpaces/$coSpaceID").coSpace}function Get-AcanocoSpaceMembers {<#
.SYNOPSIS

Returns all members of a given coSpace
.DESCRIPTION

Use this Cmdlet to get all users configured for the queried coSpace
.PARAMETER Filter

Returns users that matches the filter text
.PARAMETER CallLegProfileFilter <callLegProfileID>

Returns member users using just that call leg profile

.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of member users beginning
at the user in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanocoSpaceMembers -coSpaceID 279e740b-df03-4917-9b3f-ff25734d01fd

Will return all members of the provided coSpaceID
.EXAMPLE
Get-AcanocoSpaceMembers -coSpaceID 279e740b-df03-4917-9b3f-ff25734d01fd -Filter "Greg"

Will return all coSpace members whos userJid contains "Greg"
#>[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true,Position=1)]        [parameter(ParameterSetName="NoOffset",Mandatory=$true,Position=1)]        [string]$coSpaceID,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CallLegProfileFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )        $nodeLocation = "api/v1/coSpaces/$coSpaceID/coSpaceUsers"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($CallLegProfileFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&callLegProfileFilter=$CallLegProfileFilter"        } else {            $nodeLocation += "?callLegProfileFilter=$CallLegProfileFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Acano-GET -NodeLocation $nodeLocation).coSpaceUsers.coSpaceUser | fl}function Get-AcanocoSpaceMember {<#
.SYNOPSIS

Returns information about a given coSpace member user
.DESCRIPTION

Use this Cmdlet to get information on a coSpace member user
.PARAMETER coSpaceUserID

The user ID of the user
.PARAMETER coSpaceID

The ID of the coSpace
.EXAMPLE
Get-AcanocoSpaces -coSpaceUserID 61a1229d-3198-43b3-9423-6857d22bdcc9 -coSpaceID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the member user

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$coSpaceUserID,        [parameter(Mandatory=$true)]
        [string]$coSpaceID    )    return (Acano-GET -NodeLocation "api/v1/coSpaces/$coSpaceID/coSpaceUsers/$coSpaceUserID").coSpaceUser}function Get-AcanocoSpaceAccessMethods {<#
.SYNOPSIS

Returns all access methods of a given coSpace
.DESCRIPTION

Use this Cmdlet to get all access methods configured for the queried coSpace
.PARAMETER Filter

Returns access methods that matches the filter text
.PARAMETER CallLegProfileFilter <callLegProfileID>

Returns access methods using just that call leg profile

.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of access methods beginning
at the user in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-Get-AcanocoSpaceAccessMethods -coSpaceID 279e740b-df03-4917-9b3f-ff25734d01fd

Will return all access methods of the provided coSpaceID
.EXAMPLE
Get-Get-AcanocoSpaceAccessMethods -coSpaceID 279e740b-df03-4917-9b3f-ff25734d01fd -Filter "Greg"

Will return all coSpace access methods who matches "Greg"
#>[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true,Position=1)]        [parameter(ParameterSetName="NoOffset",Mandatory=$true,Position=1)]        [string]$coSpaceID,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CallLegProfileFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )        $nodeLocation = "api/v1/coSpaces/$coSpaceID/accessMethods"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($CallLegProfileFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&callLegProfileFilter=$CallLegProfileFilter"        } else {            $nodeLocation += "?callLegProfileFilter=$CallLegProfileFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Acano-GET -NodeLocation $nodeLocation).accessMethods.accessMethod | fl}function Get-AcanocoSpaceAccessMethod {<#
.SYNOPSIS

Returns information about a given coSpace access method
.DESCRIPTION

Use this Cmdlet to get information on a coSpace access method
.PARAMETER coSpaceAccessMethodID

The access method ID of the access method
.PARAMETER coSpaceID

The ID of the coSpace
.EXAMPLE
Get-AcanocoSpaces -coSpaceAccessMethodID 61a1229d-3198-43b3-9423-6857d22bdcc9 -coSpaceID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the access method

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$coSpaceAccessMethodID,        [parameter(Mandatory=$true)]
        [string]$coSpaceID    )    return (Acano-GET -NodeLocation "api/v1/coSpaces/$coSpaceID/accessMethods/$coSpaceAccessMethodID").accessMethod}function Get-AcanoOutboundDialPlanRules {    <#
.SYNOPSIS

Returns outbound dial plan rules
.DESCRIPTION

Use this Cmdlet to get information on the configured outbound dial plan rules
.PARAMETER Filter

Returns outbound dial plan rules that matches the filter text
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of outbound dial plan rules beginning
at the outbound dial plan rule in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoOutboundDialPlanRules

Will return all outbound dial plan rules
.EXAMPLE
Get-AcanoOutboundDialPlanRules -Filter contoso.com

Will return all outbound dial plan rules matching "contoso.com"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/outboundDialPlanRules"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Acano-GET -NodeLocation $nodeLocation).outboundDialPlanRules.outboundDialPlanRule}function Get-AcanoOutboundDialPlanRule {<#
.SYNOPSIS

Returns information about a given outbound dial plan rule
.DESCRIPTION

Use this Cmdlet to get information on a outbound dial plan rule
.PARAMETER OutboundDialPlanRuleID

The ID of the outbound dial plan rule
.EXAMPLE
Get-AcanocoSpaces -OutboundDialPlanRuleID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the outbound dial plan rule

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$OutboundDialPlanRuleID    )    return (Acano-GET -NodeLocation "api/v1/outboundDialPlanRules/$OutboundDialPlanRuleID").outboundDialPlanRule}function Get-AcanoInboundDialPlanRules {    <#
.SYNOPSIS

Returns inbound dial plan rules
.DESCRIPTION

Use this Cmdlet to get information on the configured inbound dial plan rules
.PARAMETER Filter

Returns inbound dial plan rules that matches the filter text
.PARAMETER TenantFilter <tenantID>

Returns coSpaces associated with that tenant
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of inbound dial plan rules beginning
at the inbound dial plan rule in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoInboundDialPlanRules

Will return all inbound dial plan rules
.EXAMPLE
Get-AcanoInboundDialPlanRules -Filter contoso.com

Will return all inbound dial plan rules matching "contoso.com"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/inboundDialPlanRules"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Acano-GET -NodeLocation $nodeLocation).inboundDialPlanRules.inboundDialPlanRule}function Get-AcanoInboundDialPlanRule {<#
.SYNOPSIS

Returns information about a given inbound dial plan rule
.DESCRIPTION

Use this Cmdlet to get information on a inbound dial plan rule
.PARAMETER OutboundDialPlanRuleID

The ID of the inbound dial plan rule
.EXAMPLE
Get-AcanocoSpaces -InboundDialPlanRuleID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the inbound dial plan rule

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$InboundDialPlanRuleID    )    return (Acano-GET -NodeLocation "api/v1/inboundDialPlanRules/$InboundDialPlanRuleID").inboundDialPlanRule}function Get-AcanoCallForwardingDialPlanRules {    <#
.SYNOPSIS

Returns call forwarding dial plan rules
.DESCRIPTION

Use this Cmdlet to get information on the configured call forwarding dial plan rules
.PARAMETER Filter

Returns call forwarding dial plan rules that matches the filter text
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of call forwarding dial plan rules beginning
at the call forwarding dial plan rule in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoCallForwardingDialPlanRules

Will return all call forwarding dial plan rules
.EXAMPLE
Get-AcanoCallForwardingDialPlanRules -Filter contoso.com

Will return all call forwarding dial plan rules matching "contoso.com"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/forwardingDialPlanRules"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Acano-GET -NodeLocation $nodeLocation).forwardingDialPlanRules.forwardingDialPlanRule}function Get-AcanoOutboundDialPlanRule {<#
.SYNOPSIS

Returns information about a given call forwarding dial plan rule
.DESCRIPTION

Use this Cmdlet to get information on a call forwarding dial plan rule
.PARAMETER ForwardingDialPlanRuleID

The ID of the call forwarding dial plan rule
.EXAMPLE
Get-AcanocoSpaces -ForwardingDialPlanRuleID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the call forwarding dial plan rule

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$ForwardingDialPlanRuleID    )    return (Acano-GET -NodeLocation "api/v1/forwardingDialPlanRules/$ForwardingDialPlanRuleID").forwardingDialPlanRule}