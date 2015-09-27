# .ExternalHelp PsAcano.psm1-Help.xml
function Open-AcanoAPI {
    Param (
        [parameter(ParameterSetName="GET",Mandatory=$true,Position=1)]
        [parameter(ParameterSetName="POST",Mandatory=$true,Position=1)]
        [parameter(ParameterSetName="PUT",Mandatory=$true,Position=1)]
        [parameter(ParameterSetName="DELETE",Mandatory=$true,Position=1)]
        [string]$NodeLocation,
        [parameter(ParameterSetName="POST",Mandatory=$true)]        [switch]$POST,
        [parameter(ParameterSetName="PUT",Mandatory=$true)]        [switch]$PUT,
        [parameter(ParameterSetName="DELETE",Mandatory=$true)]        [switch]$DELETE,
        [parameter(ParameterSetName="POST",Mandatory=$true)]
        [parameter(ParameterSetName="PUT",Mandatory=$true)]
        [string]$Data
    )

    $webclient = New-Object System.Net.WebClient
    $credCache = new-object System.Net.CredentialCache
    $credCache.Add($script:APIAddress, "Basic", $script:creds)

    $webclient.Headers.Add("user-agent", "Windows Powershell WebClient")
    $webclient.Credentials = $credCache

    if ($POST) {
        $webclient.Headers.Add("Content-Type","application/x-www-form-urlencoded")
        $webclient.UploadString($script:APIAddress+$NodeLocation,"POST",$Data)

        $res = $webclient.ResponseHeaders.Get("Location")

        return $res.Substring($res.Length-36)
    } elseif ($PUT) {
        $webclient.Headers.Add("Content-Type","application/x-www-form-urlencoded")

        return $webclient.UploadString($script:APIAddress+$NodeLocation,"PUT",$Data)
    } elseif ($DELETE){
        $webclient.Headers.Add("Content-Type","application/x-www-form-urlencoded")

        return $webclient.UploadString($script:APIAddress+$NodeLocation,"DELETE","")
    } else {
        return [xml]$webclient.DownloadString($script:APIAddress+$NodeLocation)
    }
}

