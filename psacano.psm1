function Open-AcanoAPI {
<#
.SYNOPSIS

Opens a given node location in the Acano API directly
.DESCRIPTION

Used by the other Cmdlets in the module
.PARAMETER NodeLocation

The location of the API node being accessed. 

#>
    Param (
        [parameter(Mandatory=$true,Position=1)]
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
.PARAMETER IgnoreSSLTrust

If present, connect to the Acano server API even if the certificate running on Webadmin is untrusted.
.EXAMPLE

$cred = Get-Credential
New-AcanoSession -APIAddress acano.contoso.com -Port 445 -Credential $cred

#>
    Param (
        [parameter(Mandatory=$true)]
        [string]$APIAddress,
        [parameter(Mandatory=$false)]
        [string]$Port = $null,
        [parameter(Mandatory=$true)]
        [PSCredential]$Credential,
        [parameter(Mandatory=$false)]
        [switch]$IgnoreSSLTrust
    )

    if ($Port -ne $null){
        $script:APIAddress = "https://"+$APIAddress+":"+$Port+"/"
    } else {
        $script:APIAddress = "https://"+$APIAddress+"/"
    }

    $script:creds = $Credential

    if ($IgnoreSSLTrust) {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    }
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
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CallLegProfileFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/coSpaces"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($CallLegProfileFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&callLegProfileFilter=$CallLegProfileFilter"        } else {            $nodeLocation += "?callLegProfileFilter=$CallLegProfileFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).coSpaces.coSpace}function Get-AcanocoSpace {<#
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
        [string]$coSpaceID    )    return (Open-AcanoAPI "api/v1/coSpaces/$coSpaceID").coSpace}function Get-AcanocoSpaceMembers {<#
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
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CallLegProfileFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )        $nodeLocation = "api/v1/coSpaces/$coSpaceID/coSpaceUsers"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($CallLegProfileFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&callLegProfileFilter=$CallLegProfileFilter"        } else {            $nodeLocation += "?callLegProfileFilter=$CallLegProfileFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).coSpaceUsers.coSpaceUser | fl}function Get-AcanocoSpaceMember {<#
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
        [string]$coSpaceID    )    return (Open-AcanoAPI "api/v1/coSpaces/$coSpaceID/coSpaceUsers/$coSpaceUserID").coSpaceUser}function Get-AcanocoSpaceAccessMethods {<#
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
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CallLegProfileFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )        $nodeLocation = "api/v1/coSpaces/$coSpaceID/accessMethods"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($CallLegProfileFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&callLegProfileFilter=$CallLegProfileFilter"        } else {            $nodeLocation += "?callLegProfileFilter=$CallLegProfileFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).accessMethods.accessMethod | fl}function Get-AcanocoSpaceAccessMethod {<#
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
        [string]$coSpaceID    )    return (Open-AcanoAPI "api/v1/coSpaces/$coSpaceID/accessMethods/$coSpaceAccessMethodID").accessMethod}function Get-AcanoOutboundDialPlanRules {    <#
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
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/outboundDialPlanRules"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).outboundDialPlanRules.outboundDialPlanRule}function Get-AcanoOutboundDialPlanRule {<#
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
        [string]$OutboundDialPlanRuleID    )    return (Open-AcanoAPI "api/v1/outboundDialPlanRules/$OutboundDialPlanRuleID").outboundDialPlanRule}function Get-AcanoInboundDialPlanRules {    <#
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
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/inboundDialPlanRules"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).inboundDialPlanRules.inboundDialPlanRule}function Get-AcanoInboundDialPlanRule {<#
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
        [string]$InboundDialPlanRuleID    )    return (Open-AcanoAPI "api/v1/inboundDialPlanRules/$InboundDialPlanRuleID").inboundDialPlanRule}function Get-AcanoCallForwardingDialPlanRules {    <#
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
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/forwardingDialPlanRules"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).forwardingDialPlanRules.forwardingDialPlanRule}function Get-AcanoOutboundDialPlanRule {<#
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
        [string]$ForwardingDialPlanRuleID    )    return (Open-AcanoAPI "api/v1/forwardingDialPlanRules/$ForwardingDialPlanRuleID").forwardingDialPlanRule}function Get-AcanoCalls {    <#
.SYNOPSIS

Returns current active calls
.DESCRIPTION

Use this Cmdlet to get information on current active calls
.PARAMETER coSpaceFilter <coSpaceID>

Returns current active calls associated with that coSpace
.PARAMETER TenantFilter <tenantID>

Returns current active calls associated with that tenant
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of current active calls beginning
at the current active call in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoCalls

Will return all current active calls
.EXAMPLE
Get-AcanoCalls -coSpaceFilter ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return all current active calls on the given coSpace
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$coSpaceFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/calls"    $modifiers = 0    if ($coSpaceFilter -ne "") {        $nodeLocation += "?coSpacefilter=$coSpaceFilter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).calls.call}function Get-AcanoCall {<#
.SYNOPSIS

Returns information about a given call
.DESCRIPTION

Use this Cmdlet to get information on a call
.PARAMETER CallID

The ID of the call
.EXAMPLE
Get-AcanoCall -CallID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the given call

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallID    )    return (Open-AcanoAPI "api/v1/calls/$CallID").call}function Get-AcanoCallProfiles {    <#
.SYNOPSIS

Returns configured call profiles
.DESCRIPTION

Use this Cmdlet to get information on configured call profiles
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of configured call profiles beginning
at the configured call profile in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoCallProfiles

Will return all configured call profiles
.EXAMPLE
Get-AcanoCalls -Limit 2

Will return 2 configured call profiles
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/callProfiles"    $modifiers = 0    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).callProfiles.callProfile}function Get-AcanoCallProfile {<#
.SYNOPSIS

Returns information about a given call profile
.DESCRIPTION

Use this Cmdlet to get information on a call profile
.PARAMETER CallProfileID

The ID of the call profile
.EXAMPLE
Get-AcanoCallProfile -CallProfileID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the call profile

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallProfileID    )    return (Open-AcanoAPI "api/v1/callProfiles/$CallProfileID").callProfile}function Get-AcanoCallLegs {
<#
.SYNOPSIS

Returns all active call legs on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on all active call legs
.PARAMETER Filter

Returns all active call legs that matches the filter text
.PARAMETER TenantFilter <tenantID>

Returns all active call legs associated with that tenant
.PARAMETER ParticipantFilter <participantID>

Returns all active call legs associated with that participant
.PARAMETER OwnerIdSet true|false

Returns call legs that does/doesn't have an owner ID set
.PARAMETER Alarms All|packetLoss|excessiveJitter|highRoundTripTime

Used to return just those call legs for which the specified alarm names are currently
active. Either “all”, which covers all supported alarm conditions, or one or more 
specific alarm conditions to filter on, separated by the ‘|’ character.  
The supported alarm names are:
    - packetLoss – packet loss is currently affecting this call leg
    - excessiveJitter – there is currently a high level of jitter on one or more of 
                        this call leg’s active media streams
    - highRoundTripTime – the Acano solution measures the round trip time between 
                          itself and the call leg destination; if a media stream is 
                          detected to have a high round trip time (which might impact 
                          call quality), then this alarm condition is set for the call 
                          leg.
.PARAMETER CallID <callID>

Returns all active call legs associated with that call
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of call legs beginning
at the call leg in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoCallLegs

Will return all active call legs
.EXAMPLE
Get-AcanocoSpaces -Filter "Greg"

Will return all active call legs whos URI contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$ParticipantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [ValidateSet("true","false","")]        [string]$OwnerIDSet="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Alarms="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CallID="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    if ($CallID -ne "") {        $nodeLocation = "api/v1/calls/$CallID/callLegs"    } else {        $nodeLocation = "api/v1/callLegs"    }    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($ParticipantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&participantFilter=$ParticipantFilter"        } else {            $nodeLocation += "?participantFilter=$ParticipantFilter"            $modifiers++        }    }    if ($OwnerIdSet -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&ownerIdSet=$OwnerIdSet"        } else {            $nodeLocation += "?ownerIdSet=$OwnerIdSet"            $modifiers++        }    }    if ($Alarms -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&alarms=$Alarms"        } else {            $nodeLocation += "?alarms=$Alarms"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).callLegs.callLeg}function Get-AcanoCallLeg {<#
.SYNOPSIS

Returns information about a given call leg
.DESCRIPTION

Use this Cmdlet to get information on a call leg
.PARAMETER CallLegID

The ID of the call leg
.EXAMPLE
Get-AcanoCallLeg -CallLegID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the call Leg

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallLegID    )    return (Open-AcanoAPI "api/v1/callLegs/$CallLegID").callLeg}function Get-AcanoCallLegProfiles {
<#
.SYNOPSIS

Returns all active call leg profiles on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on all active call leg profiles
.PARAMETER Filter

Returns all active call leg profiles that matches the filter text
.PARAMETER UsageFilter unreferenced|referenced

Returns call leg profiles that are referenced or unreferenced by another object
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of call leg profiles beginning
at the call leg profile in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoCallLegProfiles

Will return all active call legs
.EXAMPLE
Get-AcanocoSpaces -Filter "Greg"

Will return all active call leg profiles whos name contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [ValidateSet("unreferenced","referenced","")]        [string]$UsageFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/callLegProfiles"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($UsageFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&usageFilter=$UsageFilter"        } else {            $nodeLocation += "?usageFilter=$UsageFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).callLegProfiles.callLegProfile}function Get-AcanoCallLegProfile {<#
.SYNOPSIS

Returns information about a given call leg profile
.DESCRIPTION

Use this Cmdlet to get information on a call leg profile
.PARAMETER CallLegProfileID

The ID of the call leg profile
.EXAMPLE
Get-AcanoCallLegProfile -CallLegProfileID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the call leg profile

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallLegProfileID    )    return (Open-AcanoAPI "api/v1/callLegProfiles/$CallLegProfileID").callLegProfile}function Get-AcanoCallLegProfileUsages {<#
.SYNOPSIS

Returns information about where a given call leg profile is used
.DESCRIPTION

Use this Cmdlet to get information on where a given call leg profile is used
.PARAMETER CallLegProfileID

The ID of the call leg profile
.EXAMPLE
Get-AcanoCallLegProfileUsages -CallLegProfileID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on where the given call leg profile is used

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallLegProfileID    )    return (Open-AcanoAPI "api/v1/callLegProfiles/$CallLegProfileID/usage").callLegProfileUsage}function Get-AcanoCallLegProfileTrace {<#
.SYNOPSIS

Returns information about how a call legs call profile has been arrived at.
.DESCRIPTION

Use this Cmdlet to get information about how a call legs call profile has been arrived at. Check the API
documentation chapter 8.4.7 for more info
.PARAMETER CallLegID

The ID of the call leg being looked up
.EXAMPLE
Get-AcanoCallLegProfileTrace -CallLegID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on where the given call leg profile is used

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallLegID    )    return (Open-AcanoAPI "api/v1/callLegs/$CallLegID/callLegProfileTrace").callLegProfileTrace}function Get-AcanoDialTransforms {
<#
.SYNOPSIS

Returns all Dial Transforms on the Acano Server
.DESCRIPTION

Use this Cmdlet to get information on Dial Transforms on the Acano Server
.PARAMETER Filter

Returns Dial Transforms that matches the filter text
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of dial transforms beginning
at the dial transform in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoDialTransforms

Will return all dial transforms
.EXAMPLE
Get-AcanoDialTransforms -Filter "Greg"

Will return all dial transforms whos name contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/dialTransforms"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).dialTransforms.dialTransform}function Get-AcanoDialTransform {<#
.SYNOPSIS

Returns information about a given dial transform rule
.DESCRIPTION

Use this Cmdlet to get information on a dial transform rule
.PARAMETER DialTransformID

The ID of the dial transform rule
.EXAMPLE
Get-AcanoDialTransform -DialTransformID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the dial transform rule

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$DialTransformID    )    return (Open-AcanoAPI "api/v1/dialTransform/$DialTransformID").dialTransform}function Get-AcanoCallBrandingProfiles {
<#
.SYNOPSIS

Returns all active call branding profiles on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on all active call branding profiles
.PARAMETER UsageFilter unreferenced|referenced

Returns call branding profiles that are referenced or unreferenced by another object
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of call branding profiles beginning
at the call branding profile in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoCallBrandingProfiles

Will return all active call legs
.EXAMPLE
Get-AcanocoSpaces -UsageFilter "Unreferenced"

Will return all call branding profiles who is not referenced by another object
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [ValidateSet("unreferenced","referenced","")]        [string]$UsageFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/callBrandingProfiles"    $modifiers = 0    if ($UsageFilter -ne "") {        $nodeLocation += "?usageFilter=$UsageFilter"        $modifiers++    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).callBrandingProfiles.callBrandingProfile}function Get-AcanoCallBrandingProfile {<#
.SYNOPSIS

Returns information about a given call branding profile
.DESCRIPTION

Use this Cmdlet to get information on a call branding profile
.PARAMETER CallBrandingProfileID

The ID of the call branding profile
.EXAMPLE
Get-AcanoCallBrandingProfile -CallBrandingProfileID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the call branding profile

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallBrandingProfileID    )    return (Open-AcanoAPI "api/v1/callBrandingProfiles/$CallBrandingProfileID").callBrandingProfile}function Get-AcanoDtmfProfiles {
<#
.SYNOPSIS

Returns all configured DTMF profiles on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on configured DTMF profiles
.PARAMETER UsageFilter unreferenced|referenced

Returns DTMF profiles that are referenced or unreferenced by another object
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of DTMF profiles beginning
at the DTMF profile in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoDtmfProfiles

Will return all DTMF profiles
.EXAMPLE
Get-AcanoDtmfProfiles -UsageFilter "Unreferenced"

Will return all DTMF profiles who is not referenced by another object
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [ValidateSet("unreferenced","referenced","")]        [string]$UsageFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/dtmfProfiles"    $modifiers = 0    if ($UsageFilter -ne "") {        $nodeLocation += "?usageFilter=$UsageFilter"        $modifiers++    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).dtmfProfiles.dtmfProfile}function Get-AcanoDtmfProfile {<#
.SYNOPSIS

Returns information about a given DTMF profile
.DESCRIPTION

Use this Cmdlet to get information on a DTMF profile
.PARAMETER DtmfProfileID

The ID of the DTMF profile
.EXAMPLE
Get-AcanoDtmfProfile -DtmfProfileID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the DTMF profile

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$DtmfProfileID    )    return (Open-AcanoAPI "api/v1/dtmfProfiles/$DtmfProfileID").dtmfProfile}function Get-AcanoIvrs {
<#
.SYNOPSIS

Returns IVRs currently configured on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on IVRs
.PARAMETER Filter

Returns IVRs that matches the filter text
.PARAMETER TenantFilter <tenantID>

Returns IVRs associated with that tenant
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of IVRs beginning
at the IVR in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoIvrs

Will return all IVRs
.EXAMPLE
Get-AcanoIvrs -Filter "Greg"

Will return all IVRs whos name contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/ivrs"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).ivrs.ivr}function Get-AcanoIvr {<#
.SYNOPSIS

Returns information about a given IVR
.DESCRIPTION

Use this Cmdlet to get information on an IVR
.PARAMETER IvrID

The ID of the IVR
.EXAMPLE
Get-AcanoIvr -IvrID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the IVR

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$IvrID    )    return (Open-AcanoAPI "api/v1/ivrs/$IvrID").ivr}function Get-AcanoIvrBrandingProfiles {
<#
.SYNOPSIS

Returns IVR branding profiles currently configured on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on IVR branding profiles
.PARAMETER Filter

Returns IVR branding profiles that matches the filter text
.PARAMETER TenantFilter <tenantID>

Returns IVR branding profiles associated with that tenant
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of IVR branding profiles beginning
at the IVR branding profile in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoIvrBrandingProfiles

Will return all IVRs
.EXAMPLE
Get-AcanoIvrBrandingProfiles -Filter "Greg"

Will return all IVR branding profiles whos name contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/ivrBrandingProfiles"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).ivrBrandingProfiles.ivrBrandingProfile}function Get-AcanoIvrBrandingProfile {<#
.SYNOPSIS

Returns information about a given IVR Branding Profile
.DESCRIPTION

Use this Cmdlet to get information on an IVR Branding Profile
.PARAMETER IvrBrandingProfileID

The ID of the IVR Branding Profile
.EXAMPLE
Get-AcanoIvrBrandingProfile -IvrID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the IVR Branding Profile

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$IvrBrandingProfileID    )    return (Open-AcanoAPI "api/v1/ivrBrandingProfiles/$IvrBrandingProfileID").ivrBrandingProfile}function Get-AcanoParticipants {
<#
.SYNOPSIS

Returns all active participants on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on all active participants
.PARAMETER Filter

Returns all active participants that matches the filter text
.PARAMETER TenantFilter <tenantID>

Returns all active participants associated with that tenant
.PARAMETER callBridgeFilter

Returns all active participants associated with that CallBridge
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of participants beginning
at the participant in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoParticipants

Will return all active participants
.EXAMPLE
Get-AcanoParticipants -Filter "Greg"

Will return all active participants whos URI contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$callBridgeFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/participants"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($CallBridgeFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&callBridgeFilter=$CallBridgeFilter"        } else {            $nodeLocation += "?callBridgeFilter=$CallBridgeFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).participants.participant}function Get-AcanoParticipant {<#
.SYNOPSIS

Returns information about a given participant
.DESCRIPTION

Use this Cmdlet to get information on a participant
.PARAMETER ParticipantID

The ID of the participant
.EXAMPLE
Get-AcanoParticipant -ParticipantID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the participant

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$ParticipantID    )    return (Open-AcanoAPI "api/v1/participants/$ParticipantID").participant}function Get-AcanoParticipantCallLegs {<#
.SYNOPSIS

Returns the participants active call legs
.DESCRIPTION

Use this Cmdlet to get information on a participants active call legs
.PARAMETER ParticipantID

The ID of the participant
.EXAMPLE
Get-AcanoParticipantCallLegs -ParticipantID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the participants active call legs

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$ParticipantID    )    return (Open-AcanoAPI "api/v1/participants/$ParticipantID/callLegs").callLeg}function Get-AcanoUsers {
<#
.SYNOPSIS

Returns users currently configured on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on users
.PARAMETER Filter

Returns users that matches the filter text
.PARAMETER TenantFilter <tenantID>

Returns users associated with that tenant
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of users beginning
at the user in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoUsers

Will return all users
.EXAMPLE
Get-AcanoUsers -Filter "Greg"

Will return all users whos URI contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/users"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).users.user}function Get-AcanoUser {<#
.SYNOPSIS

Returns information about a given user
.DESCRIPTION

Use this Cmdlet to get information on a user
.PARAMETER UserID

The ID of the user
.EXAMPLE
Get-AcanoUser -UserID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the user

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$UserID    )    return (Open-AcanoAPI "api/v1/users/$UserID").user}function Get-AcanoUsercoSpaces {<#
.SYNOPSIS

Returns a users coSpaces
.DESCRIPTION

Use this Cmdlet to get information on a users coSpaces
.PARAMETER UserID

The ID of the user
.EXAMPLE
Get-AcanoUsercoSpaces -UserID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the users coSpaces

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$UserID    )    return (Open-AcanoAPI "api/v1/users/$UserID/usercoSpaces").userCoSpaces.userCoSpace}function Get-AcanoUserProfiles {
<#
.SYNOPSIS

Returns all configured user profiles on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on configured user profiles
.PARAMETER UsageFilter unreferenced|referenced

Returns user profiles that are referenced or unreferenced by another object
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of user profiles beginning
at the user profile in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoUserProfiles

Will return all user profiles
.EXAMPLE
Get-AcanoUserProfiles -UsageFilter "Unreferenced"

Will return all user profiles who is not referenced by another object
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [ValidateSet("unreferenced","referenced","")]        [string]$UsageFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/userProfiles"    $modifiers = 0    if ($UsageFilter -ne "") {        $nodeLocation += "?usageFilter=$UsageFilter"        $modifiers++    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).userProfiles.userProfile}function Get-AcanoUserProfile {<#
.SYNOPSIS

Returns information about a given user profile
.DESCRIPTION

Use this Cmdlet to get information on a user profile
.PARAMETER UserProfileID

The ID of the user profile
.EXAMPLE
Get-AcanoUserProfile -UserProfileID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the user profile

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$UserProfileID    )    return (Open-AcanoAPI "api/v1/userProfiles/$UserProfileID").userProfile}function Get-AcanoSystemStatus {<#
.SYNOPSIS

Returns information about the system status
.DESCRIPTION

Use this Cmdlet to get information on the system status
.EXAMPLE
Get-AcanoSystemStatus

Will return information on the system status

#>    return (Open-AcanoAPI "api/v1/system/status").status}function Get-AcanoSystemAlarms {<#
.SYNOPSIS

Returns information about the system alarms
.DESCRIPTION

Use this Cmdlet to get information on the system alarms
.EXAMPLE
Get-AcanoSystemAlarms

Will return information on the system alarms

#>    return (Open-AcanoAPI "api/v1/system/alarms").alarms.alarm}function Get-AcanoSystemAlarm {<#
.SYNOPSIS

Returns information about a given system alarm
.DESCRIPTION

Use this Cmdlet to get information on a system alarm
.PARAMETER AlarmID

The ID of the alarm
.EXAMPLE
Get-AcanoSystemAlarm -AlarmID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the alarm

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$AlarmID    )    return (Open-AcanoAPI "api/v1/system/alarms/$AlarmID").alarm}function Get-AcanoSystemDatabaseStatus {<#
.SYNOPSIS

Returns information about the system database status
.DESCRIPTION

Use this Cmdlet to get information on the system database status
.EXAMPLE
Get-AcanoSystemDatabaseStatus

Will return information on the system database status

#>    return (Open-AcanoAPI "api/v1/system/database").database}function Get-AcanoCdrReceiverUri {<#
.SYNOPSIS

Returns information about the configured CDR receiver
.DESCRIPTION

Use this Cmdlet to get information on the configured CDR receiver
.EXAMPLE
Get-AcanoCdrReceiverUri

Will return URI of the configured CDR receiver

#>    return (Open-AcanoAPI "api/v1/system/cdrReceiver").cdrReceiver}function Get-AcanoGlobalProfile {<#
.SYNOPSIS

Returns information about the global profile
.DESCRIPTION

Use this Cmdlet to get information on the global profile
.EXAMPLE
Get-AcanoGlobalProfile

Will return the global profile

#>    return (Open-AcanoAPI "api/v1/system/profiles").profiles}function Get-AcanoTurnServers {
<#
.SYNOPSIS

Returns TURN servers currently configured on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on TURN servers
.PARAMETER Filter

Returns TURN servers that matches the filter text
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of TURN servers beginning
at the TURN server in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-Get-AcanoTurnServers

Will return all TURN servers
.EXAMPLE
Get-AcanoTurnServers -Filter "Greg"

Will return all TURN servers whos URI contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/turnServers"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }        if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).turnServers.turnServer}function Get-AcanoTurnServer {<#
.SYNOPSIS

Returns information about a given TURN server
.DESCRIPTION

Use this Cmdlet to get information on a TURN server
.PARAMETER TurnServerID

The ID of the TURN server
.EXAMPLE
Get-AcanoTurnServer -TurnServerID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the TURN Server

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$TurnServerID    )    return (Open-AcanoAPI "api/v1/turnServers/$TurnServerID").turnServer}function Get-AcanoWebBridges {
<#
.SYNOPSIS

Returns Web bridges currently configured on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on Web bridges
.PARAMETER Filter

Returns Web bridges that matches the filter text
.PARAMETER TenantFilter <tenantID>

Returns Web bridges associated with that tenant
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of Web bridges beginning
at the Web bridge in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoWebBridges

Will return all Web bridges
.EXAMPLE
Get-AcanoWebBridges -Filter "Greg"

Will return all Web bridges whos name contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/webBridges"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).webBridges.webBridge}function Get-AcanoWebBridge {<#
.SYNOPSIS

Returns information about a given web bridge
.DESCRIPTION

Use this Cmdlet to get information on a web bridge
.PARAMETER WebBridgeID

The ID of the web bridge
.EXAMPLE
Get-AcanoWebBridge -WebBridgeID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the web bridge

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$WebBridgeID    )    return (Open-AcanoAPI "api/v1/webBridges/$WebBridgeID").webBridge}function Get-AcanoCallBridges {
<#
.SYNOPSIS

Returns call bridges currently configured on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on call bridges
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of call bridges beginning
at the call bridge in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoCallBridges

Will return all call bridges
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/callBridges"    if ($Limit -ne "") {        $nodeLocation += "?limit=$Limit"                if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).callBridges.callBridge}function Get-AcanoCallBridge {<#
.SYNOPSIS

Returns information about a given call bridge
.DESCRIPTION

Use this Cmdlet to get information on a call bridge
.PARAMETER CallBridgeID

The ID of the call bridge
.EXAMPLE
Get-AcanoCallBridge -CallBridgeID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the call bridge

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallBridgeID    )    return (Open-AcanoAPI "api/v1/callBridges/$CallBridgeID").callBridge}function Get-AcanoXmppServer {<#
.SYNOPSIS

Returns information about the XMPP server
.DESCRIPTION

Use this Cmdlet to get information on the XMPP server
.EXAMPLE
Get-AcanoXmppServer

Will return information on the XMPP server

#>    return (Open-AcanoAPI "api/v1/system/configuration/xmpp").xmpp}function Get-AcanoSystemDiagnostics {
<#
.SYNOPSIS

Returns system diagnostics from the Acano server
.DESCRIPTION

Use this Cmdlet to get system diagnostics from the Acano server
.PARAMETER CoSpaceFilter <coSpaceID>

Returns those diagnostics that correspond to the specified coSpace 
.PARAMETER CallCorrelatorFilter <CallCorrelatorID>

Returns those diagnostics that correspond to the specified callCorrelator 
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of system diagnostics beginning
at the system diagnostic in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoSystemDiagnostics

Will return all system diagnostics
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CoSpaceFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CallCorrelatorFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/system/diagnostics"    $modifiers = 0    if ($CoSpaceFilter -ne "") {        $nodeLocation += "?coSpacefilter=$CoSpaceFilter"        $modifiers++    }    if ($CallCorrelatorFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&callCorrelatorFilter=$CallCorrelatorFilter"        } else {            $nodeLocation += "?callCorrelatorFilter=$CallCorrelatorFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).diagnostics.diagnostic}function Get-AcanoSystemDiagnostic {<#
.SYNOPSIS

Returns information about a given system diagnostic
.DESCRIPTION

Use this Cmdlet to get information on a system diagnostic
.PARAMETER SystemDiagnosticID

The ID of the system diagnostic
.EXAMPLE
Get-AcanoSystemDiagnostic -SystemDiagnosticID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the system diagnostic

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$SystemDiagnosticID    )    return (Open-AcanoAPI "api/v1/system/diagnostics/$SystemDiagnosticID").diagnostic}function Get-AcanoSystemDiagnosticContent {<#
.SYNOPSIS

Returns the content of a given system diagnostic
.DESCRIPTION

Use this Cmdlet to get the content of a system diagnostic
.PARAMETER SystemDiagnosticID

The ID of the system diagnostic
.EXAMPLE
Get-AcanoSystemDiagnosticContent -SystemDiagnosticID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return the content of the system diagnostic

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$SystemDiagnosticID    )    return (Open-AcanoAPI "api/v1/system/diagnostics/$SystemDiagnosticID/contents").diagnostic}function Get-AcanoLdapServers {
<#
.SYNOPSIS

Returns LDAP servers currently configured on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on LDAP servers
.PARAMETER Filter

Returns LDAP servers that matches the filter text
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of LDAP servers beginning
at the LDAP server in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-Get-AcanoLdapServers

Will return all LDAP servers
.EXAMPLE
Get-AcanoLdapServers -Filter "Greg"

Will return all LDAP servers whos URI contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/ldapServers"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }        if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).ldapServers.ldapServer}function Get-AcanoLdapServer {<#
.SYNOPSIS

Returns information about a given LDAP server
.DESCRIPTION

Use this Cmdlet to get information on a LDAP server
.PARAMETER LdapServerID

The ID of the LDAP server
.EXAMPLE
Get-AcanoLdapServer -LdapServerID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the LDAP Server

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$LdapServerID    )    return (Open-AcanoAPI "api/v1/ldapServers/$LdapServerID").ldapServer}function Get-AcanoLdapMappings {
<#
.SYNOPSIS

Returns LDAP mappings currently configured on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on LDAP mappings
.PARAMETER Filter

Returns LDAP mappings that matches the filter text
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of LDAP mappings beginning
at the LDAP mapping in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-Get-AcanoLdapMappings

Will return all LDAP mappings
.EXAMPLE
Get-AcanoLdapMappings -Filter "Greg"

Will return all LDAP mappings whos URI contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/ldapMappings"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }        if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).ldapMappings.ldapMapping}function Get-AcanoLdapMapping {<#
.SYNOPSIS

Returns information about a given LDAP mapping
.DESCRIPTION

Use this Cmdlet to get information on a LDAP mapping
.PARAMETER LdapMappingID

The ID of the LDAP mapping
.EXAMPLE
Get-AcanoLdapMapping -LdapMappingID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the LDAP Mapping

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$LdapMappingID    )    return (Open-AcanoAPI "api/v1/ldapMappings/$LdapMappingID").ldapMapping}function Get-AcanoLdapSources {
<#
.SYNOPSIS

Returns LDAP sources currently configured on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on LDAP sources
.PARAMETER Filter

Returns LDAP sources that matches the filter text
.PARAMETER TenantFilter <tenantID>

Returns LDAP sources associated with that tenant
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of LDAP sources beginning
at the LDAP source in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-Get-AcanoLdapSources

Will return all LDAP mappings
.EXAMPLE
Get-AcanoLdapSources -Filter "Greg"

Will return all LDAP sources whos URI contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/ldapMappings"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }        if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).ldapSources.ldapSource}function Get-AcanoLdapSource {<#
.SYNOPSIS

Returns information about a given LDAP Source
.DESCRIPTION

Use this Cmdlet to get information on a LDAP Source
.PARAMETER LdapSourceID

The ID of the LDAP Source
.EXAMPLE
Get-AcanoLdapSource -LdapSourceID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the LDAP Source

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$LdapSourceID    )    return (Open-AcanoAPI "api/v1/ldapSources/$LdapSourceID").ldapSource}