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
        [string]$ParticipantID    )    return (Open-AcanoAPI "api/v1/participants/$ParticipantID").participant}