# .ExternalHelp PsAcano.psm1-Help.xml
function New-AcanoSession {
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

# .ExternalHelp PsAcano.psm1-Help.xml
function Get-AcanocoSpaces {
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CallLegProfileFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/coSpaces"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($CallLegProfileFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&callLegProfileFilter=$CallLegProfileFilter"        } else {            $nodeLocation += "?callLegProfileFilter=$CallLegProfileFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).coSpaces.coSpace}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanocoSpace {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$coSpaceID    )    return (Open-AcanoAPI "api/v1/coSpaces/$coSpaceID").coSpace}# .ExternalHelp PsAcano.psm1-Help.xmlfunction New-AcanocoSpace {    Param (
        [parameter(Mandatory=$true)]        [string]$Name,
        [parameter(Mandatory=$true)]        [string]$Uri,        [parameter(Mandatory=$false)]        [string]$SecondaryUri="",        [parameter(Mandatory=$false)]        [string]$CallId="",        [parameter(Mandatory=$false)]        [string]$CdrTag="",        [parameter(Mandatory=$false)]        [string]$Passcode="",        [parameter(Mandatory=$false)]        [string]$DefaultLayout="",        [parameter(Mandatory=$false)]        [string]$TenantID="",        [parameter(Mandatory=$false)]        [string]$CallLegProfile="",        [parameter(Mandatory=$false)]        [string]$CallProfile="",        [parameter(Mandatory=$false)]        [string]$CallBrandingProfile="",        [parameter(Mandatory=$false)]        [boolean]$RequireCallID=$true,        [parameter(Mandatory=$false)]        [string]$Secret=""    )    $nodeLocation = "/api/v1/coSpaces"    $data = "name=$Name&uri=$Uri"    if ($SecondaryUri -ne "") {        $data += "&secondaryUri=$SecondaryUri"    }    if ($CallID -ne "") {        $data += "&callId=$CallId"    }    if ($CdrTag -ne "") {        $data += "&cdrTag=$CdrTag"    }    if ($Passcode -ne "") {        $data += "&passcode=$Passcode"    }    if ($DefaultLayout -ne "") {        $data += "&defaultLayout=$DefaultLayout"    }    if ($TenantID -ne "") {        $data += "&tenantId=$TenantID"    }    if ($CallLegProfile -ne "") {        $data += "&callLegProfile=$CallLegProfile"    }    if ($CallProfile -ne "") {        $data += "&callProfile=$CallProfile"    }    if ($CallBrandingProfile -ne "") {        $data += "&callBrandingProfile=$CallBrandingProfile"    }    if ($Secret -ne "") {        $data += "&secret=$Secret"    }    $data += "&requireCallID="+$RequireCallID.toString()    [string]$NewcoSpaceID = Open-AcanoAPI $nodeLocation -POST -Data $data    Get-AcanocoSpace -coSpaceID $NewcoSpaceID.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Set-AcanocoSpace {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$coSpaceId,
        [parameter(Mandatory=$false)]        [string]$Name,
        [parameter(Mandatory=$false)]        [string]$Uri,        [parameter(Mandatory=$false)]        [string]$SecondaryUri="",        [parameter(Mandatory=$false)]        [string]$CallId="",        [parameter(Mandatory=$false)]        [string]$CdrTag="",        [parameter(Mandatory=$false)]        [string]$Passcode="",        [parameter(Mandatory=$false)]        [string]$DefaultLayout="",        [parameter(Mandatory=$false)]        [string]$TenantId="",        [parameter(Mandatory=$false)]        [string]$CallLegProfile="",        [parameter(Mandatory=$false)]        [string]$CallProfile="",        [parameter(Mandatory=$false)]        [string]$CallBrandingProfile="",        [parameter(Mandatory=$false)]        [boolean]$RequireCallId,        [parameter(Mandatory=$false)]        [string]$Secret="",        [parameter(Mandatory=$false)]        [switch]$RegenerateSecret    )    $nodeLocation = "/api/v1/coSpaces/$coSpaceId"    $data = ""    $modifiers = 0        if ($Name -ne "") {        if ($modifiers -gt 0) {            $data += "&name=$Name"        } else {            $data += "name=$Name"            $modifiers++        }    }        if ($Uri -ne "") {        if ($modifiers -gt 0) {            $data += "&uri=$Uri"        } else {            $data += "uri=$Uri"            $modifiers++        }    }        if ($SecondaryURI -ne "") {        if ($modifiers -gt 0) {            $data += "&secondaryUri=$SecondaryUri"        } else {            $data += "secondaryUri=$SecondaryUri"            $modifiers++        }    }    if ($CallID -ne "") {        if ($modifiers -gt 0) {            $data += "&callID=$CallId"        } else {            $data += "callID=$CallId"            $modifiers++        }    }    if ($CdrTag -ne "") {        if ($modifiers -gt 0) {            $data += "&cdrTag=$CdrTag"        } else {            $data += "cdrTag=$CdrTag"            $modifiers++        }    }    if ($Passcode -ne "") {        if ($modifiers -gt 0) {            $data += "&passcode=$Passcode"        } else {            $data += "passcode=$Passcode"            $modifiers++        }    }    if ($DefaultLayout -ne "") {        if ($modifiers -gt 0) {            $data += "&defaultLayout=$DefaultLayout"        } else {            $data += "defaultLayout=$DefaultLayout"            $modifiers++        }    }    if ($TenantID -ne "") {        if ($modifiers -gt 0) {            $data += "&tenantId=$TenantId"        } else {            $data += "tenantId=$TenantId"            $modifiers++        }    }    if ($CallLegProfile -ne "") {        if ($modifiers -gt 0) {            $data += "&callLegProfile=$CallLegProfile"        } else {            $data += "callLegProfile=$CallLegProfile"            $modifiers++        }    }    if ($CallProfile -ne "") {        if ($modifiers -gt 0) {            $data += "&callProfile=$CallProfile"        } else {            $data += "callProfile=$CallProfile"            $modifiers++        }    }    if ($CallBrandingProfile -ne "") {        if ($modifiers -gt 0) {            $data += "&callBrandingProfile=$CallBrandingProfile"        } else {            $data += "callBrandingProfile=$CallBrandingProfile"            $modifiers++        }    }    if ($Secret -ne "") {        if ($modifiers -gt 0) {            $data += "&secret=$Secret"        } else {            $data += "secret=$Secret"            $modifiers++        }    }    if ((($RequireCallID -ne $true) -and ($RequireCallID -ne $false)) -eq $false) {        if ($modifiers -gt 0) {            $data += "&requireCallID="+$RequireCallId.toString()        } else {            $data += "requireCallID="+$RequireCallId.toString()            $modifiers++        }    }    if ($modifiers -gt 0) {        $data += "&regenerateSecret="+$RegenerateSecret.toString()    } else {        $data += "regenerateSecret="+$RegenerateSecret.toString()    }    Open-AcanoAPI $nodeLocation -PUT -Data $data}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Remove-AcanocoSpace {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$coSpaceID    )    ### Add confirmation    Open-AcanoAPI "api/v1/coSpaces/$coSpaceID" -DELETE}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanocoSpaceMembers {    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true,Position=1)]        [parameter(ParameterSetName="NoOffset",Mandatory=$true,Position=1)]        [string]$coSpaceID,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CallLegProfileFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )        $nodeLocation = "api/v1/coSpaces/$coSpaceID/coSpaceUsers"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($CallLegProfileFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&callLegProfileFilter=$CallLegProfileFilter"        } else {            $nodeLocation += "?callLegProfileFilter=$CallLegProfileFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).coSpaceUsers.coSpaceUser | fl}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanocoSpaceMember {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$coSpaceUserID,        [parameter(Mandatory=$true)]
        [string]$coSpaceID    )    return (Open-AcanoAPI "api/v1/coSpaces/$coSpaceID/coSpaceUsers/$coSpaceUserID").coSpaceUser}# .ExternalHelp PsAcano.psm1-Help.xmlfunction New-AcanocoSpaceMember {    Param (
        [parameter(Mandatory=$true)]        [string]$coSpaceId,
        [parameter(Mandatory=$true)]        [string]$UserJid,        [parameter(Mandatory=$false)]        [string]$CallLegProfile="",        [parameter(Mandatory=$false)]        [boolean]$CanDestroy,        [parameter(Mandatory=$false)]        [boolean]$CanAddRemoveMember,        [parameter(Mandatory=$false)]        [boolean]$CanChangeName,        [parameter(Mandatory=$false)]        [boolean]$CanChangeUri,        [parameter(Mandatory=$false)]        [boolean]$CanChangeCallId,        [parameter(Mandatory=$false)]        [boolean]$CanChangePasscode,        [parameter(Mandatory=$false)]        [boolean]$CanPostMessage,        [parameter(Mandatory=$false)]        [boolean]$CanRemoveSelf,        [parameter(Mandatory=$false)]        [boolean]$CanDeleteAllMessages    )    $nodeLocation = "/api/v1/coSpaces/$coSpaceId/coSpaceUsers"    $data = "userJid=$UserJid"    if ($CallLegProfile -ne "") {        $data += "&callLegProfile=$CallLegProfile"    }    if ((($CanDestroy -ne $true) -and ($CanDestroy -ne $false)) -eq $false) {        $data += "&canDestroy="+$CanDestroy.toString()    }    if ((($CanAddRemoveMember -ne $true) -and ($CanAddRemoveMember -ne $false)) -eq $false) {        $data += "&canAddRemoveMember="+$CanAddRemoveMember.toString()    }    if ((($CanChangeName -ne $true) -and ($CanChangeName -ne $false)) -eq $false) {        $data += "&canChangeName="+$CanChangeName.toString()    }    if ((($CanChangeUri -ne $true) -and ($CanChangeUri -ne $false)) -eq $false) {        $data += "&canChangeUri="+$CanChangeUri.toString()    }    if ((($CanChangeCallId -ne $true) -and ($CanChangeCallId -ne $false)) -eq $false) {        $data += "&canChangeCallId="+$CanChangeCallId.toString()    }    if ((($CanChangePasscode -ne $true) -and ($CanChangePasscode -ne $false)) -eq $false) {        $data += "&canChangePasscode="+$CanChangePasscode.toString()    }    if ((($CanPostMessage -ne $true) -and ($CanPostMessage -ne $false)) -eq $false) {        $data += "&canPostMessage="+$CanPostMessage.toString()    }    if ((($CanRemoveSelf -ne $true) -and ($CanRemoveSelf -ne $false)) -eq $false) {        $data += "&canRemoveSelf="+$CanRemoveSelf.toString()    }    if ((($CanDeleteAllMessages -ne $true) -and ($CanDeleteAllMessages -ne $false)) -eq $false) {        $data += "&canDeleteAllMessages="+$CanDeleteAllMessages.toString()    }    [string]$NewcoSpaceMemberID = Open-AcanoAPI $nodeLocation -POST -Data $data        Get-AcanocoSpaceMember -coSpaceID $coSpaceId -coSpaceUserID $NewcoSpaceMemberID.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Set-AcanocoSpaceMember {    Param (
        [parameter(Mandatory=$true)]
        [string]$coSpaceId,
        [parameter(Mandatory=$true)]
        [string]$UserId,
        [parameter(Mandatory=$false)]        [string]$UserJid="",        [parameter(Mandatory=$false)]        [string]$CallLegProfile="",        [parameter(Mandatory=$false)]        [boolean]$CanDestroy,        [parameter(Mandatory=$false)]        [boolean]$CanAddRemoveMember,        [parameter(Mandatory=$false)]        [boolean]$CanChangeName,        [parameter(Mandatory=$false)]        [boolean]$CanChangeUri,        [parameter(Mandatory=$false)]        [boolean]$CanChangeCallId,        [parameter(Mandatory=$false)]        [boolean]$CanChangePasscode,        [parameter(Mandatory=$false)]        [boolean]$CanPostMessage,        [parameter(Mandatory=$false)]        [boolean]$CanRemoveSelf,        [parameter(Mandatory=$false)]        [boolean]$CanDeleteAllMessages    )    $nodeLocation = "/api/v1/coSpaces/$coSpaceId/coSpaceUsers/$UserId"    $data = ""    $modifiers = 0        if ($UserJid -ne "") {        $data += "userJid=$UserJid"        $modifiers++    }        if ($CallLegProfile -ne "") {        if ($modifiers -gt 0) {            $data += "&callLegProfile=$CallLegProfile"        } else {            $data += "callLegProfile=$CallLegProfile"            $modifiers++        }    }    if ((($CanDestroy -ne $true) -and ($CanDestroy -ne $false)) -eq $false) {        if ($modifiers -gt 0) {            $data += "&canDestroy="+$CanDestroy.toString()        } else {            $data += "canDestroy="+$CanDestroy.toString()            $modifiers++        }    }    if ((($CanAddRemoveMember -ne $true) -and ($CanAddRemoveMember -ne $false)) -eq $false) {        if ($modifiers -gt 0) {            $data += "&canAddRemoveMember="+$CanAddRemoveMember.toString()        } else {            $data += "canAddRemoveMember="+$CanAddRemoveMember.toString()            $modifiers++        }    }    if ((($CanChangeName -ne $true) -and ($CanChangeName -ne $false)) -eq $false) {        if ($modifiers -gt 0) {            $data += "&canChangeName="+$CanChangeName.toString()        } else {            $data += "canChangeName="+$CanChangeName.toString()            $modifiers++        }    }    if ((($CanChangeUri -ne $true) -and ($CanChangeUri -ne $false)) -eq $false) {        if ($modifiers -gt 0) {            $data += "&canChangeUri="+$CanChangeUri.toString()        } else {            $data += "canChangeUri="+$CanChangeUri.toString()            $modifiers++        }    }    if ((($CanChangeCallId -ne $true) -and ($CanChangeCallId -ne $false)) -eq $false) {        if ($modifiers -gt 0) {            $data += "&canChangeCallId="+$CanChangeCallId.toString()        } else {            $data += "canChangeCallId="+$CanChangeCallId.toString()            $modifiers++        }    }    if ((($CanChangePasscode -ne $true) -and ($CanChangePasscode -ne $false)) -eq $false) {        if ($modifiers -gt 0) {            $data += "&canChangePasscode="+$CanChangePasscode.toString()        } else {            $data += "canChangePasscode="+$CanChangePasscode.toString()            $modifiers++        }    }    if ((($CanPostMessage -ne $true) -and ($CanPostMessage -ne $false)) -eq $false) {        if ($modifiers -gt 0) {            $data += "&canPostMessage="+$CanPostMessage.toString()        } else {            $data += "canPostMessage="+$CanPostMessage.toString()            $modifiers++        }    }    if ((($CanRemoveSelf -ne $true) -and ($CanRemoveSelf -ne $false)) -eq $false) {        if ($modifiers -gt 0) {            $data += "&canRemoveSelf="+$CanRemoveSelf.toString()        } else {            $data += "canRemoveSelf="+$CanRemoveSelf.toString()            $modifiers++        }    }    if ((($CanDeleteAllMessages -ne $true) -and ($CanDeleteAllMessages -ne $false)) -eq $false) {        if ($modifiers -gt 0) {            $data += "&canDeleteAllMessages="+$CanDeleteAllMessages.toString()        } else {            $data += "canDeleteAllMessages="+$CanDeleteAllMessages.toString()            $modifiers++        }    }    Open-AcanoAPI $nodeLocation -PUT -Data $data}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Remove-AcanocoSpaceMember {    Param (
        [parameter(Mandatory=$true)]
        [string]$coSpaceId,        [parameter(Mandatory=$true)]
        [string]$UserId    )    ### Add confirmation    Open-AcanoAPI "api/v1/coSpaces/$coSpaceId/coSpaceUsers/$UserId" -DELETE}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanocoSpaceAccessMethods {    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true,Position=1)]        [parameter(ParameterSetName="NoOffset",Mandatory=$true,Position=1)]        [string]$coSpaceID,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CallLegProfileFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )        $nodeLocation = "api/v1/coSpaces/$coSpaceID/accessMethods"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($CallLegProfileFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&callLegProfileFilter=$CallLegProfileFilter"        } else {            $nodeLocation += "?callLegProfileFilter=$CallLegProfileFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).accessMethods.accessMethod | fl}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanocoSpaceAccessMethod {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$coSpaceAccessMethodID,        [parameter(Mandatory=$true)]
        [string]$coSpaceID    )    return (Open-AcanoAPI "api/v1/coSpaces/$coSpaceID/accessMethods/$coSpaceAccessMethodID").accessMethod}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoOutboundDialPlanRules {
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
        [string]$OutboundDialPlanRuleID    )    return (Open-AcanoAPI "api/v1/outboundDialPlanRules/$OutboundDialPlanRuleID").outboundDialPlanRule}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoInboundDialPlanRules {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/inboundDialPlanRules"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).inboundDialPlanRules.inboundDialPlanRule}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoInboundDialPlanRule {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$InboundDialPlanRuleID    )    return (Open-AcanoAPI "api/v1/inboundDialPlanRules/$InboundDialPlanRuleID").inboundDialPlanRule}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCallForwardingDialPlanRules {
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
        [string]$ForwardingDialPlanRuleID    )    return (Open-AcanoAPI "api/v1/forwardingDialPlanRules/$ForwardingDialPlanRuleID").forwardingDialPlanRule}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCalls {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$coSpaceFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/calls"    $modifiers = 0    if ($coSpaceFilter -ne "") {        $nodeLocation += "?coSpacefilter=$coSpaceFilter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).calls.call}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCall {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallID    )    return (Open-AcanoAPI "api/v1/calls/$CallID").call}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCallProfiles {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/callProfiles"    $modifiers = 0    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).callProfiles.callProfile}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCallProfile {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallProfileID    )    return (Open-AcanoAPI "api/v1/callProfiles/$CallProfileID").callProfile}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCallLegs {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$ParticipantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [ValidateSet("true","false","")]        [string]$OwnerIDSet="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Alarms="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CallID="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    if ($CallID -ne "") {        $nodeLocation = "api/v1/calls/$CallID/callLegs"    } else {        $nodeLocation = "api/v1/callLegs"    }    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($ParticipantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&participantFilter=$ParticipantFilter"        } else {            $nodeLocation += "?participantFilter=$ParticipantFilter"            $modifiers++        }    }    if ($OwnerIdSet -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&ownerIdSet=$OwnerIdSet"        } else {            $nodeLocation += "?ownerIdSet=$OwnerIdSet"            $modifiers++        }    }    if ($Alarms -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&alarms=$Alarms"        } else {            $nodeLocation += "?alarms=$Alarms"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).callLegs.callLeg}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCallLeg {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallLegID    )    return (Open-AcanoAPI "api/v1/callLegs/$CallLegID").callLeg}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCallLegProfiles {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [ValidateSet("unreferenced","referenced","")]        [string]$UsageFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/callLegProfiles"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($UsageFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&usageFilter=$UsageFilter"        } else {            $nodeLocation += "?usageFilter=$UsageFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).callLegProfiles.callLegProfile}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCallLegProfile {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallLegProfileID    )    return (Open-AcanoAPI "api/v1/callLegProfiles/$CallLegProfileID").callLegProfile}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCallLegProfileUsages {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallLegProfileID    )    return (Open-AcanoAPI "api/v1/callLegProfiles/$CallLegProfileID/usage").callLegProfileUsage}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCallLegProfileTrace {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallLegID    )    return (Open-AcanoAPI "api/v1/callLegs/$CallLegID/callLegProfileTrace").callLegProfileTrace}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoDialTransforms {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/dialTransforms"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).dialTransforms.dialTransform}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoDialTransform {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$DialTransformID    )    return (Open-AcanoAPI "api/v1/dialTransform/$DialTransformID").dialTransform}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCallBrandingProfiles {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [ValidateSet("unreferenced","referenced","")]        [string]$UsageFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/callBrandingProfiles"    $modifiers = 0    if ($UsageFilter -ne "") {        $nodeLocation += "?usageFilter=$UsageFilter"        $modifiers++    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).callBrandingProfiles.callBrandingProfile}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCallBrandingProfile {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallBrandingProfileID    )    return (Open-AcanoAPI "api/v1/callBrandingProfiles/$CallBrandingProfileID").callBrandingProfile}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoDtmfProfiles {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [ValidateSet("unreferenced","referenced","")]        [string]$UsageFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/dtmfProfiles"    $modifiers = 0    if ($UsageFilter -ne "") {        $nodeLocation += "?usageFilter=$UsageFilter"        $modifiers++    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).dtmfProfiles.dtmfProfile}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoDtmfProfile {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$DtmfProfileID    )    return (Open-AcanoAPI "api/v1/dtmfProfiles/$DtmfProfileID").dtmfProfile}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoIvrs {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/ivrs"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).ivrs.ivr}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoIvr {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$IvrID    )    return (Open-AcanoAPI "api/v1/ivrs/$IvrID").ivr}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoIvrBrandingProfiles {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/ivrBrandingProfiles"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).ivrBrandingProfiles.ivrBrandingProfile}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoIvrBrandingProfile {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$IvrBrandingProfileID    )    return (Open-AcanoAPI "api/v1/ivrBrandingProfiles/$IvrBrandingProfileID").ivrBrandingProfile}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoParticipants {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$callBridgeFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/participants"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($CallBridgeFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&callBridgeFilter=$CallBridgeFilter"        } else {            $nodeLocation += "?callBridgeFilter=$CallBridgeFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).participants.participant}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoParticipant {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$ParticipantID    )    return (Open-AcanoAPI "api/v1/participants/$ParticipantID").participant}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoParticipantCallLegs {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$ParticipantID    )    return (Open-AcanoAPI "api/v1/participants/$ParticipantID/callLegs").callLeg}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoUsers {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/users"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).users.user}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoUser {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$UserID    )    return (Open-AcanoAPI "api/v1/users/$UserID").user}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoUsercoSpaces {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$UserID    )    return (Open-AcanoAPI "api/v1/users/$UserID/usercoSpaces").userCoSpaces.userCoSpace}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoUserProfiles {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [ValidateSet("unreferenced","referenced","")]        [string]$UsageFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/userProfiles"    $modifiers = 0    if ($UsageFilter -ne "") {        $nodeLocation += "?usageFilter=$UsageFilter"        $modifiers++    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).userProfiles.userProfile}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoUserProfile {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$UserProfileID    )    return (Open-AcanoAPI "api/v1/userProfiles/$UserProfileID").userProfile}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoSystemStatus {    return (Open-AcanoAPI "api/v1/system/status").status}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoSystemAlarms {    return (Open-AcanoAPI "api/v1/system/alarms").alarms.alarm}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoSystemAlarm {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$AlarmID    )    return (Open-AcanoAPI "api/v1/system/alarms/$AlarmID").alarm}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoSystemDatabaseStatus {    return (Open-AcanoAPI "api/v1/system/database").database}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCdrReceiverUri {    return (Open-AcanoAPI "api/v1/system/cdrReceiver").cdrReceiver}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoGlobalProfile {    return (Open-AcanoAPI "api/v1/system/profiles").profiles}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoTurnServers {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/turnServers"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }        if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).turnServers.turnServer}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoTurnServer {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$TurnServerID    )    return (Open-AcanoAPI "api/v1/turnServers/$TurnServerID").turnServer}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoWebBridges {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/webBridges"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }    if ($TenantFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&tenantFilter=$TenantFilter"        } else {            $nodeLocation += "?tenantFilter=$TenantFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).webBridges.webBridge}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoWebBridge {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$WebBridgeID    )    return (Open-AcanoAPI "api/v1/webBridges/$WebBridgeID").webBridge}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCallBridges {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/callBridges"    if ($Limit -ne "") {        $nodeLocation += "?limit=$Limit"                if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).callBridges.callBridge}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoCallBridge {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$CallBridgeID    )    return (Open-AcanoAPI "api/v1/callBridges/$CallBridgeID").callBridge}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoXmppServer {    return (Open-AcanoAPI "api/v1/system/configuration/xmpp").xmpp}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoSystemDiagnostics {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CoSpaceFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$CallCorrelatorFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/system/diagnostics"    $modifiers = 0    if ($CoSpaceFilter -ne "") {        $nodeLocation += "?coSpacefilter=$CoSpaceFilter"        $modifiers++    }    if ($CallCorrelatorFilter -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&callCorrelatorFilter=$CallCorrelatorFilter"        } else {            $nodeLocation += "?callCorrelatorFilter=$CallCorrelatorFilter"            $modifiers++        }    }    if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).diagnostics.diagnostic}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoSystemDiagnostic {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$SystemDiagnosticID    )    return (Open-AcanoAPI "api/v1/system/diagnostics/$SystemDiagnosticID").diagnostic}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoSystemDiagnosticContent {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$SystemDiagnosticID    )    return (Open-AcanoAPI "api/v1/system/diagnostics/$SystemDiagnosticID/contents").diagnostic}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoLdapServers {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/ldapServers"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }        if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).ldapServers.ldapServer}# .ExternalHelp PsAcano.psm1-Help.xmlfunction Get-AcanoLdapServer {    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$LdapServerID    )    return (Open-AcanoAPI "api/v1/ldapServers/$LdapServerID").ldapServer}function Get-AcanoLdapMappings {
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
        [string]$LdapSourceID    )    return (Open-AcanoAPI "api/v1/ldapSources/$LdapSourceID").ldapSource}function Get-AcanoLdapSyncs {
<#
.SYNOPSIS

Returns LDAP syncs currently pending and in-progress on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on LDAP syncs currently pending and in-progress
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of LDAP syncs beginning
at the sync in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoLdapSyncs

Will return all LDAP syncs currently pending and in-progress
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/ldapSyncs"    if ($Limit -ne "") {        $nodeLocation += "?limit=$Limit"                if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).ldapSyncs.ldapSync}function Get-AcanoLdapSync {<#
.SYNOPSIS

Returns information about a given LDAP sync currently pending and in-progress
.DESCRIPTION

Use this Cmdlet to get information on an LDAP sync currently pending and in-progress
.PARAMETER LdapSyncID

The ID of the LDAP sync currently pending and in-progress
.EXAMPLE
Get-AcanoLdapSync -LdapSyncID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the LDAP sync currently pending and in-progress

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$LdapSyncID    )    return (Open-AcanoAPI "api/v1/ldapSyncs/$LdapSyncID").ldapSync}function Get-AcanoExternalDirectorySearchLocations {
<#
.SYNOPSIS

Returns external directory search locations currently configured on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on external directory search locations
.PARAMETER TenantFilter <tenantID>

Returns external directory search locations associated with that tenant
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of external directory
search locations beginning at the location in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-AcanoExternalDirectorySearchLocations

Will return all LDAP mappings
.EXAMPLE
Get-AcanoLdapSources -TenantFilter ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the external directory search locations associated with
that tenant
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$TenantFilter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/directorySearchLocations"    $modifiers = 0    if ($TenantFilter -ne "") {        $nodeLocation += "?tenantFilter=$TenantFilter"        $modifiers++    }        if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).directorySearchLocations.directorySearchLocation}function Get-AcanoExternalDirectorySearchLocation {<#
.SYNOPSIS

Returns information about a given external directory search location
.DESCRIPTION

Use this Cmdlet to get information on a external directory search location
.PARAMETER ExternalDirectorySearchLocationID

The ID of the external directory search location
.EXAMPLE
Get-AcanoExternalDirectorySearchLocation -ExternalDirectorySearchLocationID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the external directory search location

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$ExternalDirectorySearchLocationID    )    return (Open-AcanoAPI "api/v1/directorySearchLocations/$ExternalDirectorySearchLocationID").directorySearchLocation}function Get-AcanoTenants {
<#
.SYNOPSIS

Returns Tenants currently configured on the Acano server
.DESCRIPTION

Use this Cmdlet to get information on Tenants
.PARAMETER Filter

Returns Tenants that matches the filter text
.PARAMETER Limit

Limits the returned results
.PARAMETER Offset

Can only be used together with -Limit. Returns the limited number of Tenants beginning
at the Tenant in the offset. See the API reference guide for uses. 
.EXAMPLE

Get-Get-AcanoTenants

Will return all Tenants
.EXAMPLE
Get-AcanoTenants -Filter "Greg"

Will return all Tenants whos URI contains "Greg"
#>
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Filter="",        [parameter(ParameterSetName="Offset",Mandatory=$true)]        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]        [string]$Limit="",        [parameter(ParameterSetName="Offset",Mandatory=$false)]        [string]$Offset=""    )    $nodeLocation = "api/v1/tenants"    $modifiers = 0    if ($Filter -ne "") {        $nodeLocation += "?filter=$Filter"        $modifiers++    }        if ($Limit -ne "") {        if ($modifiers -gt 0) {            $nodeLocation += "&limit=$Limit"        } else {            $nodeLocation += "?limit=$Limit"        }        if($Offset -ne ""){            $nodeLocation += "&offset=$Offset"        }    }    return (Open-AcanoAPI $nodeLocation).tenants.tenant}function Get-AcanoTenant {<#
.SYNOPSIS

Returns information about a given Tenant
.DESCRIPTION

Use this Cmdlet to get information on a Tenant
.PARAMETER TenantID

The ID of the Tenant
.EXAMPLE
Get-AcanoTenant -TenantID ce03f08f-547f-4df1-b531-ae3a64a9c18f

Will return information on the Tenant

#>    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$TenantID    )    return (Open-AcanoAPI "api/v1/tenants/$TenantID").tenants}