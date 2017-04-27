function Open-CmsAPI {
    Param (
        [parameter(ParameterSetName="GET",Mandatory=$true,Position=1)]
        [parameter(ParameterSetName="POST",Mandatory=$true,Position=1)]
        [parameter(ParameterSetName="PUT",Mandatory=$true,Position=1)]
        [parameter(ParameterSetName="DELETE",Mandatory=$true,Position=1)]
        [string]$NodeLocation,
        [parameter(ParameterSetName="POST",Mandatory=$true)]
        [switch]$POST,
        [parameter(ParameterSetName="PUT",Mandatory=$true)]
        [switch]$PUT,
        [parameter(ParameterSetName="DELETE",Mandatory=$true)]
        [switch]$DELETE,
        [parameter(ParameterSetName="POST",Mandatory=$false)]
        [parameter(ParameterSetName="PUT",Mandatory=$false)]
        [parameter(ParameterSetName="DELETE",Mandatory=$false)]
        [string]$Data,
        [parameter(ParameterSetName="POST",Mandatory=$false)]
        [switch]$ReturnResponse
    )

    $webclient = New-Object System.Net.WebClient
    $credCache = new-object System.Net.CredentialCache
    $credCache.Add($script:APIAddress, "Basic", $script:creds)

    $webclient.Headers.Add("user-agent", "PSCms Powershell Module")
    $webclient.Credentials = $credCache

    try {
        if ($POST) {
            $webclient.Headers.Add("Content-Type","application/x-www-form-urlencoded")
            $response = $webclient.UploadString($script:APIAddress+$NodeLocation,"POST",$Data)

            if ($ReturnResponse) {
                return [xml]$response
            }
            else {
                $res = $webclient.ResponseHeaders.Get("Location")

                return $res.Substring($res.Length-36)
            }
        } elseif ($PUT) {
            $webclient.Headers.Add("Content-Type","application/x-www-form-urlencoded")

            return $webclient.UploadString($script:APIAddress+$NodeLocation,"PUT",$Data)
        } elseif ($DELETE){
            $webclient.Headers.Add("Content-Type","application/x-www-form-urlencoded")

            return $webclient.UploadString($script:APIAddress+$NodeLocation,"DELETE",$Data)
        } else {
            return [xml]$webclient.DownloadString($script:APIAddress+$NodeLocation)
        }
    }
    catch [Net.WebException]{
        if ($_.Exception.Response.StatusCode.Value__ -eq 400) {
            [System.IO.StreamReader]$failure = $_.Exception.Response.GetResponseStream()
            $CmsFailureReasonRaw = $failure.ReadToEnd()
            $stripbefore = $CmsFailureReasonRaw.Remove(0,38)
            $CmsFailureReason = $stripbefore.Remove($stripbefore.Length-20)
          
            Write-Error "Error: API returned reason: $CmsFailureReason" -ErrorId $CmsFailureReason -TargetObject $NodeLocation
        }
    }
}

function New-CmsSession {
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
        $port = 443
    }

    $script:creds = $Credential

    if ($IgnoreSSLTrust) {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    }

    $connectionstatus = Get-CmsSystemStatus
    $ver = $connectionstatus.softwareVersion
    $ut = $connectionstatus.uptimeSeconds
    if ($connectionstatus -ne $null) {
        Write-Information "Successfully connected to the Cms Server at $APIAddress`:$port running version $ver. Uptime is $ut seconds."
        return $true
    }
    else {
        throw "Could not connect to the Cms Server at $APIAddress`:$port"
    }
}

function Get-CmsSpaces {
[CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$TenantFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$CallLegProfileFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/coSpaces"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($TenantFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }

        $nodeLocation += "tenantFilter=$TenantFilter"
        $modifiers++
    }

    if ($CallLegProfileFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }

        $nodeLocation += "callLegProfileFilter=$CallLegProfileFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
            
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).coSpaces.coSpace
}

function Get-CmsSpace {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) 

    { 

        "getAll"  {
            Get-CmsSpaces
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/coSpaces/$Identity").coSpace
        } 
    } 
}

function New-CmsSpace {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Name,
        [parameter(Mandatory=$true)]
        [string]$Uri,
        [parameter(Mandatory=$false)]
        [string]$SecondaryUri,
        [parameter(Mandatory=$false)]
        [string]$CallId,
        [parameter(Mandatory=$false)]
        [string]$CdrTag,
        [parameter(Mandatory=$false)]
        [string]$Passcode,
        [parameter(Mandatory=$false)]
        [ValidateSet("allEqual","speakerOnly","telepresence","stacked","allEqualQuarters","allEqualNinths","allEqualSixteenths","allEqualTwentyFifths","onePlusFive","onePlusSeven","onePlusNine","onePlusN","automatic")]
        [string]$DefaultLayout,
        [parameter(Mandatory=$false)]
        [string]$TenantID,
        [parameter(Mandatory=$false)]
        [string]$CallLegProfile,
        [parameter(Mandatory=$false)]
        [string]$CallProfile,
        [parameter(Mandatory=$false)]
        [string]$CallBrandingProfile,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RequireCallID="true",
        [parameter(Mandatory=$false)]
        [string]$Secret,
        [parameter(Mandatory=$false)]
        [string]$OwnerId,
        [parameter(Mandatory=$false)]
        [string]$OwnerJid,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$NonMemberAccess
    )

    $nodeLocation = "/api/v1/coSpaces"
    $data = "name=$Name&uri=$Uri"

    if ($SecondaryUri -ne "") {
        $data += "&secondaryUri=$SecondaryUri"
    }

    if ($CallID -ne "") {
        $data += "&callId=$CallId"
    }

    if ($CdrTag -ne "") {
        $data += "&cdrTag=$CdrTag"
    }

    if ($Passcode -ne "") {
        $data += "&passcode=$Passcode"
    }

    if ($DefaultLayout -ne "") {
        $data += "&defaultLayout=$DefaultLayout"
    }

    if ($TenantID -ne "") {
        $data += "&tenantId=$TenantID"
    }

    if ($CallLegProfile -ne "") {
        $data += "&callLegProfile=$CallLegProfile"
    }

    if ($CallProfile -ne "") {
        $data += "&callProfile=$CallProfile"
    }

    if ($CallBrandingProfile -ne "") {
        $data += "&callBrandingProfile=$CallBrandingProfile"
    }

    if ($Secret -ne "") {
        $data += "&secret=$Secret"
    }

    if ($OwnerId -ne "") {
        $data += "&ownerId=$OwnerId"
    }

    if ($OwnerJid -ne "") {
        $data += "&ownerJid=$OwnerJid"
    }

    if ($NonMemberAccess -ne "") {
        $data += "&nonMemberAccess=$NonMemberAccess"
    }

    $data += "&requireCallID="+$RequireCallID

    [string]$NewcoSpaceID = Open-CmsAPI $nodeLocation -POST -Data $data

    Get-CmsSpace $NewcoSpaceID.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsSpace {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$Name,
        [parameter(Mandatory=$false)]
        [string]$Uri,
        [parameter(Mandatory=$false)]
        [string]$SecondaryUri,
        [parameter(Mandatory=$false)]
        [string]$CallId,
        [parameter(Mandatory=$false)]
        [string]$CdrTag,
        [parameter(Mandatory=$false)]
        [string]$Passcode,
        [parameter(Mandatory=$false)]
        [ValidateSet("allEqual","speakerOnly","telepresence","stacked","allEqualQuarters","allEqualNinths","allEqualSixteenths","allEqualTwentyFifths","onePlusFive","onePlusSeven","onePlusNine","onePlusN","automatic")]
        [string]$DefaultLayout,
        [parameter(Mandatory=$false)]
        [string]$TenantId,
        [parameter(Mandatory=$false)]
        [string]$CallLegProfile,
        [parameter(Mandatory=$false)]
        [string]$CallProfile,
        [parameter(Mandatory=$false)]
        [string]$CallBrandingProfile,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RequireCallId,
        [parameter(Mandatory=$false)]
        [string]$Secret,
        [parameter(Mandatory=$false)]
        [switch]$RegenerateSecret,
        [parameter(Mandatory=$false)]
        [string]$OwnerId,
        [parameter(Mandatory=$false)]
        [string]$OwnerJid,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$NonMemberAccess
    )

    $nodeLocation = "/api/v1/coSpaces/$Identity"
    $data = ""
    $modifiers = 0
    
    if ($Name -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "name=$Name"
        $modifiers++
    }
    
    if ($Uri -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "uri=$Uri"
        $modifiers++
    }
    
    if ($SecondaryURI -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "secondaryUri=$SecondaryUri"
        $modifiers++
    }

    if ($CallID -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callID=$CallId"
        $modifiers++
    }

    if ($CdrTag -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "cdrTag=$CdrTag"
        $modifiers++
    }

    if ($Passcode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "passcode=$Passcode"
        $modifiers++
    }

    if ($DefaultLayout -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "defaultLayout=$DefaultLayout"
        $modifiers++
    }

    if ($TenantID -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "tenantId=$TenantId"
        $modifiers++
    }

    if ($CallLegProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callLegProfile=$CallLegProfile"
        $modifiers++
    }

    if ($CallProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callProfile=$CallProfile"
        $modifiers++
    }

    if ($CallBrandingProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callBrandingProfile=$CallBrandingProfile"
        $modifiers++
    }

    if ($Secret -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "secret=$Secret"
        $modifiers++
    }

    if ($RequireCallID -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "requireCallID="+$RequireCallId
        $modifiers++
    }

    if ($OwnerId -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "ownerId=$OwnerId"
        $modifiers++
    }

    if ($OwnerJid -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "ownerJid=$OwnerJid"
        $modifiers++
    }

    if ($NonMemberAccess -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "nonMemberAccess=$NonMemberAccess"
        $modifiers++
    }

    if ($modifiers -gt 0) {
            $data += "&"
        }
    $data += "regenerateSecret="+$RegenerateSecret.toString()

    Open-CmsAPI $nodeLocation -PUT -Data $data

    Get-CmsSpace $Identity
}

function Remove-CmsSpace { 
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove coSpace")) {
        Open-CmsAPI "api/v1/coSpaces/$Identity" -DELETE
    }
}

function Get-CmsSpaceMembers {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true,Position=1)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$CallLegProfileFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    
    $nodeLocation = "api/v1/coSpaces/$Identity/coSpaceUsers"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($CallLegProfileFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "callLegProfileFilter=$CallLegProfileFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).coSpaceUsers.coSpaceUser | fl
}

function Get-CmsSpaceMember {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(ParameterSetName="getSingle",Mandatory=$true)]
        [parameter(ParameterSetName="getAll",Mandatory=$false)]
        [string]$coSpaceMemberID
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsSpaceMembers $Identity
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/coSpaces/$Identity/coSpaceUsers/$coSpaceMemberID").coSpaceUser
        }
    }
}

function New-CmsSpaceMember {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Identity,
        [parameter(Mandatory=$true)]
        [string]$UserJid,
        [parameter(Mandatory=$false)]
        [string]$CallLegProfile,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanDestroy,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanAddRemoveMember,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanChangeName,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanChangeUri,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanChangeCallId,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanChangePasscode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanPostMessage,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanRemoveSelf,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanDeleteAllMessages
    )

    $nodeLocation = "/api/v1/coSpaces/$Identity/coSpaceUsers"
    $data = "userJid=$UserJid"

    if ($CallLegProfile -ne "") {
        $data += "&callLegProfile=$CallLegProfile"
    }

    if ($CanDestroy -ne "") {
        $data += "&canDestroy="+$CanDestroy
    }

    if ($CanAddRemoveMember -ne "") {
        $data += "&canAddRemoveMember="+$CanAddRemoveMember
    }

    if ($CanChangeName -ne "") {
        $data += "&canChangeName="+$CanChangeName
    }

    if ($CanChangeUri -ne "") {
        $data += "&canChangeUri="+$CanChangeUri
    }

    if ($CanChangeCallId -ne "") {
        $data += "&canChangeCallId="+$CanChangeCallId
    }

    if ($CanChangePasscode -ne "") {
        $data += "&canChangePasscode="+$CanChangePasscode
    }

    if ($CanPostMessage -ne "") {
        $data += "&canPostMessage="+$CanPostMessage
    }

    if ($CanRemoveSelf -ne "") {
        $data += "&canRemoveSelf="+$CanRemoveSelf
    }

    if ($CanDeleteAllMessages -ne "") {
        $data += "&canDeleteAllMessages="+$CanDeleteAllMessages
    }

    [string]$NewcoSpaceMemberID = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsSpaceMember $Identity -coSpaceMemberID $NewcoSpaceMemberID.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsSpaceMember {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Identity,
        [parameter(Mandatory=$true)]
        [string]$coSpaceMemberId,
        [parameter(Mandatory=$false)]
        [string]$CallLegProfile,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanDestroy,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanAddRemoveMember,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanChangeName,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanChangeUri,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanChangeCallId,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanChangePasscode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanPostMessage,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanRemoveSelf,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanDeleteAllMessages
    )

    $nodeLocation = "/api/v1/coSpaces/$Identity/coSpaceUsers/$coSpaceMemberId"
    $data = ""
    $modifiers = 0
    
    if ($CallLegProfile -ne "") {
            $data += "callLegProfile=$CallLegProfile"
            $modifiers++
    }

    if ($CanDestroy -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canDestroy=$CanDestroy"
        $modifiers++
    }

    if ($CanAddRemoveMember -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canAddRemoveMember=$CanAddRemoveMember"
        $modifiers++
    }

    if ($CanChangeName -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canChangeName=$CanChangeName"
        $modifiers++
    }

    if ($CanChangeUri -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canChangeUri=$CanChangeUri"
        $modifiers++
    }

    if ($CanChangeCallId -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canChangeCallId=$CanChangeCallId"
        $modifiers++
    }

    if ($CanChangePasscode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canChangePasscode=$CanChangePasscode"
        $modifiers++
    }

    if ($CanPostMessage -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
            $data += "canPostMessage=$CanPostMessage"
            $modifiers++
    }

    if ($CanRemoveSelf -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canRemoveSelf=$CanRemoveSelf"
        $modifiers++
    }

    if ($CanDeleteAllMessages -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canDeleteAllMessages=$CanDeleteAllMessages"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data

    Get-CmsSpaceMember $Identity -coSpaceMemberID $coSpaceMemberId
}

function Remove-CmsSpaceMember {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true)]
        [string]$Identity,
        [parameter(Mandatory=$true)]
        [string]$UserId
    )

    if ($PSCmdlet.ShouldProcess("$UserId","Remove user from cospace with id $Identity")) {
        Open-CmsAPI "api/v1/coSpaces/$Identity/coSpaceUsers/$UserId" -DELETE
    }
}

function New-CmsSpaceMessage {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Identity,
        [parameter(Mandatory=$true)]
        [string]$Message,
        [parameter(Mandatory=$true)]
        [string]$From
    )

    $nodeLocation = "/api/v1/coSpaces/$Identity/messages"
    $data = "message=$Message"
    $data += "&from=$From"

    [string]$NewcoSpaceMessage = Open-CmsAPI $nodeLocation -POST -Data $data
    
    ## NOT IMPLEMENTED YET Get-CmsSpaceMember -coSpaceID $coSpaceId -coSpaceUserID $NewcoSpaceMessage.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Remove-CmsSpaceMessages {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$MinAge,
        [parameter(Mandatory=$false)]
        [string]$MaxAge
    )

    $nodeLocation = "/api/v1/coSpaces/$Identity/messages"
    $data = ""
    $modifiers = 0

    if ($MinAge -ne "") {
        $data += "minAge=$MinAge"
        $modifiers++
    }

    if ($MaxAge -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "maxAge=$MaxAge"
    }

    if ($PSCmdlet.ShouldProcess("$Identity","Remove messages in coSpace")) {
        if ($modifiers -gt 0) {
            Open-CmsAPI $nodeLocation -DELETE -Data $data
        } else {
            Open-CmsAPI $nodeLocation -DELETE
        }
    } 
}

function Get-CmsSpaceAccessMethods {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true,Position=1)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$CallLegProfileFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    
    $nodeLocation = "api/v1/coSpaces/$Identity/accessMethods"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($CallLegProfileFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "callLegProfileFilter=$CallLegProfileFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).accessMethods.accessMethod | fl
}

function Get-CmsSpaceAccessMethod {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(ParameterSetName="getSingle",Mandatory=$true)]
        [parameter(ParameterSetName="getAll",Mandatory=$false)]
        [string]$coSpaceAccessMethodID
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsSpaceAccessMethods $Identity
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/coSpaces/$Identity/accessMethods/$coSpaceAccessMethodID").accessMethod
        }
    }
}

function New-CmsSpaceAccessMethod {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$Uri,
        [parameter(Mandatory=$false)]
        [string]$CallId,
        [parameter(Mandatory=$false)]
        [string]$Passcode,
        [parameter(Mandatory=$false)]
        [string]$CallLegProfile,
        [parameter(Mandatory=$false)]
        [string]$Secret,
        [parameter(Mandatory=$false)]
        [string]$Scope
    )

    $nodeLocation = "/api/v1/coSpaces/$Identity/accessMethods"
    $data = ""
    $modifiers = 0

    if ($Uri -ne "") {
        $data += "uri=$Uri"
        $modifiers++
    }

    if ($CallId -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }

        $data += "callId=$CallId"
        $modifiers++
    }

    if ($Passcode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }

        $data += "passcode=$Passcode"
        $modifiers++
    }

    if ($CallLegProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        } 

        $data += "callLegProfile=$CallLegProfile"
        $modifiers++
    }

    if ($Secret -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        } 

        $data += "secret=$Secret"
        $modifiers++
    }

    if ($Scope -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        } 

        $data += "scope=$Scope"
    }

    [string]$NewcoSpaceAccessMethod = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsSpaceAccessMethod $Identity -coSpaceAccessMethodID $NewcoSpaceAccessMethod.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsSpaceAccessMethod {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$true)]
        [string]$coSpaceAccessMethodID,
        [parameter(Mandatory=$false)]
        [string]$Uri,
        [parameter(Mandatory=$false)]
        [string]$CallId,
        [parameter(Mandatory=$false)]
        [string]$Passcode,
        [parameter(Mandatory=$false)]
        [string]$CallLegProfile,
        [parameter(Mandatory=$false)]
        [string]$Secret,
        [parameter(Mandatory=$false)]
        [switch]$RegenerateSecret,
        [parameter(Mandatory=$false)]
        [string]$Scope
    )

    $nodeLocation = "/api/v1/coSpaces/$Identity/accessMethods/$coSpaceAccessMethodID"
    $data = ""
    $modifiers = 0

    if ($Uri -ne "") {
        $data += "uri=$Uri"
        $modifiers++
    }

    if ($CallId -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        } 

        $data += "callId=$CallId"
        $modifiers++
    }

    if ($Passcode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        } 

        $data += "passcode=$Passcode"
        $modifiers++
    }

    if ($CallLegProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        } 

        $data += "callLegProfile=$CallLegProfile"
        $modifiers++
    }

    if ($Secret -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        } 

        $data += "secret=$Secret"
        $modifiers++
    }

    if ($RegenerateSecret) {
        if ($modifiers -gt 0) {
            $data += "&"
        } 

        $data += "regenerateSecret=true"
        $modifiers++
    }

    if ($Scope -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        } 
        
        $data += "scope=$Scope"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsSpaceAccessMethod $Identity -coSpaceAccessMethodID $coSpaceAccessMethodID

}

function Remove-CmsSpaceAccessMethod {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true)]
        [string]$Identity,
        [parameter(Mandatory=$true)]
        [string]$coSpaceAccessMethodID
    )

    if ($PSCmdlet.ShouldProcess("$coSpaceAccessMethodID","Remove access method from coSpace $Identity")) {
        Open-CmsAPI "api/v1/coSpaces/$Identity/accessMethods/$coSpaceAccessMethodID" -DELETE
    }
}

function Get-CmsSpaceBulkParameterSets {

    $nodeLocation = "api/v1/coSpaceBulkParameterSets"

    return (Open-CmsAPI $nodeLocation).coSpaceBulkParameterSets.coSpaceBulkParameterSet
}

function Get-CmsSpaceBulkParameterSet {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsSpaceBulkParameterSets
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/coSpaceBulkParameterSets/$Identity").coSpaceBulkParameterSet
        } 
    }  
}

function New-CmsSpaceBulkParameterset {
    Param (
        [parameter(Mandatory=$true)]
        [string]$StartIndex,
        [parameter(Mandatory=$true)]
        [string]$Endindex,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceUriMapping,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceNameMapping,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceCallIdMapping,
        [parameter(Mandatory=$false)]
        [string]$CallProfile,
        [parameter(Mandatory=$false)]
        [string]$CallBrandingProfile,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$NonMemberAccess,
        [parameter(Mandatory=$false)]
        [string]$Tenant
    )


    $nodeLocation = "/api/v1/coSpaceBulkParameterSet"
    $data = "startIndex=$StartIndex&endIndex=$Endindex"

    if ($CoSpaceUriMapping -ne "") {
        $data += "&coSpaceUriMapping=$CoSpaceUriMapping"
    }
    
    if ($CoSpaceNameMapping -ne "") {
        $data += "&coSpaceNameMapping="+$CoSpaceNameMapping
    }

    if ($CoSpaceCallIdMapping -ne "") {
        $data += "&coSpaceCallIdMapping="+$CoSpaceCallIdMapping
    }

    if ($CallProfile -ne "") {
        $data += "&callProfile="+$CallProfile
    }

    if ($CallBrandingProfile -ne "") {
        $data += "&callBrandingProfile="+$CallBrandingProfile
    }

    if ($NonMemberAccess -ne "") {
        $data += "&nonMemberAccess="+$NonMemberAccess
    }

    if ($Tenant -ne "") {
        $data += "&tenant=$Tenant"
    }

    [string]$NewSpaceBulkParametersetId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsSpaceBulkParameterSet $NewSpaceBulkParametersetId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsSpaceBulkParameterSet {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$true)]
        [string]$StartIndex,
        [parameter(Mandatory=$true)]
        [string]$Endindex,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceUriMapping,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceNameMapping,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceCallIdMapping,
        [parameter(Mandatory=$false)]
        [string]$CallProfile,
        [parameter(Mandatory=$false)]
        [string]$CallBrandingProfile,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$NonMemberAccess,
        [parameter(Mandatory=$false)]
        [string]$Tenant
    )


    $nodeLocation = "/api/v1/coSpaceBulkParameterSets/$Identity"
    $data = ""
    $modifiers = 0

    if ($StartIndex -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "startIndex=$StartIndex"
        $modifiers++
    }

    if ($Endindex -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "endindex=$Endindex"
        $modifiers++
    }
    
    if ($CoSpaceUriMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "coSpaceUriMapping=$CoSpaceUriMapping"
        $modifiers++
    }

    if ($CoSpaceNameMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "coSpaceNameMapping=$CoSpaceNameMapping"
        $modifiers++
    }

    if ($CoSpaceCallIdMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "coSpaceCallIdMapping=$CoSpaceCallIdMapping"
        $modifiers++
    }

    if ($CallProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callProfile=$CallProfile"
        $modifiers++
    }

    if ($CallBrandingProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callBrandingProfile=$CallBrandingProfile"
        $modifiers++
    }

    if ($NonMemberAccess -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "nonMemberAccess=$NonMemberAccess"
        $modifiers++
    }

    if ($Tenant -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "tenant=$Tenant"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsSpaceBulkParameterSet $Identity
}

function Start-CmsSpaceCallDiagnosticsGeneration {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    Open-CmsAPI "api/v1/coSpaces/$Identity/diagnostics" -POST

}

function Get-CmsOutboundDialPlanRules {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/outboundDialPlanRules"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).outboundDialPlanRules.outboundDialPlanRule
}

function Get-CmsOutboundDialPlanRule {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsOutboundDialPlanRules
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/outboundDialPlanRules/$Identity").outboundDialPlanRule
        } 
    }  
}

function New-CmsOutboundDialPlanRule {
    [CmdletBinding(DefaultParameterSetName="NoCallbridgeId")]
    Param (
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$true)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$true)]
        [string]$Domain,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [string]$LocalContactDomain,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [string]$LocalFromDomain,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [string]$SipProxy,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [ValidateSet("sip","lync","avaya")]
        [string]$TrunkType,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [string]$Priority,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [ValidateSet("stop","continue")]
        [string]$FailureAction,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [ValidateSet("auto","encrypted","unencrypted")]
        [string]$SipControlEncryption,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$true)]
        [ValidateSet("global","callbridge")]
        [string]$Scope,
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [string]$CallBridgeId,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [string]$Tenant,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [ValidateSet("default","traversal")]
        [string]$CallRouting
    )

    $nodeLocation = "/api/v1/outboundDialPlanRules"
    $data = "domain=$Domain"

    if ($LocalContactDomain -ne "") {
        $data += "&localContactDomain=$LocalContactDomain"
    }

    if ($LocalFromDomain -ne "") {
        $data += "&localFromDomain=$LocalFromDomain"
    }

    if ($SipProxy -ne "") {
        $data += "&sipProxy=$SipProxy"
    }

    if ($TrunkType -ne "") {
        $data += "&trunkType=$TrunkType"
    }

    if ($Priority -ne "") {
        $data += "&priority=$Priority"
    }
    
    if ($FailureAction -ne "") {
        $data += "&failureAction=$FailureAction"
    }

    if ($SipControlEncryption -ne "") {
        $data += "&sipControlEncryption=$SipControlEncryption"
    }

    if ($Scope -ne "") {
        $data += "&scope=$Scope"
    }

    if ($CallBridgeId -ne "") {
        $data += "&callBridge=$CallBridgeId"
    }

    if ($Tenant -ne "") {
        $data += "&tenant=$Tenant"
    }

    if ($CallRouting -ne "") {
        $data += "&callRouting=$CallRouting"
    }

    [string]$NewOutboundDialPlanRuleId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsOutboundDialPlanRule $NewOutboundDialPlanRuleId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsOutboundDialPlanRule {
    [CmdletBinding(DefaultParameterSetName="NoCallbridgeId")]
    Param (
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$true,Position=1)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [string]$Domain,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [string]$LocalContactDomain,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [string]$LocalFromDomain,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [string]$SipProxy,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [ValidateSet("sip","lync","avaya")]
        [string]$TrunkType,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [string]$Priority,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [ValidateSet("stop","continue")]
        [string]$FailureAction,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [ValidateSet("auto","encrypted","unencrypted")]
        [string]$SipControlEncryption,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$true)]
        [ValidateSet("global","callbridge")]
        [string]$Scope,
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [string]$CallBridgeId,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [string]$Tenant,
        [parameter(ParameterSetName="NoCallbridgeId",Mandatory=$false)]
        [parameter(ParameterSetName="CallbridgeId",Mandatory=$false)]
        [ValidateSet("default","traversal")]
        [string]$CallRouting
    )

    $nodeLocation = "/api/v1/outboundDialPlanRules/$Identity"
    $modifiers = 0
    $data = ""

    if ($Domain -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "domain=$Domain"
        $modifiers++
    }

    if ($LocalContactDomain -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "localContactDomain=$LocalContactDomain"
        $modifiers++
    }

    if ($LocalFromDomain -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "localFromDomain=$LocalFromDomain"
        $modifiers++
    }

    if ($SipProxy -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "sipProxy=$SipProxy"
        $modifiers++
    }

    if ($TrunkType -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "trunkType=$TrunkType"
        $modifiers++
    }

    if ($Priority -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "priority=$Priority"
        $modifiers++
    }
    
    if ($FailureAction -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "failureAction=$FailureAction"
        $modifiers++
    }

    if ($SipControlEncryption -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "sipControlEncryption=$SipControlEncryption"
        $modifiers++
    }

    if ($Scope -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "scope=$Scope"
        $modifiers++
    }

    if ($CallBridgeId -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callBridge=$CallBridgeId"
        $modifiers++
    }

    if ($Tenant -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "tenant=$Tenant"
        $modifiers++
    }

    if ($CallRouting -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callRouting=$CallRouting"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsOutboundDialPlanRule $Identity
}

function Remove-CmsOutboundDialPlanRule {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove outbound dial plan rule")) {
        Open-CmsAPI "/api/v1/outboundDialPlanRules/$Identity" -DELETE
    }
}

function Get-CmsInboundDialPlanRules {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$TenantFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/inboundDialPlanRules"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($TenantFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "tenantFilter=$TenantFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).inboundDialPlanRules.inboundDialPlanRule
}

function Get-CmsInboundDialPlanRule {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsInboundDialPlanRules
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/inboundDialPlanRules/$Identity").inboundDialPlanRule
        } 
    }
}

function New-CmsInboundDialPlanRule {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Domain,
        [parameter(Mandatory=$false)]
        [string]$Priority,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveToUsers,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveTocoSpaces,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveToIvrs,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveToLyncConferences,
        [parameter(Mandatory=$false)]
        [string]$Tenant
    )


    $nodeLocation = "/api/v1/inboundDialPlanRules"
    $data = "domain=$Domain"

    if ($Priority -ne "") {
        $data += "&priority=$Priority"
    }
    
    if ($ResolveToUsers -ne "") {
        $data += "&resolveToUsers="+$ResolveToUsers
    }

    if ($ResolveTocoSpaces -ne "") {
        $data += "&resolveTocoSpaces="+$ResolveTocoSpaces
    }

    if ($ResolveToIvrs -ne "") {
        $data += "&resolveToIvrs="+$ResolveToIvrs
    }

    if ($ResolveToLyncConferences -ne "") {
        $data += "&resolveToLyncConferences="+$ResolveToLyncConferences
    }

    if ($Tenant -ne "") {
        $data += "&tenant=$Tenant"
    }

    [string]$NewInboundDialPlanRuleId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsInboundDialPlanRule $NewInboundDialPlanRuleId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsInboundDialPlanRule {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$Domain,
        [parameter(Mandatory=$false)]
        [string]$Priority,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveToUsers,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveTocoSpaces,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveToIvrs,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveToLyncConferences,
        [parameter(Mandatory=$false)]
        [string]$Tenant
    )


    $nodeLocation = "/api/v1/inboundDialPlanRules/$Identity"
    $data = ""
    $modifiers = 0

    if ($Domain -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "domain=$Domain"
        $modifiers++
    }

    if ($Priority -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "priority=$Priority"
        $modifiers++
    }
    
    if ($ResolveToUsers -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resolveToUsers=$ResolveToUsers"
        $modifiers++
    }

    if ($ResolveTocoSpaces -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resolveTocoSpaces=$ResolveTocoSpaces"
        $modifiers++
    }

    if ($ResolveToIvrs -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resolveToIvrs=$ResolveToIvrs"
        $modifiers++
    }

    if ($ResolveToLyncConferences -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resolveToLyncConferences=$ResolveToLyncConferences"
        $modifiers++
    }

    if ($Tenant -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "tenant=$Tenant"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsInboundDialPlanRule $Identity
}

function Remove-CmsInboundDialPlanRule {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove inbound dial plan rule")) {
        Open-CmsAPI "/api/v1/inboundDialPlanRules/$Identity" -DELETE
    }
}

function Get-CmsCallForwardingDialPlanRules {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/forwardingDialPlanRules"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).forwardingDialPlanRules.forwardingDialPlanRule
}

function Get-CmsCallForwardingDialPlanRule {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsCallForwardingDialPlanRules
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/forwardingDialPlanRules/$Identity").forwardingDialPlanRule
        } 
    }
}

function New-CmsCallForwardingDialPlanRule {
    Param (
        [parameter(Mandatory=$true)]
        [string]$MatchPattern,
        [parameter(Mandatory=$false)]
        [string]$DestinationDomain,
        [parameter(Mandatory=$false)]
        [ValidateSet("forward","reject")]
        [string]$Action,
        [parameter(Mandatory=$false)]
        [ValidateSet("regenerate","preserve")]
        [string]$CallerIdMode,
        [parameter(Mandatory=$false)]
        [string]$Priority,
        [parameter(Mandatory=$false)]
        [string]$Tenant,
        [parameter(Mandatory=$false)]
        [string]$UriParameters
    )

    $nodeLocation = "/api/v1/forwardingDialPlanRules"
    $data = "matchPattern=$MatchPattern"

    if ($DestinationDomain -ne "") {
        $data += "&destinationDomain=$DestinationDomain"
    }

    if ($Action -ne "") {
        $data += "&action=$Action"
    }
    
    if ($CallerIdMode -ne "") {
        $data += "&callerIdMode=$CallerIdMode"
    }

    if ($Priority -ne "") {
        $data += "&priority=$Priority"
    }

    if ($Tenant -ne "") {
        $data += "&tenant=$Tenant"
    }

    if ($UriParameters -ne "") {
        $data += "&uriParameters=$UriParameters"
    }

    [string]$NewCallForwardingPlanRuleId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsCallForwardingDialPlanRule $NewCallForwardingPlanRuleId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsCallForwardingDialPlanRule {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$MatchPattern,
        [parameter(Mandatory=$false)]
        [string]$DestinationDomain,
        [parameter(Mandatory=$false)]
        [ValidateSet("forward","reject")]
        [string]$Action,
        [parameter(Mandatory=$false)]
        [ValidateSet("regenerate","preserve")]
        [string]$CallerIdMode,
        [parameter(Mandatory=$false)]
        [string]$Priority,
        [parameter(Mandatory=$false)]
        [string]$Tenant,
        [parameter(Mandatory=$false)]
        [string]$UriParameters
    )

    $nodeLocation = "/api/v1/forwardingDialPlanRules/$Identity"
    $modifiers = 0
    $data = ""

    if ($MatchPattern -ne "") {
        if ($modifiers -gt 0) {
            $data += ""
        }
        $data += "matchPattern=$MatchPattern"
        $modifiers++
    }

    if ($DestinationDomain -ne "") {
        if ($modifiers -gt 0) {
            $data += ""
        }
        $data += "destinationDomain=$DestinationDomain"
        $modifiers++
    }

    if ($Action -ne "") {
        if ($modifiers -gt 0) {
            $data += ""
        }
        $data += "action=$Action"
        $modifiers++
    }

    if ($CallerIdMode -ne "") {
        if ($modifiers -gt 0) {
            $data += ""
        }
        $data += "callerIdMode=$CallerIdMode"
        $modifiers++
    }

    if ($Priority -ne "") {
        if ($modifiers -gt 0) {
            $data += ""
        }
        $data += "priority=$Priority"
        $modifiers++
    }

    if ($UriParameters -ne "") {
        if ($modifiers -gt 0) {
            $data += ""
        }
        $data += "uriParameters=$UriParameters"
        $modifiers++
    }

    if ($Tenant -ne "") {
        if ($modifiers -gt 0) {
            $data += ""
        }
        $data += "tenant=$Tenant"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsCallForwardingDialPlanRule $Identity
}

function Remove-CmsCallForwardingDialPlanRule {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove call forwarding rule")) {
        Open-CmsAPI "/api/v1/forwardingDialPlanRules/$Identity" -DELETE
    }
}

function Get-CmsCalls {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$coSpaceFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$TenantFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/calls"
    $modifiers = 0

    if ($coSpaceFilter -ne "") {
        $nodeLocation += "?coSpacefilter=$coSpaceFilter"
        $modifiers++
    }

    if ($TenantFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "tenantFilter=$TenantFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).calls.call
}

function Get-CmsCall {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsCalls
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/calls/$Identity").call
        } 
    }
}

function New-CmsCall {
    Param (
        [parameter(Mandatory=$true)]
        [string]$CoSpaceId,
        [parameter(Mandatory=$false)]
        [string]$Name,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$Locked,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$Recording,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$AllowAllMuteSelf,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$AllowAllPresentationContribution,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$JoinAudioMuteOverride
    )

    $nodeLocation = "/api/v1/calls"
    $data = "coSpace=$CoSpaceId"

    if ($Name -ne "") {
        $data += "&name=$Name"
    }

    if ($Locked -ne "") {
        $data += "&locked=$Locked"
    }

    if ($Recording -ne "") {
        $data += "&recording=$Recording"
    }

    if ($AllowAllMuteSelf -ne "") {
        $data += "&allowAllMuteSelf=$AllowAllMuteSelf"
    }

    if ($AllowAllPresentationContribution -ne "") {
        $data += "&allowAllPresentationContribution=$AllowAllPresentationContribution"
    }

    if ($JoinAudioMuteOverride -ne "") {
        $data += "&joinAudioMuteOverride=$JoinAudioMuteOverride"
    }

    [string]$NewCallId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsCall $NewCallId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsCall {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$Name,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$Locked,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$Recording,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$AllowAllMuteSelf,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$AllowAllPresentationContribution,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$JoinAudioMuteOverride
    )

    $nodeLocation = "/api/v1/calls/$Identity"
    $data = ""
    $modifiers = 0

    if ($Name -ne "") {
        $data += "name=$Name"
        $modifiers++
    }

    if ($Locked -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "locked=$Locked"
        $modifiers++
    }

    if ($Recording -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "recording=$Recording"
    }

    if ($AllowAllMuteSelf -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "allowAllMuteSelf=$AllowAllMuteSelf"
    }

    if ($AllowAllPresentationContribution -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "allowAllPresentationContribution=$AllowAllPresentationContribution"
    }

    if ($JoinAudioMuteOverride -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "joinAudioMuteOverride=$JoinAudioMuteOverride"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsCall $Identity
}

function Remove-CmsCall {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove call")) {
        Open-CmsAPI "/api/v1/calls/$Identity" -DELETE
    }
}

function Get-CmsCallProfiles {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/callProfiles"
    $modifiers = 0

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).callProfiles.callProfile
}

function Get-CmsCallProfile {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsCallProfiles
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/callProfiles/$Identity").callProfile | fl
        } 
    }
}

function New-CmsCallProfile {
    Param (
        [parameter(Mandatory=$false)]
        [string]$ParticipantLimit,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$MessageBoardEnabled,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$Locked,
        [parameter(Mandatory=$false)]
        [ValidateSet("disabled","manual","automatic")]
        [string]$RecordingMode
    )

    $nodeLocation = "/api/v1/callProfiles"
    $data = ""
    $modifiers = 0

    if ($ParticipantLimit -ne "") {
        $data += "participantLimit=$ParticipantLimit"
        $modifiers++
    }

    if ($MessageBoardEnabled -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "messageBoardEnabled=$MessageBoardEnabled"
        $modifiers++
    }

    if ($RecordingMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "recordingMode=$RecordingMode"
        $modifiers++
    }

    if ($Locked -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "locked=$Locked"
    }

    [string]$NewCallProfileId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsCallProfile -$NewCallProfileId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsCallProfile {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$ParticipantLimit,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$MessageBoardEnabled,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$Locked,
        [parameter(Mandatory=$false)]
        [ValidateSet("disabled","manual","automatic")]
        [string]$RecordingMode
    )

    $nodeLocation = "/api/v1/callProfiles/$Identity"
    $data = ""
    $modifiers = 0

    if ($ParticipantLimit -ne "") {
        $data += "participantLimit=$ParticipantLimit"
        $modifiers++
    }

    if ($MessageBoardEnabled -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "messageBoardEnabled=$MessageBoardEnabled"
        $modifiers++
    }

    if ($RecordingMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "recordingMode=$RecordingMode"
        $modifiers++
    }

    if ($Locked -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "locked=$Locked"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsCallProfile $Identity
}

function Remove-CmsCallProfile {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove call profile")) {
        Open-CmsAPI "/api/v1/callProfiles/$Identity" -DELETE
    }
}

function Get-CmsCallLegs {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$TenantFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$ParticipantFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$OwnerIDSet,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [ValidateSet("All","packetLoss","excessiveJitter","highRoundTripTime")]
        [string[]]$Alarms,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$CallID,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$ActiveLayoutFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$AvailableVideoStreamsLowerBound,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$AvailableVideoStreamsUpperBound,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    if ($CallID -ne "") {
        $nodeLocation = "api/v1/calls/$CallID/callLegs"
    } else {
        $nodeLocation = "api/v1/callLegs"
    }

    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($TenantFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "tenantFilter=$TenantFilter"
        $modifiers++
    }

    if ($ParticipantFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "participantFilter=$ParticipantFilter"
        $modifiers++
    }

    if ($OwnerIdSet -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "ownerIdSet=$OwnerIdSet"
        $modifiers++
    }

    if ($Alarms -ne $null) {
        if ($Alarms.Contains("All") -or $Alarms.Contains("all")) {
            $Alarmstring = "all"
        } else {
            $i = 0
            foreach ($Alarm in $Alarms) {
                if ($i -eq 0) {
                    $Alarmstring = $Alarm
                } else {
                    $Alarmstring += "|$Alarm"
                }
                $i++
            }
        }

        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "alarms=$Alarmstring"
        $modifiers++
    }

    if ($ActiveLayoutFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        
        $nodeLocation += "activeLayoutFilter=$ActiveLayoutFilter"
        $modifiers++
    }

    if ($AvailableVideoStreamsLowerBound -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        
        $nodeLocation += "availableVideoStreamsLowerBound=$AvailableVideoStreamsLowerBound"
        $modifiers++
    }

    if ($AvailableVideoStreamsUpperBound -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        
        $nodeLocation += "availableVideoStreamsUpperBound=$AvailableVideoStreamsUpperBound"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).callLegs.callLeg
}


function Get-CmsCallLeg {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsCallLegs
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/callLegs/$Identity").callLeg
        } 
    }
}

function New-CmsCallLeg {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Identity,
        [parameter(Mandatory=$true)]
        [string]$RemoteParty,
        [parameter(Mandatory=$false)]
        [string]$Bandwidth,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$Confirmation,
        [parameter(Mandatory=$false)]
        [string]$OwnerId,
        [parameter(Mandatory=$false)]
        [ValidateSet("allEqual","speakerOnly","telepresence","stacked","allEqualQuarters","allEqualNinths","allEqualSixteenths","allEqualTwentyFifths","onePlusFive","onePlusSeven","onePlusNine","onePlusN","automatic")]
        [string]$ChosenLayout,
        [parameter(Mandatory=$false)]
        [string]$CallLegProfileId,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$NeedsActivation,
        [parameter(Mandatory=$false)]
        [ValidateSet("allEqual","speakerOnly","telepresence","stacked","allEqualQuarters","allEqualNinths","allEqualSixteenths","allEqualTwentyFifths","onePlusFive","onePlusSeven","onePlusNine","onePlusN","automatic")]
        [string]$DefaultLayout,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$EndCallAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$MuteOthersAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$VideoMuteOthersAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$MuteSelfAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$VideoMuteSelfAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ChangeLayoutAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ParticipantLabels,
        [parameter(Mandatory=$false)]
        [ValidateSet("dualStream","singleStream")]
        [string]$PresentationDisplayMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$PresentationContributionAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$PresentationViewingAllowed,
        [parameter(Mandatory=$false)]
        [string]$JoinToneParticipantThreshold,
        [parameter(Mandatory=$false)]
        [string]$LeaveToneParticipantThreshold,
        [parameter(Mandatory=$false)]
        [ValidateSet("auto","disabled")]
        [string]$VideoMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RxAudioMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TxAudioMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RxVideoMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TxVideoMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("optional","required","prohibited")]
        [string]$SipMediaEncryption,
        [parameter(Mandatory=$false)]
        [string]$AudioPacketSizeMs,
        [parameter(Mandatory=$false)]
        [ValidateSet("deactivate","disconnect","remainActivated")]
        [string]$DeactivationMode,
        [parameter(Mandatory=$false)]
        [string]$DeactivationModeTime,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TelepresenceCallsAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$SipPresentationChannelEnabled,
        [parameter(Mandatory=$false)]
        [string]$DtmfSequence,
        [parameter(Mandatory=$false)]
        [ValidateSet("serverOnly","serverAndClient")]
        [string]$BfcpMode
    )

    $nodeLocation = "/api/v1/calls/$Identity/callLegs"
    $data = "remoteParty=$RemoteParty"

    if ($Bandwidth -ne "") {
        $data += "&bandwidth=$Bandwidth"
    }

    if ($Confirmation -ne "") {
        $data += "&confirmation=$Confirmation"
    }

    if ($OwnerId -ne "") {
        $data += "&ownerId=$OwnerId"
    }

    if ($ChosenLayout -ne "") {
        $data += "&chosenLayout=$ChosenLayout"
    }

    if ($CallLegProfileId -ne "") {
        $data += "&callLegProfile=$CallLegProfileId"
    }

    if ($NeedsActivation -ne "") {
        $data += "&needsActivation=$NeedsActivation"
    }

    if ($DefaultLayout -ne "") {
        $data += "&defaultLayout=$DefaultLayout"
    }

    if ($EndCallAllowed -ne "") {
        $data += "&endCallAllowed=$EndCallAllowed"
    }

    if ($MuteOthersAllowed -ne "") {
        $data += "&muteOthersAllowed=$MuteOthersAllowed"
    }

    if ($VideoMuteOthersAllowed -ne "") {
        $data += "&videoMuteOthersAllowed=$VideoMuteOthersAllowed"
    }

    if ($MuteSelfAllowed -ne "") {
        $data += "&muteSelfAllowed=$MuteSelfAllowed"
    }

    if ($VideoMuteSelfAllowed -ne "") {
        $data += "&videoMuteSelfAllowed=$VideoMuteSelfAllowed"
    }

    if ($ChangeLayoutAllowed -ne "") {
        $data += "&changeLayoutAllowed=$ChangeLayoutAllowed"
    }

    if ($ParticipantLabels -ne "") {
        $data += "&participantLabels=$ParticipantLabels"
    }

    if ($PresentationDisplayMode -ne "") {
        $data += "&presentationDisplayMode=$PresentationDisplayMode"
    }

    if ($PresentationContributionAllowed -ne "") {
        $data += "&presentationContributionAllowed=$PresentationContributionAllowed"
    }

    if ($PresentationViewingAllowed -ne "") {
        $data += "&presentationViewingAllowed=$PresentationViewingAllowed"
    }

    if ($JoinToneParticipantThreshold -ne "") {
        $data += "&joinToneParticipantThreshold=$JoinToneParticipantThreshold"
    }

    if ($LeaveToneParticipantThreshold -ne "") {
        $data += "&leaveToneParticipantThreshold=$LeaveToneParticipantThreshold"
    }

    if ($VideoMode -ne "") {
        $data += "&videoMode=$VideoMode"
    }

    if ($RxAudioMute -ne "") {
        $data += "&rxAudioMute=$RxAudioMute"
    }

    if ($TxAudioMute -ne "") {
        $data += "&txAudioMute=$TxAudioMute"
    }

    if ($RxVideoMute -ne "") {
        $data += "&rxVideoMute=$RxVideoMute"
    }

    if ($TxVideoMute -ne "") {
        $data += "&txVideoMute=$TxVideoMute"
    }

    if ($SipMediaEncryption -ne "") {
        $data += "&sipMediaEncryption=$SipMediaEncryption"
    }

    if ($AudioPacketSizeMs -ne "") {
        $data += "&audioPacketSizeMs=$AudioPacketSizeMs"
    }

    if ($DeactivationMode -ne "") {
        $data += "&deactivationMode=$DeactivationMode"
    }

    if ($DeactivationModeTime -ne "") {
        $data += "&deactivationModeTime=$DeactivationModeTime"
    }

    if ($TelepresenceCallsAllowed -ne "") {
        $data += "&telepresenceCallsAllowed=$TelepresenceCallsAllowed"
    }

    if ($SipPresentationChannelEnabled -ne "") {
        $data += "&sipPresentationChannelEnabled=$SipPresentationChannelEnabled"
    }

    if ($BfcpMode -ne "") {
        $data += "&bfcpMode=$BfcpMode"
    }

    if ($DtmfSequence -ne "") {
        $data += "&dtmfSequence=$DtmfSequence"
    }

    [string]$NewCallLegId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsCallLeg $NewCallLegId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsCallLeg {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$OwnerId,
        [parameter(Mandatory=$false)]
        [ValidateSet("allEqual","speakerOnly","telepresence","stacked","allEqualQuarters","allEqualNinths","allEqualSixteenths","allEqualTwentyFifths","onePlusFive","onePlusSeven","onePlusNine","onePlusN","automatic")]
        [string]$ChosenLayout,
        [parameter(Mandatory=$false)]
        [string]$CallLegProfileId,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$NeedsActivation,
        [parameter(Mandatory=$false)]
        [ValidateSet("allEqual","speakerOnly","telepresence","stacked","allEqualQuarters","allEqualNinths","allEqualSixteenths","allEqualTwentyFifths","onePlusFive","onePlusSeven","onePlusNine","onePlusN","automatic")]
        [string]$DefaultLayout,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$EndCallAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$MuteOthersAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$VideoMuteOthersAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$MuteSelfAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$VideoMuteSelfAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ChangeLayoutAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ParticipantLabels,
        [parameter(Mandatory=$false)]
        [ValidateSet("dualStream","singleStream")]
        [string]$PresentationDisplayMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$PresentationContributionAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$PresentationViewingAllowed,
        [parameter(Mandatory=$false)]
        [string]$JoinToneParticipantThreshold,
        [parameter(Mandatory=$false)]
        [string]$LeaveToneParticipantThreshold,
        [parameter(Mandatory=$false)]
        [ValidateSet("auto","disabled")]
        [string]$VideoMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RxAudioMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TxAudioMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RxVideoMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TxVideoMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("optional","required","prohibited")]
        [string]$SipMediaEncryption,
        [parameter(Mandatory=$false)]
        [string]$AudioPacketSizeMs,
        [parameter(Mandatory=$false)]
        [ValidateSet("deactivate","disconnect","remainActivated")]
        [string]$DeactivationMode,
        [parameter(Mandatory=$false)]
        [string]$DeactivationModeTime,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TelepresenceCallsAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$SipPresentationChannelEnabled,
        [parameter(Mandatory=$false)]
        [string]$DtmfSequence,
        [parameter(Mandatory=$false)]
        [ValidateSet("serverOnly","serverAndClient")]
        [string]$BfcpMode
    )

    $nodeLocation = "/api/v1/callLegs/$Identity"
    $data = ""
    $modifiers = 0

    if ($OwnerId -ne "") {
        $data += "&ownerId=$OwnerId"
        $modifiers++
    }

    if ($ChosenLayout -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "chosenLayout=$ChosenLayout"
        $modifiers++
    }

    if ($CallLegProfileId -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callLegProfile=$CallLegProfileId"
        $modifiers++
    }

    if ($NeedsActivation -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "needsActivation=$NeedsActivation"
        $modifiers++
    }

    if ($DefaultLayout -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "defaultLayout=$DefaultLayout"
        $modifiers++
    }

    if ($EndCallAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "endCallAllowed=$EndCallAllowed"
        $modifiers++
    }

    if ($MuteOthersAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteOthersAllowed=$MuteOthersAllowed"
        $modifiers++
    }

    if ($VideoMuteOthersAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "videoMuteOthersAllowed=$VideoMuteOthersAllowed"
        $modifiers++
    }

    if ($MuteSelfAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteSelfAllowed=$MuteSelfAllowed"
        $modifiers++
    }

    if ($VideoMuteSelfAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "videoMuteSelfAllowed=$VideoMuteSelfAllowed"
        $modifiers++
    }

    if ($ChangeLayoutAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "changeLayoutAllowed=$ChangeLayoutAllowed"
        $modifiers++
    }

    if ($ParticipantLabels -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "participantLabels=$ParticipantLabels"
        $modifiers++
    }

    if ($PresentationDisplayMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "presentationDisplayMode=$PresentationDisplayMode"
        $modifiers++
    }

    if ($PresentationContributionAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "presentationContributionAllowed=$PresentationContributionAllowed"
        $modifiers++
    }

    if ($PresentationViewingAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "presentationViewingAllowed=$PresentationViewingAllowed"
        $modifiers++
    }

    if ($JoinToneParticipantThreshold -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "joinToneParticipantThreshold=$JoinToneParticipantThreshold"
        $modifiers++
    }

    if ($LeaveToneParticipantThreshold -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "leaveToneParticipantThreshold=$LeaveToneParticipantThreshold"
        $modifiers++
    }

    if ($VideoMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "videoMode=$VideoMode"
        $modifiers++
    }

    if ($RxAudioMute -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "rxAudioMute=$RxAudioMute"
        $modifiers++
    }

    if ($TxAudioMute -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "txAudioMute=$TxAudioMute"
        $modifiers++
    }

    if ($RxVideoMute -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "rxVideoMute=$RxVideoMute"
        $modifiers++
    }

    if ($TxVideoMute -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "txVideoMute=$TxVideoMute"
        $modifiers++
    }

    if ($SipMediaEncryption -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "sipMediaEncryption=$SipMediaEncryption"
        $modifiers++
    }

    if ($AudioPacketSizeMs -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "audioPacketSizeMs=$AudioPacketSizeMs"
        $modifiers++
    }

    if ($DeactivationMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "deactivationMode=$DeactivationMode"
        $modifiers++
    }

    if ($DeactivationModeTime -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "deactivationModeTime=$DeactivationModeTime"
        $modifiers++
    }

    if ($TelepresenceCallsAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "telepresenceCallsAllowed=$TelepresenceCallsAllowed"
        $modifiers++
    }

    if ($SipPresentationChannelEnabled -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "sipPresentationChannelEnabled=$SipPresentationChannelEnabled"
        $modifiers++
    }

    if ($DtmfSequence -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "dtmfSequence=$DtmfSequence"
        $modifiers++
    }

    if ($BfcpMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "bfcpMode=$BfcpMode"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsCallLeg $Identity
}

function Remove-CmsCallLeg {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove call leg")) {
        Open-CmsAPI "/api/v1/callLegs/$Identity" -DELETE
    }
}

function New-CmsCallLegParticipant {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$true)]
        [string]$RemoteParty,
        [parameter(Mandatory=$false)]
        [string]$Bandwidth,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$Confirmation,
        [parameter(Mandatory=$false)]
        [string]$OwnerId,
        [parameter(Mandatory=$false)]
        [ValidateSet("allEqual","speakerOnly","telepresence","stacked","allEqualQuarters","allEqualNinths","allEqualSixteenths","allEqualTwentyFifths","onePlusFive","onePlusSeven","onePlusNine","onePlusN","automatic")]
        [string]$ChosenLayout,
        [parameter(Mandatory=$false)]
        [string]$CallLegProfileId,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$NeedsActivation,
        [parameter(Mandatory=$false)]
        [ValidateSet("allEqual","speakerOnly","telepresence","stacked","allEqualQuarters","allEqualNinths","allEqualSixteenths","allEqualTwentyFifths","onePlusFive","onePlusSeven","onePlusNine","onePlusN","automatic")]
        [string]$DefaultLayout,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$EndCallAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$MuteOthersAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$VideoMuteOthersAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$MuteSelfAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$VideoMuteSelfAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ChangeLayoutAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ParticipantLabels,
        [parameter(Mandatory=$false)]
        [ValidateSet("dualStream","singleStream")]
        [string]$PresentationDisplayMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$PresentationContributionAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$PresentationViewingAllowed,
        [parameter(Mandatory=$false)]
        [string]$JoinToneParticipantThreshold,
        [parameter(Mandatory=$false)]
        [string]$LeaveToneParticipantThreshold,
        [parameter(Mandatory=$false)]
        [ValidateSet("auto","disabled")]
        [string]$VideoMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RxAudioMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TxAudioMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RxVideoMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TxVideoMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("optional","required","prohibited")]
        [string]$SipMediaEncryption,
        [parameter(Mandatory=$false)]
        [string]$AudioPacketSizeMs,
        [parameter(Mandatory=$false)]
        [ValidateSet("deactivate","disconnect","remainActivated")]
        [string]$DeactivationMode,
        [parameter(Mandatory=$false)]
        [string]$DeactivationModeTime,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TelepresenceCallsAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$SipPresentationChannelEnabled,
        [parameter(Mandatory=$false)]
        [string]$DtmfSequence,
        [parameter(Mandatory=$false)]
        [ValidateSet("serverOnly","serverAndClient")]
        [string]$BfcpMode
    )

    $nodeLocation = "/api/v1/calls/$Identity/participants"
    $data = "remoteParty=$RemoteParty"

    if ($Bandwidth -ne "") {
        $data += "&bandwidth=$Bandwidth"
    }

    if ($Confirmation -ne "") {
        $data += "&confirmation=$Confirmation"
    }

    if ($OwnerId -ne "") {
        $data += "&ownerId=$OwnerId"
    }

    if ($ChosenLayout -ne "") {
        $data += "&chosenLayout=$ChosenLayout"
    }

    if ($CallLegProfileId -ne "") {
        $data += "&callLegProfile=$CallLegProfileId"
    }

    if ($NeedsActivation -ne "") {
        $data += "&needsActivation=$NeedsActivation"
    }

    if ($DefaultLayout -ne "") {
        $data += "&defaultLayout=$DefaultLayout"
    }

    if ($EndCallAllowed -ne "") {
        $data += "&endCallAllowed=$EndCallAllowed"
    }

    if ($MuteOthersAllowed -ne "") {
        $data += "&muteOthersAllowed=$MuteOthersAllowed"
    }

    if ($VideoMuteOthersAllowed -ne "") {
        $data += "&videoMuteOthersAllowed=$VideoMuteOthersAllowed"
    }

    if ($MuteSelfAllowed -ne "") {
        $data += "&muteSelfAllowed=$MuteSelfAllowed"
    }

    if ($VideoMuteSelfAllowed -ne "") {
        $data += "&videoMuteSelfAllowed=$VideoMuteSelfAllowed"
    }

    if ($ChangeLayoutAllowed -ne "") {
        $data += "&changeLayoutAllowed=$ChangeLayoutAllowed"
    }

    if ($ParticipantLabels -ne "") {
        $data += "&participantLabels=$ParticipantLabels"
    }

    if ($PresentationDisplayMode -ne "") {
        $data += "&presentationDisplayMode=$PresentationDisplayMode"
    }

    if ($PresentationContributionAllowed -ne "") {
        $data += "&presentationContributionAllowed=$PresentationContributionAllowed"
    }

    if ($PresentationViewingAllowed -ne "") {
        $data += "&presentationViewingAllowed=$PresentationViewingAllowed"
    }

    if ($JoinToneParticipantThreshold -ne "") {
        $data += "&joinToneParticipantThreshold=$JoinToneParticipantThreshold"
    }

    if ($LeaveToneParticipantThreshold -ne "") {
        $data += "&leaveToneParticipantThreshold=$LeaveToneParticipantThreshold"
    }

    if ($VideoMode -ne "") {
        $data += "&videoMode=$VideoMode"
    }

    if ($RxAudioMute -ne "") {
        $data += "&rxAudioMute=$RxAudioMute"
    }

    if ($TxAudioMute -ne "") {
        $data += "&txAudioMute=$TxAudioMute"
    }

    if ($RxVideoMute -ne "") {
        $data += "&rxVideoMute=$RxVideoMute"
    }

    if ($TxVideoMute -ne "") {
        $data += "&txVideoMute=$TxVideoMute"
    }

    if ($SipMediaEncryption -ne "") {
        $data += "&sipMediaEncryption=$SipMediaEncryption"
    }

    if ($AudioPacketSizeMs -ne "") {
        $data += "&audioPacketSizeMs=$AudioPacketSizeMs"
    }

    if ($DeactivationMode -ne "") {
        $data += "&deactivationMode=$DeactivationMode"
    }

    if ($DeactivationModeTime -ne "") {
        $data += "&deactivationModeTime=$DeactivationModeTime"
    }

    if ($TelepresenceCallsAllowed -ne "") {
        $data += "&telepresenceCallsAllowed=$TelepresenceCallsAllowed"
    }

    if ($SipPresentationChannelEnabled -ne "") {
        $data += "&sipPresentationChannelEnabled=$SipPresentationChannelEnabled"
    }

    if ($BfcpMode -ne "") {
        $data += "&bfcpMode=$BfcpMode"
    }

    if ($DtmfSequence -ne "") {
        $data += "&dtmfSequence=$DtmfSequence"
    }

    [string]$NewCallLegParticipantId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsParticipant $NewCallLegParticipantId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Get-CmsCallLegProfiles {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [ValidateSet("unreferenced","referenced","")]
        [string]$UsageFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/callLegProfiles"


    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($UsageFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "usageFilter=$UsageFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).callLegProfiles.callLegProfile
}

function Get-CmsCallLegProfile {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsCallLegProfiles
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/callLegProfiles/$Identity").callLegProfile
        } 
    }
}

function New-CmsCallLegProfile {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$NeedsActivation,
        [parameter(Mandatory=$false)]
        [ValidateSet("allEqual","speakerOnly","telepresence","stacked","allEqualQuarters","allEqualNinths","allEqualSixteenths","allEqualTwentyFifths","onePlusFive","onePlusSeven","onePlusNine","onePlusN","automatic")]
        [string]$DefaultLayout,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$EndCallAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$MuteOthersAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$VideoMuteOthersAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$MuteSelfAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$AllowMuteSelfAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$VideoMuteSelfAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ChangeLayoutAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ParticipantLabels,
        [parameter(Mandatory=$false)]
        [ValidateSet("dualStream","singleStream")]
        [string]$PresentationDisplayMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$PresentationContributionAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$PresentationViewingAllowed,
        [parameter(Mandatory=$false)]
        [string]$JoinToneParticipantThreshold,
        [parameter(Mandatory=$false)]
        [string]$LeaveToneParticipantThreshold,
        [parameter(Mandatory=$false)]
        [ValidateSet("auto","disabled")]
        [string]$VideoMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RxAudioMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TxAudioMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RxVideoMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TxVideoMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("optional","required","prohibited")]
        [string]$SipMediaEncryption,
        [parameter(Mandatory=$false)]
        [string]$AudioPacketSizeMs,
        [parameter(Mandatory=$false)]
        [ValidateSet("deactivate","disconnect","remainActivated")]
        [string]$DeactivationMode,
        [parameter(Mandatory=$false)]
        [string]$DeactivationModeTime,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TelepresenceCallsAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$SipPresentationChannelEnabled,
        [parameter(Mandatory=$false)]
        [ValidateSet("serverOnly","serverAndClient")]
        [string]$BfcpMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CallLockAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RecordingControlAllowed,
        [parameter(Mandatory=$false)]
        [string]$Name,
        [parameter(Mandatory=$false)]
        [string]$MaxCallDurationTime
    )

    $nodeLocation = "/api/v1/callLegProfiles"
    $data = ""
    $modifiers = 0

    if ($NeedsActivation -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "needsActivation=$NeedsActivation"
        $modifiers++
    }

    if ($DefaultLayout -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "defaultLayout=$DefaultLayout"
        $modifiers++
    }

    if ($EndCallAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "endCallAllowed=$EndCallAllowed"
        $modifiers++
    }

    if ($MuteOthersAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteOthersAllowed=$MuteOthersAllowed"
        $modifiers++
    }

    if ($VideoMuteOthersAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "videoMuteOthersAllowed=$VideoMuteOthersAllowed"
        $modifiers++
    }

    if ($MuteSelfAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteSelfAllowed=$MuteSelfAllowed"
        $modifiers++
    }

    if ($AllowMuteSelfAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "allowMuteSelfAllowed=$AllowMuteSelfAllowed"
        $modifiers++
    }

    if ($VideoMuteSelfAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "videoMuteSelfAllowed=$VideoMuteSelfAllowed"
        $modifiers++
    }

    if ($ChangeLayoutAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "changeLayoutAllowed=$ChangeLayoutAllowed"
        $modifiers++
    }

    if ($ParticipantLabels -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "participantLabels=$ParticipantLabels"
        $modifiers++
    }

    if ($PresentationDisplayMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "presentationDisplayMode=$PresentationDisplayMode"
        $modifiers++
    }

    if ($PresentationContributionAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "presentationContributionAllowed=$PresentationContributionAllowed"
        $modifiers++
    }

    if ($PresentationViewingAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "presentationViewingAllowed=$PresentationViewingAllowed"
        $modifiers++
    }

    if ($JoinToneParticipantThreshold -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "joinToneParticipantThreshold=$JoinToneParticipantThreshold"
        $modifiers++
    }

    if ($LeaveToneParticipantThreshold -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "leaveToneParticipantThreshold=$LeaveToneParticipantThreshold"
        $modifiers++
    }

    if ($VideoMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "videoMode=$VideoMode"
        $modifiers++
    }

    if ($RxAudioMute -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "rxAudioMute=$RxAudioMute"
        $modifiers++
    }

    if ($TxAudioMute -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "txAudioMute=$TxAudioMute"
        $modifiers++
    }

    if ($RxVideoMute -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "rxVideoMute=$RxVideoMute"
        $modifiers++
    }

    if ($TxVideoMute -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "txVideoMute=$TxVideoMute"
        $modifiers++
    }

    if ($SipMediaEncryption -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "sipMediaEncryption=$SipMediaEncryption"
        $modifiers++
    }

    if ($AudioPacketSizeMs -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "audioPacketSizeMs=$AudioPacketSizeMs"
        $modifiers++
    }

    if ($DeactivationMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "deactivationMode=$DeactivationMode"
        $modifiers++
    }

    if ($DeactivationModeTime -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "deactivationModeTime=$DeactivationModeTime"
        $modifiers++
    }

    if ($TelepresenceCallsAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "telepresenceCallsAllowed=$TelepresenceCallsAllowed"
        $modifiers++
    }

    if ($SipPresentationChannelEnabled -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "sipPresentationChannelEnabled=$SipPresentationChannelEnabled"
        $modifiers++
    }

    if ($BfcpMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "bfcpMode=$BfcpMode"
        $modifiers++
    }

    if ($RecordingControlAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "recordingControlAllowed=$RecordingControlAllowed"
        $modifiers++
    }

    if ($Name -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "name=$Name"
        $modifiers++
    }

    if ($MaxCallDurationTime -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "maxCallDurationTime=$MaxCallDurationTime"
        $modifiers++
    }

    if ($CallLockAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callLockAllowed=$CallLockAllowed"
    }

    [string]$NewCallLegProfileId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsCallLegProfile $NewCallLegProfileId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsCallLegProfile {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$NeedsActivation,
        [parameter(Mandatory=$false)]
        [ValidateSet("allEqual","speakerOnly","telepresence","stacked","allEqualQuarters","allEqualNinths","allEqualSixteenths","allEqualTwentyFifths","onePlusFive","onePlusSeven","onePlusNine","onePlusN","automatic")]
        [string]$DefaultLayout,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$EndCallAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$MuteOthersAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$VideoMuteOthersAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$MuteSelfAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$AllowMuteSelfAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$VideoMuteSelfAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ChangeLayoutAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ParticipantLabels,
        [parameter(Mandatory=$false)]
        [ValidateSet("dualStream","singleStream")]
        [string]$PresentationDisplayMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$PresentationContributionAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$PresentationViewingAllowed,
        [parameter(Mandatory=$false)]
        [string]$JoinToneParticipantThreshold,
        [parameter(Mandatory=$false)]
        [string]$LeaveToneParticipantThreshold,
        [parameter(Mandatory=$false)]
        [ValidateSet("auto","disabled")]
        [string]$VideoMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RxAudioMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TxAudioMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RxVideoMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TxVideoMute,
        [parameter(Mandatory=$false)]
        [ValidateSet("optional","required","prohibited")]
        [string]$SipMediaEncryption,
        [parameter(Mandatory=$false)]
        [string]$AudioPacketSizeMs,
        [parameter(Mandatory=$false)]
        [ValidateSet("deactivate","disconnect","remainActivated")]
        [string]$DeactivationMode,
        [parameter(Mandatory=$false)]
        [string]$DeactivationModeTime,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$TelepresenceCallsAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$SipPresentationChannelEnabled,
        [parameter(Mandatory=$false)]
        [ValidateSet("serverOnly","serverAndClient")]
        [string]$BfcpMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CallLockAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$RecordingControlAllowed,
        [parameter(Mandatory=$false)]
        [string]$Name,
        [parameter(Mandatory=$false)]
        [string]$MaxCallDurationTime
    )

    $nodeLocation = "/api/v1/callLegProfiles/$Identity"
    $data = ""
    $modifiers = 0

    if ($NeedsActivation -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "needsActivation=$NeedsActivation"
        $modifiers++
    }

    if ($DefaultLayout -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "defaultLayout=$DefaultLayout"
        $modifiers++
    }

    if ($EndCallAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "endCallAllowed=$EndCallAllowed"
        $modifiers++
    }

    if ($MuteOthersAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteOthersAllowed=$MuteOthersAllowed"
        $modifiers++
    }

    if ($VideoMuteOthersAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "videoMuteOthersAllowed=$VideoMuteOthersAllowed"
        $modifiers++
    }

    if ($MuteSelfAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteSelfAllowed=$MuteSelfAllowed"
        $modifiers++
    }

    if ($AllowMuteSelfAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "allowMuteSelfAllowed=$AllowMuteSelfAllowed"
        $modifiers++
    }

    if ($VideoMuteSelfAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "videoMuteSelfAllowed=$VideoMuteSelfAllowed"
        $modifiers++
    }

    if ($ChangeLayoutAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "changeLayoutAllowed=$ChangeLayoutAllowed"
        $modifiers++
    }

    if ($ParticipantLabels -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "participantLabels=$ParticipantLabels"
        $modifiers++
    }

    if ($PresentationDisplayMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "presentationDisplayMode=$PresentationDisplayMode"
        $modifiers++
    }

    if ($PresentationContributionAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "presentationContributionAllowed=$PresentationContributionAllowed"
        $modifiers++
    }

    if ($PresentationViewingAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "presentationViewingAllowed=$PresentationViewingAllowed"
        $modifiers++
    }

    if ($JoinToneParticipantThreshold -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "joinToneParticipantThreshold=$JoinToneParticipantThreshold"
        $modifiers++
    }

    if ($LeaveToneParticipantThreshold -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "leaveToneParticipantThreshold=$LeaveToneParticipantThreshold"
        $modifiers++
    }

    if ($VideoMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "videoMode=$VideoMode"
        $modifiers++
    }

    if ($RxAudioMute -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "rxAudioMute=$RxAudioMute"
        $modifiers++
    }

    if ($TxAudioMute -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "txAudioMute=$TxAudioMute"
        $modifiers++
    }

    if ($RxVideoMute -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "rxVideoMute=$RxVideoMute"
        $modifiers++
    }

    if ($TxVideoMute -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "txVideoMute=$TxVideoMute"
        $modifiers++
    }

    if ($SipMediaEncryption -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "sipMediaEncryption=$SipMediaEncryption"
        $modifiers++
    }

    if ($AudioPacketSizeMs -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "audioPacketSizeMs=$AudioPacketSizeMs"
        $modifiers++
    }

    if ($DeactivationMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "deactivationMode=$DeactivationMode"
        $modifiers++
    }

    if ($DeactivationModeTime -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "deactivationModeTime=$DeactivationModeTime"
        $modifiers++
    }

    if ($TelepresenceCallsAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "telepresenceCallsAllowed=$TelepresenceCallsAllowed"
        $modifiers++
    }

    if ($SipPresentationChannelEnabled -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "sipPresentationChannelEnabled=$SipPresentationChannelEnabled"
        $modifiers++
    }

    if ($BfcpMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "bfcpMode=$BfcpMode"
        $modifiers++
    }

    if ($RecordingControlAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "recordingControlAllowed=$RecordingControlAllowed"
        $modifiers++
    }

    if ($Name -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "name=$Name"
        $modifiers++
    }

    if ($MaxCallDurationTime -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "maxCallDurationTime=$MaxCallDurationTime"
        $modifiers++
    }

    if ($CallLockAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callLockAllowed=$CallLockAllowed"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsCallLegProfile $Identity
}

function Remove-CmsCallLegProfile {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove call leg profile")) {
        Open-CmsAPI "/api/v1/callLegProfiles/$Identity" -DELETE
    }
}

function Get-CmsCallLegProfileUsages {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    return (Open-CmsAPI "api/v1/callLegProfiles/$Identity/usage").callLegProfileUsage

}

function Get-CmsCallLegProfileTrace {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    return (Open-CmsAPI "api/v1/callLegs/$Identity/callLegProfileTrace").callLegProfileTrace

}

function Get-CmsDialTransforms {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/dialTransforms"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "?limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).dialTransforms.dialTransform
}

function Get-CmsDialTransform {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsDialTransforms
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/dialTransforms/$Identity").dialTransform
        }
    }
}

function New-CmsDialTransform {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateSet("raw","strip","phone")]
        [string]$Type="raw",
        [parameter(Mandatory=$false)]
        [string]$Match,
        [parameter(Mandatory=$false)]
        [string]$Transform,
        [parameter(Mandatory=$false)]
        [string]$Priority,
        [parameter(Mandatory=$false)]
        [ValidateSet("accept","acceptPhone","deny")]
        [string]$Action
    )

    $nodeLocation = "/api/v1/dialTransforms"
    $data = "type=$type"

    if ($Match -ne "") {
        $data += "&match=$Match"
    }

    if ($Transform -ne "") {
        $data += "&transform=$Transform"
    }

    if ($Priority -ne "") {
        $data += "&priority=$Priority"
    }

    if ($Action -ne "") {
        $data += "&Action=$Action"
    }

    $data

    [string]$NewDialTransformId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsDialTransform $NewDialTransformId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsDialTransform {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [ValidateSet("raw","strip","phone")]
        [string]$Type,
        [parameter(Mandatory=$false)]
        [string]$Match,
        [parameter(Mandatory=$false)]
        [string]$Transform,
        [parameter(Mandatory=$false)]
        [string]$Priority,
        [parameter(Mandatory=$false)]
        [ValidateSet("accept","acceptPhone","deny")]
        [string]$Action
    )

    $nodeLocation = "/api/v1/dialTransforms/$Identity"
    $data = ""
    $modifiers = 0
    

    if ($Type -ne "") {
        $data = "type=$Type"
        $modifiers++
    }

    if ($Match -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "match=$Match"
        $modifiers++
    }

    if ($Transform -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "transform=$Transform"
        $modifiers++
    }

    if ($Priority -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "priority=$Priority"
        $modifiers++
    }

    if ($Action -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "Action=$Action"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsDialTransform $Identity
}

function Remove-CmsDialTransform {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove dial transform rule")) {
        Open-CmsAPI "/api/v1/dialTransforms/$Identity" -DELETE
    }
}

function Get-CmsCallBrandingProfiles {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [ValidateSet("unreferenced","referenced","")]
        [string]$UsageFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/callBrandingProfiles"


    $modifiers = 0

    if ($UsageFilter -ne "") {
        $nodeLocation += "?usageFilter=$UsageFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "?limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).callBrandingProfiles.callBrandingProfile
}

function Get-CmsCallBrandingProfile {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsCallBrandingProfiles
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/callBrandingProfiles/$Identity").callBrandingProfile
        }
    }
}

function New-CmsCallBrandingProfile {
    Param (
        [parameter(Mandatory=$false)]
        [string]$InvitationTemplate,
        [parameter(Mandatory=$false)]
        [string]$ResourceLocation
    )

    $nodeLocation = "/api/v1/callBrandingProfiles"
    $data = ""
    $modifiers = 0

    if ($InvitationTemplate -ne "") {
        $data += "invitationTemplate=$InvitationTemplate"
        $modifiers++
    }

    if ($ResourceLocation -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resourceLocation=$ResourceLocation"
    }

    [string]$NewCallBrandingProfileId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsCallBrandingProfile $NewCallBrandingProfileId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsCallBrandingProfile {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$InvitationTemplate,
        [parameter(Mandatory=$false)]
        [string]$ResourceLocation
    )

    $nodeLocation = "/api/v1/callBrandingProfiles/$Identity"
    $data = ""
    $modifiers = 0

    if ($InvitationTemplate -ne "") {
        $data += "invitationTemplate=$InvitationTemplate"
        $modifiers++
    }

    if ($ResourceLocation -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resourceLocation=$ResourceLocation"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsCallBrandingProfile $Identity
}

function Remove-CmsCallBrandingProfile {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove call branding profile")) {
        Open-CmsAPI "/api/v1/CallBrandingProfiles/$Identity" -DELETE
    }
}

function Get-CmsDtmfProfiles {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [ValidateSet("unreferenced","referenced","")]
        [string]$UsageFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/dtmfProfiles"


    $modifiers = 0

    if ($UsageFilter -ne "") {
        $nodeLocation += "?usageFilter=$UsageFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "?limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).dtmfProfiles.dtmfProfile
}

function Get-CmsDtmfProfile {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsDtmfProfiles
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/dtmfProfiles/$Identity").dtmfProfile
        }
    }
}

function New-CmsDtmfProfile {
    Param (
        [parameter(Mandatory=$false)]
        [string]$LockCall,
        [parameter(Mandatory=$false)]
        [string]$UnlockCall,
        [parameter(Mandatory=$false)]
        [string]$NextLayout,
        [parameter(Mandatory=$false)]
        [string]$PreviousLayout,
        [parameter(Mandatory=$false)]
        [string]$MuteSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$UnmuteSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$ToggleMuteSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$MuteAllExceptSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$UnMuteAllExceptSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$StartRecording,
        [parameter(Mandatory=$false)]
        [string]$StopRecording,
        [parameter(Mandatory=$false)]
        [string]$AllowAllMuteSelf,
        [parameter(Mandatory=$false)]
        [string]$CancelAllowAllMuteSelf,
        [parameter(Mandatory=$false)]
        [string]$AllowAllPresentationContribution,
        [parameter(Mandatory=$false)]
        [string]$CancelAllowAllPresentationContribution,
        [parameter(Mandatory=$false)]
        [string]$MuteAllNewAudio,
        [parameter(Mandatory=$false)]
        [string]$UnMuteAllNewAudio,
        [parameter(Mandatory=$false)]
        [string]$DefaultMuteAllNewAudio,
        [parameter(Mandatory=$false)]
        [string]$MuteAllNewAndAllExceptSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$UnMuteAllNewAndAllExceptSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$EndCall
    )

    $nodeLocation = "/api/v1/dtmfProfiles"
    $data = ""
    $modifiers = 0

    if ($LockCall -ne "") {
        $data += "lockCall=$LockCall"
        $modifiers++
    }

    if ($UnlockCall -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "unlockCall=$UnlockCall"
        $modifiers++
    }

    if ($NextLayout -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "nextLayout=$NextLayout"
        $modifiers++
    }

    if ($PreviousLayout -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "previousLayout=$PreviousLayout"
        $modifiers++
    }

    if ($MuteSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteSelfAudio=$MuteSelfAudio"
        $modifiers++
    }

    if ($UnMuteSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "unmuteSelfAudio=$UnMuteSelfAudio"
        $modifiers++
    }

    if ($ToggleMuteSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "toggleMuteSelfAudio=$ToggleMuteSelfAudio"
        $modifiers++
    }

    if ($MuteAllExceptSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteAllExceptSelfAudio=$MuteAllExceptSelfAudio"
        $modifiers++
    }

    if ($UnMuteAllExceptSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "unmuteAllExceptSelfAudio=$UnMuteAllExceptSelfAudio"
        $modifiers++
    }

    if ($StartRecording -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "startRecording=$StartRecording"
        $modifiers++
    }

    if ($StopRecording -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "stopRecording=$StopRecording"
        $modifiers++
    }

    if ($AllowAllMuteSelf -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "allowAllMuteSelf=$AllowAllMuteSelf"
        $modifiers++
    }

    if ($CancelAllowAllMuteSelf -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "cancelAllowAllMuteSelf=$CancelAllowAllMuteSelf"
        $modifiers++
    }

    if ($AllowAllPresentationContribution -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "allowAllPresentationContribution=$AllowAllPresentationContribution"
        $modifiers++
    }

    if ($CancelAllowAllPresentationContribution -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "cancelAllowAllPresentationContribution=$CancelAllowAllPresentationContribution"
        $modifiers++
    }

    if ($MuteAllNewAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteAllNewAudio=$MuteAllNewAudio"
        $modifiers++
    }

    if ($UnMuteAllNewAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "unmuteAllNewAudio=$UnMuteAllNewAudio"
        $modifiers++
    }

    if ($MuteAllNewAndAllExceptSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteAllNewAndAllExceptSelfAudio=$MuteAllNewAndAllExceptSelfAudio"
        $modifiers++
    }

    if ($UnMuteAllNewAndAllExceptSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "unmuteAllNewAndAllExceptSelfAudio=$UnMuteAllNewAndAllExceptSelfAudio"
        $modifiers++
    }

    if ($EndCall -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "endCall=$EndCall"
    }

    [string]$NewDtmfProfileId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsDtmfProfile $NewDtmfProfileId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsDtmfProfile {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$LockCall,
        [parameter(Mandatory=$false)]
        [string]$UnlockCall,
        [parameter(Mandatory=$false)]
        [string]$NextLayout,
        [parameter(Mandatory=$false)]
        [string]$PreviousLayout,
        [parameter(Mandatory=$false)]
        [string]$MuteSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$UnmuteSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$ToggleMuteSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$MuteAllExceptSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$UnMuteAllExceptSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$StartRecording,
        [parameter(Mandatory=$false)]
        [string]$StopRecording,
        [parameter(Mandatory=$false)]
        [string]$AllowAllMuteSelf,
        [parameter(Mandatory=$false)]
        [string]$CancelAllowAllMuteSelf,
        [parameter(Mandatory=$false)]
        [string]$AllowAllPresentationContribution,
        [parameter(Mandatory=$false)]
        [string]$CancelAllowAllPresentationContribution,
        [parameter(Mandatory=$false)]
        [string]$MuteAllNewAudio,
        [parameter(Mandatory=$false)]
        [string]$UnMuteAllNewAudio,
        [parameter(Mandatory=$false)]
        [string]$DefaultMuteAllNewAudio,
        [parameter(Mandatory=$false)]
        [string]$MuteAllNewAndAllExceptSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$UnMuteAllNewAndAllExceptSelfAudio,
        [parameter(Mandatory=$false)]
        [string]$EndCall
    )

    $nodeLocation = "/api/v1/dtmfProfiles/$Identity"
    $data = ""
    $modifiers = 0

    if ($LockCall -ne "") {
        $data += "lockCall=$LockCall"
        $modifiers++
    }

    if ($UnlockCall -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "unlockCall=$UnlockCall"
        $modifiers++
    }

    if ($NextLayout -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "nextLayout=$NextLayout"
        $modifiers++
    }

    if ($PreviousLayout -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "previousLayout=$PreviousLayout"
        $modifiers++
    }

    if ($MuteSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteSelfAudio=$MuteSelfAudio"
        $modifiers++
    }

    if ($UnMuteSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "unmuteSelfAudio=$UnMuteSelfAudio"
        $modifiers++
    }

    if ($ToggleMuteSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "toggleMuteSelfAudio=$ToggleMuteSelfAudio"
        $modifiers++
    }

    if ($MuteAllExceptSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteAllExceptSelfAudio=$MuteAllExceptSelfAudio"
        $modifiers++
    }

    if ($UnMuteAllExceptSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "unmuteAllExceptSelfAudio=$UnMuteAllExceptSelfAudio"
        $modifiers++
    }

    if ($StartRecording -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "startRecording=$StartRecording"
        $modifiers++
    }

    if ($StopRecording -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "stopRecording=$StopRecording"
        $modifiers++
    }

    if ($AllowAllMuteSelf -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "allowAllMuteSelf=$UnMuteAllEAllowAllMuteSelfxceptSelfAudio"
        $modifiers++
    }

    if ($CancelAllowAllMuteSelf -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "cancelAllowAllMuteSelf=$CancelAllowAllMuteSelf"
        $modifiers++
    }

    if ($AllowAllPresentationContribution -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "allowAllPresentationContribution=$AllowAllPresentationContribution"
        $modifiers++
    }

    if ($CancelAllowAllPresentationContribution -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "cancelAllowAllPresentationContribution=$CancelAllowAllPresentationContribution"
        $modifiers++
    }

    if ($MuteAllNewAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteAllNewAudio=$MuteAllNewAudio"
        $modifiers++
    }

    if ($UnMuteAllNewAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "unmuteAllNewAudio=$UnMuteAllNewAudio"
        $modifiers++
    }

    if ($MuteAllNewAndAllExceptSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "muteAllNewAndAllExceptSelfAudio=$MuteAllNewAndAllExceptSelfAudio"
        $modifiers++
    }

    if ($UnMuteAllNewAndAllExceptSelfAudio -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "unmuteAllNewAndAllExceptSelfAudio=$UnMuteAllNewAndAllExceptSelfAudio"
        $modifiers++
    }

    if ($EndCall -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "endCall=$EndCall"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsDtmfProfile $Identity
}

function Remove-CmsDtmfProfile {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove DTMF profile")) {
        Open-CmsAPI "/api/v1/dtmfProfiles/$Identity" -DELETE
    }
}

function Get-CmsIvrs {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$TenantFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/ivrs"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($TenantFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "tenantFilter=$TenantFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).ivrs.ivr
}

function Get-CmsIvr {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsIvrs
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/ivrs/$Identity").ivr
        }
    }
}

function New-CmsIvr {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Uri,
        [parameter(Mandatory=$false)]
        [string]$Tenant,
        [parameter(Mandatory=$false)]
        [string]$TenantGroup,
        [parameter(Mandatory=$false)]
        [string]$IvrBrandingProfile,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveCoSpaceCallIds,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveLyncConferenceIds
    )

    $nodeLocation = "/api/v1/ivrs"
    $data = "uri=$Uri"

    if ($Tenant -ne "") {
        $data += "&tenant=$Tenant"
    }

    if ($TenantGroup -ne "") {
        $data += "&tenantgroup=$TenantGroup"
    }

    if ($IvrBrandingProfile -ne "") {
        $data += "&ivrBrandingProfile=$IvrBrandingProfile"
    }

    if ($ResolveCoSpaceCallIds -ne "") {
        $data += "&resolveCoSpaceCallIds=$ResolveCoSpaceCallIds"
    }

    if ($ResolveLyncConferenceIds -ne "") {
        $data += "&reesolveLyncConferenceIds=$ResolveLyncConferenceIds"
    }

    [string]$NewIvrId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsIvr $NewIvrId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsIvr {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$Uri,
        [parameter(Mandatory=$false)]
        [string]$Tenant,
        [parameter(Mandatory=$false)]
        [string]$TenantGroup,
        [parameter(Mandatory=$false)]
        [string]$IvrBrandingProfile,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveCoSpaceCallIds,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveLyncConferenceIds
    )

    $nodeLocation = "/api/v1/ivrs/$Identity"
    $data = ""
    $modifiers = 0

    if ($Uri -ne "") {
        $data += "uri=$Uri"
        $modifiers++
    }

    if ($Tenant -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "tenant=$Tenant"
        $modifiers++
    }

    if ($TenantGroup -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "tenantGroup=$TenantGroup"
        $modifiers++
    }

    if ($IvrBrandingProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "ivrBrandingProfile=$IvrBrandingProfile"
        $modifiers++
    }

    if ($ResolveCoSpaceCallIds -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resolveCoSpaceCallIds=$ResolveCoSpaceCallIds"
        $modifiers++
    }

    if ($ResolveLyncConferenceIds -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resolveLyncConferenceIds=$ResolveLyncConferenceIds"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsIvr $Identity
}

function Remove-CmsIvr {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove IVR")) {
        Open-CmsAPI "/api/v1/ivrs/$Identity" -DELETE
    }
}

function Get-CmsIvrBrandingProfiles {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$TenantFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/ivrBrandingProfiles"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($TenantFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "tenantFilter=$TenantFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).ivrBrandingProfiles.ivrBrandingProfile
}

function Get-CmsIvrBrandingProfile {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsIvrBrandingProfiles
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/ivrBrandingProfiles/$Identity").ivrBrandingProfile
        }
    }
}

function New-CmsIvrBrandingProfile {
    Param (
        [parameter(Mandatory=$false)]
        [string]$ResourceLocation
    )

    $nodeLocation = "/api/v1/ivrBrandingProfiles"
    $data = ""

    if ($ResourceLocation -ne "") {
        $data += "resourceLocation=$ResourceLocation"
    }

    [string]$NewIvrBrandingProfileId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsIvrBrandingProfile $NewIvrBrandingProfileId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsIvrBrandingProfile {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$ResourceLocation
    )

    $nodeLocation = "/api/v1/ivrBrandingProfiles/$Identity"
    $data = ""

    if ($ResourceLocation -ne "") {
        $data += "resourceLocation=$ResourceLocation"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsIvrBrandingProfile $Identity
}

function Remove-CmsIvrBrandingProfile {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove IVR Branding profile")) {
        Open-CmsAPI "/api/v1/ivrBrandingProfiles/$Identity" -DELETE
    }
}

function Get-CmsParticipants {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$TenantFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$callBridgeFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/participants"

    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($TenantFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "tenantFilter=$TenantFilter"
        $modifiers++
    }

    if ($CallBridgeFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "callBridgeFilter=$CallBridgeFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).participants.participant
}

function Get-CmsParticipant {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsParticipants
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/participants/$Identity").participant
        }
    }
}

function Get-CmsParticipantCallLegs {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    return (Open-CmsAPI "api/v1/participants/$Identity/callLegs").callLeg

}

function Get-CmsUsers {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$TenantFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/users"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($TenantFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "tenantFilter=$TenantFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).users.user
}

function Get-CmsUser {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsUsers
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/users/$Identity").user
        }
    }
}

function Get-CmsUsercoSpaces {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    return (Open-CmsAPI "api/v1/users/$Identity/usercoSpaces").userCoSpaces.userCoSpace

}

function Get-CmsUserProfiles {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [ValidateSet("unreferenced","referenced","")]
        [string]$UsageFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/userProfiles"


    $modifiers = 0

    if ($UsageFilter -ne "") {
        $nodeLocation += "?usageFilter=$UsageFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).userProfiles.userProfile
}

function Get-CmsUserProfile {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsUserProfiles
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/userProfiles/$Identity").userProfile
        }
    }
}

function New-CmsUserProfile {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$canCreateCoSpaces,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanCreateCalls,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanUseExternalDevices,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanMakePhoneCalls,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$UserToUserMessagingAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$HasLicense,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$AudioParticipationAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$VideoParticipationAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$PresentationParticipationAllowed
    )

    $nodeLocation = "/api/v1/userProfiles"
    $data = ""
    $modifiers = 0

    if ($canCreateCoSpaces -ne "") {
        $data += "canCreateCoSpaces=$canCreateCoSpaces"
        $modifiers++
    }

    if ($CanCreateCalls -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canCreateCalls=$canCreateCalls"
        $modifiers++
    }

    if ($CanUseExternalDevices -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canUseExternalDevices=$CanUseExternalDevices"
        $modifiers++
    }

    if ($CanMakePhoneCalls -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canMakePhoneCalls=$CanMakePhoneCalls"
        $modifiers++
    }

    if ($UserToUserMessagingAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "userToUserMessagingAllowed=$UserToUserMessagingAllowed"
        $modifiers++
    }

    if ($HasLicense -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "hasLicense=$HasLicense"
        $modifiers++
    }
        
    if ($AudioParticipationAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "audioParticipationAllowed=$AudioParticipationAllowed"
        $modifiers++
    }

    if ($VideoParticipationAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "videoParticipationAllowed=$VideoParticipationAllowed"
        $modifiers++
    }

    if ($PresentationParticipationAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "presentationParticipationAllowed=$PresentationParticipationAllowed"
    }

    [string]$NewUserProfileId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsUserProfile $NewUserProfileId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsUserProfile {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$canCreateCoSpaces,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanCreateCalls,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanUseExternalDevices,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$CanMakePhoneCalls,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$UserToUserMessagingAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$HasLicense,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$AudioParticipationAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$VideoParticipationAllowed,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$PresentationParticipationAllowed
    )

    $nodeLocation = "/api/v1/userProfiles/$Identity"
    $data = ""
    $modifiers = 0

    if ($canCreateCoSpaces -ne "") {
        $data += "canCreateCoSpaces=$canCreateCoSpaces"
        $modifiers++
    }

    if ($CanCreateCalls -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canCreateCalls=$canCreateCalls"
        $modifiers++
    }

    if ($CanUseExternalDevices -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canUseExternalDevices=$CanUseExternalDevices"
        $modifiers++
    }

    if ($CanMakePhoneCalls -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "canMakePhoneCalls=$CanMakePhoneCalls"
        $modifiers++
    }

    if ($UserToUserMessagingAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "userToUserMessagingAllowed=$UserToUserMessagingAllowed"
        $modifiers++
    }

    if ($AudioParticipationAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "audioParticipationAllowed=$AudioParticipationAllowed"
        $modifiers++
    }

    if ($VideoParticipationAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "videoParticipationAllowed=$VideoParticipationAllowed"
        $modifiers++
    }

    if ($PresentationParticipationAllowed -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "presentationParticipationAllowed=$PresentationParticipationAllowed"
        $modifiers++
    }

    if ($HasLicense -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "hasLicense=$HasLicense"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsUserProfile $Identity
}

function Remove-CmsUserProfile {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove user profile")) {
        Open-CmsAPI "/api/v1/userProfiles/$Identity" -DELETE
    }
}

function Get-CmsSystemStatus {
    return (Open-CmsAPI "api/v1/system/status").status
}


function Get-CmsSystemAlarms {
    return (Open-CmsAPI "api/v1/system/alarms").alarms.alarm
}


function Get-CmsSystemAlarm {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    return (Open-CmsAPI "api/v1/system/alarms/$Identity").alarm
}

function Get-CmsSystemDatabaseStatus {
    return (Open-CmsAPI "api/v1/system/database").database
}

function Get-CmsCdrRecieverUris {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/system/cdrRecievers"
    $modifiers = 0

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).cdrRecievers.cdrReciever
}

function Get-CmsCdrRecieverUri {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsCdrRecieverUris
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/system/cdrRecievers/$Identity").cdrReciever
        }
    }
}

function New-CmsCdrRecieverUri {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Uri
    )

    $nodeLocation = "/api/v1/system/cdrRecievers"
    $data = "uri=$Uri"

    [string]$NewCdrRecieverUriId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsCdrRecieverUri $NewCdrRecieverUriId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsCdrRecieverUri {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$Uri
    )

    $nodeLocation = "/api/v1/system/cdrRecievers/$Identity"
    $data = ""

    if ($Uri -ne "") {
        $data += "uri=$Uri"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsCdrRecieverUri $Identity
}

function Remove-CmsCdrRecieverUri {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove CDR reciever")) {
        Open-CmsAPI "/api/v1/system/cdrRecievers/$Identity" -DELETE
    }
}

function Get-CmsLegacyCdrReceiverUri {
    return (Open-CmsAPI "api/v1/system/cdrReceiver").cdrReceiver
}

function Set-CmsLegacyCdrRecieverUri {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
     Param (
        [parameter(Mandatory=$false,Position=1)]
        [string]$Uri
    )

    $nodeLocation = "/api/v1/system/cdrReciever"
    $data = ""

    if ($Uri -ne "") {
        $data += "&uri=$Uri"
        
        [string]$NewCdrRecieverUri = Open-CmsAPI $nodeLocation -POST -Data $data
    } 
    
    else {
        if ($PSCmdlet.ShouldProcess("Legacy CDR Reciever","Remove")) {
            Open-CmsAPI $nodeLocation -PUT -Data $data
        }
    }

    Get-CmsLegacyCdrReceiverUri
}

function Remove-CmsLegacyCdrRecieverUri {
    ##Triggers a PUT on Set-CmsLegacyCdrRecieverUri, which effectively removes the CDR reciever.
    Set-CmsLegacyCdrRecieverUri
}

function Get-CmsGlobalProfile {
    return (Open-CmsAPI "api/v1/system/profiles").profiles
}

function Set-CmsGlobalProfile {
    Param (
        [parameter(Mandatory=$false)]
        [string]$CallLegProfile,
        [parameter(Mandatory=$false)]
        [string]$CallProfile,
        [parameter(Mandatory=$false)]
        [string]$DtmfProfile,
        [parameter(Mandatory=$false)]
        [string]$UserProfile,
        [parameter(Mandatory=$false)]
        [string]$IvrBrandingProfile,
        [parameter(Mandatory=$false)]
        [string]$CallBrandingProfile
    )

    $nodeLocation = "/api/v1/system/profiles"
    $data = ""
    $modifiers = 0

    if ($CallLegProfile -ne "") {
        if ($CallLegProfile -eq $null){
            $data += "callLegProfile="
        }
        else {
            $data += "callLegProfile=$CallLegProfile"
        }
        $modifiers++
    }

    if ($CallProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }

        if ($CallProfile -eq $null){
            $data += "callProfile="
        }
        else {
            $data += "callProfile=$CallProfile"
        }

        $modifiers++
    }

    if ($DtmfProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }

        if ($DtmfProfile -eq $null){
            $data += "dtmfProfile="
        }
        else {
            $data += "dtmfProfile=$DtmfProfile"
        }

        $modifiers++
    }

    if ($UserProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }

        if ($UserProfile -eq $null){
            $data += "userProfile="
        }
        else {
            $data += "userProfile=$UserProfile"
        }

        $modifiers++
    }

    if ($IvrBrandingProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }

        if ($IvrBrandingProfile -eq $null){
            $data += "ivrBrandingProfile="
        }
        else {
            $data += "ivrBrandingProfile=$IvrBrandingProfile"
        }

        $modifiers++
    }

    if ($CallBrandingProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }

        if ($CallBrandingProfile -eq $null){
            $data += "callBrandingProfile="
        }
        else {
            $data += "callBrandingProfile=$CallBrandingProfile"
        }
    }
    $data

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsGlobalProfile
}

function Get-CmsTurnServers {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/turnServers"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }
    
    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).turnServers.turnServer
}

function Get-CmsTurnServer {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsTurnServers
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/turnServers/$Identity").turnServer
        }
    }
}

function Get-CmsTurnServerStatus {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    return (Open-CmsAPI "api/v1/turnServers/$Identity/status").turnServer.host
}

function New-CmsTurnServer {
    Param (
        [parameter(Mandatory=$false)]
        [string]$ServerAddress,
        [parameter(Mandatory=$false)]
        [string]$ClientAddress,
        [parameter(Mandatory=$false)]
        [string]$Username,
        [parameter(Mandatory=$false)]
        [string]$Password,
        [parameter(Mandatory=$false)]
        [ValidateSet("Cms","lyncEdge","standard")]
        [string]$Type,
        [parameter(Mandatory=$false)]
        [string]$NumRegistrations,
        [parameter(Mandatory=$false)]
        [string]$TcpPortNumberOverride
    )

    $nodeLocation = "/api/v1/turnServers"
    $data = ""
    $modifiers = 0

    if ($ServerAddress -ne "") {
        $data += "serverAddress=$ServerAddress"
        $modifiers++
    }

    if ($ClientAddress -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "clientAddress=$ClientAddress"
        $modifiers++
    }

    if ($Username -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "username=$Username"
        $modifiers++
    }

    if ($Password -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "password=$Password"
        $modifiers++
    }

    if ($Type -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "type=$Type"
        $modifiers++
    }

    if ($NumRegistrations -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "numRegistrations=$NumRegistrations"
        $modifiers++
    }

    if ($TcpPortNumberOverride -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "tcpPortNumberOverride=$TcpPortNumberOverride"
    }

    [string]$NewTurnServerId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsTurnServer $NewTurnServerId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsTurnServer {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$ServerAddress,
        [parameter(Mandatory=$false)]
        [string]$ClientAddress,
        [parameter(Mandatory=$false)]
        [string]$Username,
        [parameter(Mandatory=$false)]
        [string]$Password,
        [parameter(Mandatory=$false)]
        [ValidateSet("Cms","lyncEdge","standard")]
        [string]$Type,
        [parameter(Mandatory=$false)]
        [string]$NumRegistrations,
        [parameter(Mandatory=$false)]
        [string]$TcpPortNumberOverride
    )

    $nodeLocation = "/api/v1/turnServers/$Identity"
    $data = ""
    $modifiers = 0

    if ($ServerAddress -ne "") {
        $data += "serverAddress=$ServerAddress"
        $modifiers++
    }

    if ($ClientAddress -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "clientAddress=$ClientAddress"
        $modifiers++
    }

    if ($Username -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "username=$Username"
        $modifiers++
    }

    if ($Password -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "password=$Password"
        $modifiers++
    }

    if ($Type -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "type=$Type"
        $modifiers++
    }

    if ($NumRegistrations -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "numRegistrations=$NumRegistrations"
        $modifiers++
    }

    if ($TcpPortNumberOverride -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "tcpPortNumberOverride=$TcpPortNumberOverride"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsTurnServer $Identity
}

function Remove-CmsTurnServer {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove TURN server")) {
        Open-CmsAPI "/api/v1/turnServers/$Identity" -DELETE
    }
}

function Get-CmsWebBridges {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$TenantFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/webBridges"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($TenantFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "tenantFilter=$TenantFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).webBridges.webBridge
}

function Get-CmsWebBridge {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsWebBridges
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/webBridges/$Identity").webBridge
        }
    }
}

function New-CmsWebBridge {
    Param (
        [parameter(Mandatory=$false)]
        [string]$Url,
        [parameter(Mandatory=$false)]
        [string]$ResourceArchive,
        [parameter(Mandatory=$false)]
        [string]$Tenant,
        [parameter(Mandatory=$false)]
        [string]$TenantGroup,
        [parameter(Mandatory=$false)]
        [ValidateSet("disabled","secure","legacy")]
        [string]$IdEntryMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$AllowWebLinkAccess,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ShowSignIn,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveCoSpaceCallIds,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveLyncConferenceIds
    )

    $nodeLocation = "/api/v1/webBridges"
    $data = ""
    $modifiers = 0

    if ($Url -ne "") {
        $data += "url=$Url"
        $modifiers++
    }

    if ($ResourceArchive -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resourceArchive=$ResourceArchive"
        $modifiers++
    }

    if ($Tenant -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "tenant=$Tenant"
        $modifiers++
    }

    if ($TenantGroup -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "tenantGroup=$TenantGroup"
        $modifiers++
    }

    if ($IdEntryMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "idEntryMode=$IdEntryMode"
        $modifiers++
    }

    if ($AllowWebLinkAccess -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "allowWebLinkAccess=$AllowWebLinkAccess"
        $modifiers++
    }

    if ($ShowSignIn -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }

        $data += "showSignIn=$ShowSignIn"
        $modifiers++
    }

    if ($ResolveCoSpaceCallIds -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resolveCoSpaceCallIds=$ResolveCoSpaceCallIds"
        $modifiers++
    }

    if ($ResolveLyncConferenceIds -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resolveLyncConferenceIds=$ResolveLyncConferenceIds"
    }

    [string]$NewWebBridgeId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsWebBridge $NewWebBridgeId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsWebBridge {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$Url,
        [parameter(Mandatory=$false)]
        [string]$ResourceArchive,
        [parameter(Mandatory=$false)]
        [string]$Tenant,
        [parameter(Mandatory=$false)]
        [string]$TenantGroup,
        [parameter(Mandatory=$false)]
        [ValidateSet("disabled","secure","legacy")]
        [string]$IdEntryMode,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$AllowWebLinkAccess,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ShowSignIn,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveCoSpaceCallIds,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$ResolveLyncConferenceIds
    )

    $nodeLocation = "/api/v1/webBridges/$Identity"
    $data = ""
    $modifiers = 0

    if ($Url -ne "") {
        $data += "url=$Url"
        $modifiers++
    }

    if ($ResourceArchive -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resourceArchive=$ResourceArchive"
        $modifiers++
    }

    if ($Tenant -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "tenant=$Tenant"
        $modifiers++
    }

    if ($TenantGroup -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "tenantGroup=$TenantGroup"
        $modifiers++
    }

    if ($IdEntryMode -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "idEntryMode=$IdEntryMode"
        $modifiers++
    }

    if ($AllowWebLinkAccess -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "allowWebLinkAccess=$AllowWebLinkAccess"
        $modifiers++
    }

    if ($ShowSignIn -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "showSignIn=$ShowSignIn"
        $modifiers++
    }

    if ($ResolveCoSpaceCallIds -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resolveCoSpaceCallIds=$ResolveCoSpaceCallIds"
        $modifiers++
    }

    if ($ResolveLyncConferenceIds -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "resolveLyncConferenceIds=$ResolveLyncConferenceIds"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsWebBridge $Identity
}

function Remove-CmsWebBridge {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove web bridge")) {
        Open-CmsAPI "/api/v1/webBridges/$Identity" -DELETE
    }
}

function Update-CmsWebBridgeCustomization {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    Open-CmsAPI "/api/v1/webBridges/$Identity/updateCustomization" -POST -ReturnResponse | Out-Null
}

function Get-CmsCallBridges {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/callBridges"

    if ($Limit -ne "") {
        $nodeLocation += "?limit=$Limit"
        
        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).callBridges.callBridge
}

function Get-CmsCallBridge {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsCallBridges
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/callBridges/$Identity").callBridge
        }
    }
}

function New-CmsCallBridge {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Name,
        [parameter(Mandatory=$false)]
        [string]$Address,
        [parameter(Mandatory=$false)]
        [string]$SipDomain
    )

    $nodeLocation = "/api/v1/callBridges"
    $data = "name=$Name"

    if ($Address -ne "") {
        $data += "&address=$Address"
    }

    if ($SipDomain -ne "") {
        $data += "&sipDomain=$SipDomain"
    }

    [string]$NewCallBridgeId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsCallBridge $NewCallBridgeId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsCallBridge {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$Name,
        [parameter(Mandatory=$false)]
        [string]$Address,
        [parameter(Mandatory=$false)]
        [string]$SipDomain
    )

    $nodeLocation = "/api/v1/callBridges/$Identity"
    $data = ""
    $modifiers = 0

    if ($Name -ne "") {
        $data += "name=$Name"
        $modifiers++
    }

    if ($Address -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "address=$Address"
        $modifiers++
    }

    if ($SipDomain -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "sipAddress=$SipDomain"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsCallBridge $Identity
}

function Remove-CmsCallBridge {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove callbridge")) {
        Open-CmsAPI "/api/v1/callBridges/$Identity" -DELETE
    }
}

function Get-CmsXmppServer {
    return (Open-CmsAPI "api/v1/system/configuration/xmpp").xmpp
}

function Set-CmsXmppServer {
     Param (
        [parameter(Mandatory=$false)]
        [string]$UniqueName,
        [parameter(Mandatory=$false)]
        [string]$Domain,
        [parameter(Mandatory=$false)]
        [string]$SharedSecret,
        [parameter(Mandatory=$false)]
        [string]$ServerAddressOverride
    )

    $nodeLocation = "/api/v1/system/configuration/xmpp"
    $data = ""
    $modifiers = 0

    if ($UniqueName -ne "") {
        $data += "uniqueName=$UniqueName"
        $modifiers++
    }

    if ($Domain -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "domain=$Domain"
        $modifiers++
    }

    if ($SharedSecret -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "sharedSecret=$SharedSecret"
        $modifiers++
    }

    if ($ServerAddressOverride -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "serverAddressOverride=$ServerAddressOverride"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsXmppServer
}

function Get-CmsCallBridgeCluster {
    return (Open-CmsAPI "api/v1/system/configuration/cluster").cluster
}

function Set-CmsCallBridgeCluster {
     Param (
        [parameter(Mandatory=$false)]
        [string]$UniqueName,
        [parameter(Mandatory=$false)]
        [string]$PeerLinkBitRate,
        [parameter(Mandatory=$false)]
        [string]$ParticipantLimit
    )

    $nodeLocation = "/api/v1/system/configuration/cluster"
    $data = ""
    $modifiers = 0

    if ($UniqueName -ne "") {
        $data += "uniqueName=$UniqueName"
        $modifiers++
    }

    if ($PeerLinkBitRate -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "peerLinkBitRate=$PeerLinkBitRate"
        $modifiers++
    }

    if ($ParticipantLimit -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "participantLimit=$ParticipantLimit"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsCallBridgeCluster
}

function Get-CmsSystemDiagnostics {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$CoSpaceFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$CallCorrelatorFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/system/diagnostics"
    $modifiers = 0

    if ($CoSpaceFilter -ne "") {
        $nodeLocation += "?coSpacefilter=$CoSpaceFilter"
        $modifiers++
    }

    if ($CallCorrelatorFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "callCorrelatorFilter=$CallCorrelatorFilter"
        $modifiers++
    }

    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).diagnostics.diagnostic
}

function Get-CmsSystemDiagnostic {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    return (Open-CmsAPI "api/v1/system/diagnostics/$Identity").diagnostic
}

function Get-CmsSystemDiagnosticContent {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    return (Open-CmsAPI "api/v1/system/diagnostics/$Identity/contents").diagnostic
}

function Get-CmsLdapServers {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/ldapServers"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }
    
    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).ldapServers.ldapServer
}

function Get-CmsLdapServer {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsLdapServers
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/ldapServers/$Identity").ldapServer
        }
    }
}

function New-CmsLdapServer {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Address,
        [parameter(Mandatory=$true)]
        [string]$PortNumber,
        [parameter(Mandatory=$false)]
        [string]$Username,
        [parameter(Mandatory=$false)]
        [string]$Password,
        [parameter(Mandatory=$true)]
        [ValidateSet("true","false")]
        [string]$Secure
    )

    $nodeLocation = "/api/v1/ldapServers"
    $data = "address=$Address&portNumber=$PortNumber&secure=$Secure"
    $modifiers = 0

    if ($Username -ne "") {
        $data += "&username=$Username"
    }

    if ($Password -ne "") {
        $data += "&password=$Password"
    }

    [string]$NewLdapServerId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsLdapServer $NewLdapServerId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsLdapServer {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$Address,
        [parameter(Mandatory=$false)]
        [string]$PortNumber,
        [parameter(Mandatory=$false)]
        [string]$Username,
        [parameter(Mandatory=$false)]
        [string]$Password,
        [parameter(Mandatory=$false)]
        [ValidateSet("true","false")]
        [string]$Secure
    )

    $nodeLocation = "/api/v1/ldapServers/$Identity"
    $data = ""
    $modifiers = 0

    if ($Address -ne "") {
        $data += "address=$Address"
        $modifiers++
    }

    if ($PortNumber -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "portNumber=$PortNumber"
        $modifiers++
    }

    if ($Username -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "username=$Username"
        $modifiers++
    }

    if ($Password -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "password=$Password"
        $modifiers++
    }

    if ($Secure -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "secure=$Secure"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsLdapServer $Identity
}

function Remove-CmsLdapServer {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove LDAP server")) {
        Open-CmsAPI "/api/v1/ldapServers/$Identity" -DELETE
    }
}

function Get-CmsLdapMappings {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/ldapMappings"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }
    
    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).ldapMappings.ldapMapping
}


function Get-CmsLdapMapping {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsLdapMappings
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/ldapMappings/$Identity").ldapMapping
        }
    }
}

function New-CmsLdapMapping {
    Param (
        [parameter(Mandatory=$false)]
        [string]$JidMapping,
        [parameter(Mandatory=$false)]
        [string]$NameMapping,
        [parameter(Mandatory=$false)]
        [string]$CdrTagMapping,
        [parameter(Mandatory=$false)]
        [string]$AuthenticationMapping,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceUriMapping,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceSecondaryUriMapping,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceNameMapping,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceCallIdMapping
    )

    $nodeLocation = "/api/v1/ldapMappings"
    $data = ""
    $modifiers = 0

    if ($JidMapping -ne "") {
        $data += "jidMapping=$JidMapping"
        $modifiers++
    }

    if ($NameMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "nameMapping=$NameMapping"
        $modifiers++
    }

    if ($CdrTagMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "cdrTagMapping=$CdrTagMapping"
        $modifiers++
    }

    if ($AuthenticationMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "authenticationMapping=$AuthenticationMapping"
        $modifiers++
    }

    if ($CoSpaceUriMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "coSpaceUriMapping=$CoSpaceUriMapping"
        $modifiers++
    }

    if ($CoSpaceSecondaryUriMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "coSpaceSecondaryUriMapping=$CoSpaceSecondaryUriMapping"
        $modifiers++
    }

    if ($CoSpaceNameMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "coSpaceNameMapping=$CoSpaceNameMapping"
        $modifiers++
    }

    if ($CoSpaceCallIdMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "coSpaceCallIdMapping=$CoSpaceCallIdMapping"
    }

    [string]$NewLdapMappingId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsLdapMapping $NewLdapMappingId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsLdapMapping {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$JidMapping,
        [parameter(Mandatory=$false)]
        [string]$NameMapping,
        [parameter(Mandatory=$false)]
        [string]$CdrTagMapping,
        [parameter(Mandatory=$false)]
        [string]$AuthenticationMapping,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceUriMapping,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceSecondaryUriMapping,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceNameMapping,
        [parameter(Mandatory=$false)]
        [string]$CoSpaceCallIdMapping
    )

    $nodeLocation = "/api/v1/ldapMappings/$Identity"
    $data = ""
    $modifiers = 0

    if ($JidMapping -ne "") {
        $data += "jidMapping=$JidMapping"
        $modifiers++
    }

    if ($NameMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "nameMapping=$NameMapping"
        $modifiers++
    }

    if ($CdrTagMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "cdrTagMapping=$CdrTagMapping"
        $modifiers++
    }

    if ($AuthenticationMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "authenticationMapping=$AuthenticationMapping"
        $modifiers++
    }

    if ($CoSpaceUriMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "coSpaceUriMapping=$CoSpaceUriMapping"
        $modifiers++
    }

    if ($CoSpaceSecondaryUriMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "coSpaceSecondaryUriMapping=$CoSpaceSecondaryUriMapping"
        $modifiers++
    }

    if ($CoSpaceNameMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "coSpaceNameMapping=$CoSpaceNameMapping"
        $modifiers++
    }

    if ($CoSpaceCallIdMapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "coSpaceCallIdMapping=$CoSpaceCallIdMapping"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsLdapMapping $Identity
}

function Remove-CmsLdapMapping {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove LDAP mapping")) {
        Open-CmsAPI "/api/v1/ldapMappings/$Identity" -DELETE
    }
}


function Get-CmsLdapSources {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$TenantFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/ldapSources"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }

    if ($TenantFilter -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "tenantFilter=$TenantFilter"
        $modifiers++
    }
    
    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).ldapSources.ldapSource
}


function Get-CmsLdapSource {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsLdapSources
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/ldapSources/$Identity").ldapSource
        }
    }
}

function New-CmsLdapSource {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Server,
        [parameter(Mandatory=$true)]
        [string]$Mapping,
        [parameter(Mandatory=$true)]
        [string]$BaseDN,
        [parameter(Mandatory=$false)]
        [string]$Filter,
        [parameter(Mandatory=$false)]
        [string]$Tenant,
        [parameter(Mandatory=$false)]
        [string]$UserProfile
    )

    $nodeLocation = "/api/v1/ldapSources"
    $data = "server=$Server&mapping=$Mapping&baseDN=$BaseDN"
    $modifiers = 0

    if ($Filter -ne "") {
        $data += "&filter=$Filter"
    }

    if ($Tenant -ne "") {
        $data += "&tenant=$Tenant"
    }

    if ($UserProfile -ne "") {
        $data += "&userProfile=$UserProfile"
    }

    [string]$NewLdapSourceId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsLdapSource $NewLdapSourceId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsLdapSource {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$Server,
        [parameter(Mandatory=$false)]
        [string]$Mapping,
        [parameter(Mandatory=$false)]
        [string]$BaseDN,
        [parameter(Mandatory=$false)]
        [string]$Filter,
        [parameter(Mandatory=$false)]
        [string]$Tenant,
        [parameter(Mandatory=$false)]
        [string]$UserProfile
    )

    $nodeLocation = "/api/v1/ldapSources/$Identity"
    $data = ""
    $modifiers = 0

    if ($Server -ne "") {
        $data += "server=$Server"
        $modifiers++
    }

    if ($Mapping -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "mapping=$Mapping"
        $modifiers++
    }

    if ($BaseDN -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "baseDn=$BaseDN"
        $modifiers++
    }

    if ($Filter -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "filter=$Filter"
        $modifiers++
    }

    if ($Tenant -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "tenant=$Tenant"
        $modifiers++
    }

    if ($UserProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "userProfile=$UserProfile"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsLdapSource $Identity
}

function Remove-CmsLdapSource {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove LDAP source")) {
        Open-CmsAPI "/api/v1/ldapSources/$Identity" -DELETE
    }
}


function Get-CmsLdapSyncs {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/ldapSyncs"

    if ($Limit -ne "") {
        $nodeLocation += "?limit=$Limit"
        
        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).ldapSyncs.ldapSync
}


function Get-CmsLdapSync {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsLdapSyncs
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/ldapSyncs/$Identity").ldapSync
        }
    }
}

function New-CmsLdapSync {
    Param (
        [parameter(Mandatory=$false)]
        [string]$Tenant,
        [parameter(Mandatory=$false)]
        [string]$LdapSource,
        [parameter(Mandatory=$false)]
        [string]$RemoveWhenFinished
    )

    $nodeLocation = "/api/v1/ldapSyncs"
    $data = ""
    $modifiers = 0

    if ($Tenant -ne "") {
        $data += "tenant=$Tenant"
        $modifiers++
    }

    if ($LdapSource -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "ldapSource=$LdapSource"
        $modifiers++
    }

    if ($RemoveWhenFinished -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "removeWhenFinished=$RemoveWhenFinished"
    }

    [string]$NewLdapSyncId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsLdapSync $NewLdapSyncId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Remove-CmsLdapSync {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Stop ongoing LDAP Sync")) {
        Open-CmsAPI "/api/v1/ldapSyncs/$Identity" -DELETE
    }
}


function Get-CmsExternalDirectorySearchLocations {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$TenantFilter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/directorySearchLocations"
    $modifiers = 0

    if ($TenantFilter -ne "") {
        $nodeLocation += "?tenantFilter=$TenantFilter"
        $modifiers++
    }
    
    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).directorySearchLocations.directorySearchLocation
}


function Get-CmsExternalDirectorySearchLocation {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsExternalDirectorySearchLocations
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/directorySearchLocations/$Identity").directorySearchLocation
        }
    }
}

function New-CmsExternalDirectorySearchLocation {
    Param (
        [parameter(Mandatory=$true)]
        [string]$LdapServer,
        [parameter(Mandatory=$false)]
        [string]$Tenant,
        [parameter(Mandatory=$false)]
        [string]$BaseDN,
        [parameter(Mandatory=$false)]
        [string]$FilterFormat,
        [parameter(Mandatory=$false)]
        [string]$Label,
        [parameter(Mandatory=$false)]
        [string]$Priority,
        [parameter(Mandatory=$false)]
        [string]$FirstName,
        [parameter(Mandatory=$false)]
        [string]$LastName,
        [parameter(Mandatory=$false)]
        [string]$DisplayName,
        [parameter(Mandatory=$false)]
        [string]$Phone,
        [parameter(Mandatory=$false)]
        [string]$Mobile,
        [parameter(Mandatory=$false)]
        [string]$Email,
        [parameter(Mandatory=$false)]
        [string]$Sip,
        [parameter(Mandatory=$false)]
        [string]$Organization
    )

    $nodeLocation = "/api/v1/directorySearchLocations"
    $data = "ldapServer=$LdapServer"

    if ($Tenant -ne "") {
        $data += "&tenant=$Tenant"
    }

    if ($BaseDN -ne "") {
        $data += "&baseDn=$BaseDN"
    }

    if ($FilterFormat -ne "") {
        $data += "&filterFormat=$FilterFormat"
    }

    if ($Label -ne "") {
        $data += "&label=$Label"
    }

    if ($Priority -ne "") {
        $data += "&priority=$Priority"
    }

    if ($FirstName -ne "") {
        $data += "&firstName=$FirstName"
    }

    if ($LastName -ne "") {
        $data += "&lastName=$LastName"
    }

    if ($DisplayName -ne "") {
        $data += "&displayName=$DisplayName"
    }

    if ($Phone -ne "") {
        $data += "&phone=$Phone"
    }

    if ($Mobile -ne "") {
        $data += "&mobile=$Mobile"
    }

    if ($Email -ne "") {
        $data += "&email=$Email"
    }

    if ($Sip -ne "") {
        $data += "&sip=$Sip"
    }

    if ($Organization -ne "") {
        $data += "&organization=$Organization"
    }

    [string]$NewexdirsearchId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsExternalDirectorySearchLocation $NewexdirsearchId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsExternalDirectorySearchLocation {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$LdapServer,
        [parameter(Mandatory=$false)]
        [string]$Tenant,
        [parameter(Mandatory=$false)]
        [string]$BaseDN,
        [parameter(Mandatory=$false)]
        [string]$FilterFormat,
        [parameter(Mandatory=$false)]
        [string]$Label,
        [parameter(Mandatory=$false)]
        [string]$Priority,
        [parameter(Mandatory=$false)]
        [string]$FirstName,
        [parameter(Mandatory=$false)]
        [string]$LastName,
        [parameter(Mandatory=$false)]
        [string]$DisplayName,
        [parameter(Mandatory=$false)]
        [string]$Phone,
        [parameter(Mandatory=$false)]
        [string]$Mobile,
        [parameter(Mandatory=$false)]
        [string]$Email,
        [parameter(Mandatory=$false)]
        [string]$Sip,
        [parameter(Mandatory=$false)]
        [string]$Organization
    )

    $nodeLocation = "/api/v1/directorySearchLocations/$Identity"
    $data = ""
    $modifiers = 0

    if ($Tenant -ne "") {
        $data += "tenant=$Tenant"
        $modifiers++
    }

    if ($LdapServer -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "ldapServer=$LdapServer"
        $modifiers++
    }

    if ($BaseDN -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "baseDn=$BaseDN"
        $modifiers++
    }

    if ($FilterFormat -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "filterFormat=$FilterFormat"
        $modifiers++
    }

    if ($Label -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "label=$Label"
        $modifiers++
    }

    if ($Priority -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "priority=$Priority"
        $modifiers++
    }

    if ($FirstName -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "firstName=$FirstName"
        $modifiers++
    }

    if ($LastName -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "lastName=$LastName"
        $modifiers++
    }

    if ($DisplayName -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "displayName=$DisplayName"
        $modifiers++
    }

    if ($Phone -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "phone=$Phone"
        $modifiers++
    }

    if ($Mobile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "mobile=$Mobile"
        $modifiers++
    }

    if ($Email -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "email=$Email"
        $modifiers++
    }

    if ($Sip -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "sip=$Sip"
        $modifiers++
    }

    if ($Organization -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "organization=$Organization"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsExternalDirectorySearchLocation $Identity
}

function Remove-CmsExternalDirectorySearchLocation {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove external directory search location")) {
        Open-CmsAPI "/api/v1/directorySearchLocations/$Identity" -DELETE
    }
}

function Get-CmsTenants {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Filter,
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/tenants"
    $modifiers = 0

    if ($Filter -ne "") {
        $nodeLocation += "?filter=$Filter"
        $modifiers++
    }
    
    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).tenants.tenant
}

function Get-CmsTenant {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsTenants
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/tenants/$Identity").tenant
        }
    }
}

function New-CmsTenant {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Name,
        [parameter(Mandatory=$false)]
        [string]$TenantGroup,
        [parameter(Mandatory=$false)]
        [string]$CallLegProfile,
        [parameter(Mandatory=$false)]
        [string]$CallProfile,
        [parameter(Mandatory=$false)]
        [string]$DtmfProfile,
        [parameter(Mandatory=$false)]
        [string]$IvrBrandingProfile,
        [parameter(Mandatory=$false)]
        [string]$CallBrandingProfile,
        [parameter(Mandatory=$false)]
        [string]$ParticipantLimit,
        [parameter(Mandatory=$false)]
        [string]$UserProfile
    )

    $nodeLocation = "/api/v1/tenants"
    $data = "name=$Name"

    if ($TenantGroup -ne "") {
        $data += "&tenantGroup=$TenantGroup"
    }

    if ($CallLegProfile -ne "") {
        $data += "&callLegProfile=$CallLegProfile"
    }

    if ($CallProfile -ne "") {
        $data += "&callProfile=$CallProfile"
    }

    if ($DtmfProfile -ne "") {
        $data += "&dtmfProfile=$DtmfProfile"
    }

    if ($IvrBrandingProfile -ne "") {
        $data += "&ivrBrandingProfile=$IvrBrandingProfile"
    }

    if ($CallBrandingProfile -ne "") {
        $data += "&callBrandingProfile=$CallBrandingProfile"
    }

    if ($ParticipantLimit -ne "") {
        $data += "&participantLimit=$ParticipantLimit"
    }

    if ($UserProfile -ne "") {
        $data += "&userProfile=$UserProfile"
    }

    [string]$NewTenantId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsTenant $NewTenantId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsTenant {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$false)]
        [string]$Name,
        [parameter(Mandatory=$false)]
        [string]$TenantGroup,
        [parameter(Mandatory=$false)]
        [string]$CallLegProfile,
        [parameter(Mandatory=$false)]
        [string]$CallProfile,
        [parameter(Mandatory=$false)]
        [string]$DtmfProfile,
        [parameter(Mandatory=$false)]
        [string]$IvrBrandingProfile,
        [parameter(Mandatory=$false)]
        [string]$CallBrandingProfile,
        [parameter(Mandatory=$false)]
        [string]$ParticipantLimit,
        [parameter(Mandatory=$false)]
        [string]$UserProfile
    )

    $nodeLocation = "/api/v1/Tenants/$Identity"
    $data = ""
    $modifiers = 0

    if ($TenantGroup -ne "") {
        $data += "tenantgroup=$TenantGroup"
        $modifiers++
    }

    if ($Name -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "name=$Name"
        $modifiers++
    }

    if ($CallLegProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callLegProfile=$CallLegProfile"
        $modifiers++
    }

    if ($CallProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callProfile=$CallProfile"
        $modifiers++
    }

    if ($DtmfProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "dtmfProfile=$DtmfProfile"
        $modifiers++
    }

    if ($IvrBrandingProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "ivrBrandingProfile=$IvrBrandingProfile"
        $modifiers++
    }

    if ($CallBrandingProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callBrandingProfile=$CallBrandingProfile"
        $modifiers++
    }

    if ($ParticipantLimit -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "participantLimit=$ParticipantLimit"
        $modifiers++
    }

    if ($UserProfile -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "userProfile=$UserProfile"
    }

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsTenant $Identity
}

function Remove-CmsTenant {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove tenant")) {
        Open-CmsAPI "/api/v1/tenants/$Identity" -DELETE
    }
}

function Get-CmsTenantGroups {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/tenantGroups"
    $modifiers = 0
    
    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).tenantGroups.tenantGroup
}

function Get-CmsTenantGroup {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsTenantGroups
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/tenantGroups/$Identity").tenantGroup
        }
    }
}

function New-CmsTenantGroup {

    $nodeLocation = "/api/v1/tenantGroups"
    $data = ""

    [string]$NewTenantGroupId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsTenantGroup $NewTenantGroupId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Remove-CmsTenantGroup {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove tenant group")) {
        Open-CmsAPI "/api/v1/tenantGroups/$Identity" -DELETE
    }
}

function New-CmsAccessQuery {
    Param (
        [parameter(Mandatory=$false)]
        [string]$Tenant,
        [parameter(Mandatory=$false)]
        [string]$Uri,
        [parameter(Mandatory=$false)]
        [string]$CallId
    )

    $nodeLocation = "/api/v1/accessQuery"
    $data = ""
    $modifiers = 0

    if ($Tenant -ne "") {
        $data += "tenant=$Tenant"
        $modifiers++
    }

    if ($Uri -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "uri=$Uri"
        $modifiers++
    }

    if ($CallId -ne "") {
        if ($modifiers -gt 0) {
            $data += "&"
        }
        $data += "callId=$CallId"
    }

    return (Open-CmsAPI $nodeLocation -POST -Data $data -ReturnResponse).accessQuery
}

function Get-CmsRecorders {
    [CmdletBinding(DefaultParameterSetName="NoOffset")]
    Param (
        [parameter(ParameterSetName="Offset",Mandatory=$true)]
        [parameter(ParameterSetName="NoOffset",Mandatory=$false)]
        [string]$Limit,
        [parameter(ParameterSetName="Offset",Mandatory=$false)]
        [string]$Offset
    )

    $nodeLocation = "api/v1/recorders"
    $modifiers = 0
    
    if ($Limit -ne "") {
        if ($modifiers -gt 0) {
            $nodeLocation += "&"
        } else {
            $nodeLocation += "?"
        }
        $nodeLocation += "limit=$Limit"

        if($Offset -ne ""){
            $nodeLocation += "&offset=$Offset"
        }
    }

    return (Open-CmsAPI $nodeLocation).recorders.recorder
}

function Get-CmsRecorder {
    [CmdletBinding(DefaultParameterSetName="getAll")]
    Param (
        [parameter(ParameterSetName="getSingle",Mandatory=$true,Position=1)]
        [string]$Identity
    )

    switch ($PsCmdlet.ParameterSetName) { 

        "getAll"  {
            Get-CmsRecorders
        } 

        "getSingle"  {
            return (Open-CmsAPI "api/v1/recorders/$Identity").recorder
        }
    }
}

function New-CmsRecorder {
    Param (
        [parameter(Mandatory=$true)]
        [string]$Url
    )

    $nodeLocation = "/api/v1/recorders"
    $data = "Url=$Url"

    [string]$NewRecorderId = Open-CmsAPI $nodeLocation -POST -Data $data
    
    Get-CmsRecorder $NewRecorderId.Replace(" ","") ## For some reason POST returns a string starting and ending with a whitespace
}

function Set-CmsRecorder {
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity,
        [parameter(Mandatory=$true)]
        [string]$Url
    )

    $nodeLocation = "/api/v1/recorders/$Identity"
    $data = "url=$Url"

    Open-CmsAPI $nodeLocation -PUT -Data $data
    
    Get-CmsRecorder $Identity
}

function Remove-CmsRecorder {
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    Param (
        [parameter(Mandatory=$true,Position=1)]
        [string]$Identity
    )

    if ($PSCmdlet.ShouldProcess("$Identity","Remove recorder")) {
        Open-CmsAPI "/api/v1/recorders/$Identity" -DELETE
    }
}

New-Alias -Name Get-AcanoCall -Value Get-CmsCall
New-Alias -Name Get-AcanoCallBrandingProfile -Value Get-CmsCallBrandingProfile
New-Alias -Name Get-AcanoCallBrandingProfiles -Value Get-CmsCallBrandingProfiles
New-Alias -Name Get-AcanoCallBridge -Value Get-CmsCallBridge
New-Alias -Name Get-AcanoCallBridgeCluster -Value Get-CmsCallBridgeCluster
New-Alias -Name Get-AcanoCallBridges -Value Get-CmsCallBridges
New-Alias -Name Get-AcanoCallForwardingDialPlanRule -Value Get-CmsCallForwardingDialPlanRule
New-Alias -Name Get-AcanoCallForwardingDialPlanRules -Value Get-CmsCallForwardingDialPlanRules
New-Alias -Name Get-AcanoCallLeg -Value Get-CmsCallLeg
New-Alias -Name Get-AcanoCallLegProfile -Value Get-CmsCallLegProfile
New-Alias -Name Get-AcanoCallLegProfiles -Value Get-CmsCallLegProfiles
New-Alias -Name Get-AcanoCallLegProfileTrace -Value Get-CmsCallLegProfileTrace
New-Alias -Name Get-AcanoCallLegProfileUsages -Value Get-CmsCallLegProfileUsages
New-Alias -Name Get-AcanoCallLegs -Value Get-CmsCallLegs
New-Alias -Name Get-AcanoCallProfile -Value Get-CmsCallProfile
New-Alias -Name Get-AcanoCallProfiles -Value Get-CmsCallProfiles
New-Alias -Name Get-AcanoCalls -Value Get-CmsCalls
New-Alias -Name Get-AcanoCdrRecieverUri -Value Get-CmsCdrRecieverUri
New-Alias -Name Get-AcanoCdrRecieverUris -Value Get-CmsCdrRecieverUris
New-Alias -Name Get-AcanocoSpace -Value Get-CmsSpace
New-Alias -Name Get-AcanocoSpaceAccessMethod -Value Get-CmsSpaceAccessMethod
New-Alias -Name Get-AcanocoSpaceAccessMethods -Value Get-CmsSpaceAccessMethods
New-Alias -Name Get-AcanocoSpaceMember -Value Get-CmsSpaceMember
New-Alias -Name Get-AcanocoSpaceMembers -Value Get-CmsSpaceMembers
New-Alias -Name Get-AcanocoSpaces -Value Get-CmsSpaces
New-Alias -Name Get-CmscoSpace -Value Get-CmsSpace
New-Alias -Name Get-CmscoSpaceAccessMethod -Value Get-CmsSpaceAccessMethod
New-Alias -Name Get-CmscoSpaceAccessMethods -Value Get-CmsSpaceAccessMethods
New-Alias -Name Get-CmscoSpaceMember -Value Get-CmsSpaceMember
New-Alias -Name Get-CmscoSpaceMembers -Value Get-CmsSpaceMembers
New-Alias -Name Get-CmscoSpaces -Value Get-CmsSpaces
New-Alias -Name Get-AcanoDialTransform -Value Get-CmsDialTransform
New-Alias -Name Get-AcanoDialTransforms -Value Get-CmsDialTransforms
New-Alias -Name Get-AcanoDtmfProfile -Value Get-CmsDtmfProfile
New-Alias -Name Get-AcanoDtmfProfiles -Value Get-CmsDtmfProfiles
New-Alias -Name Get-AcanoExternalDirectorySearchLocation -Value Get-CmsExternalDirectorySearchLocation
New-Alias -Name Get-AcanoExternalDirectorySearchLocations -Value Get-CmsExternalDirectorySearchLocations
New-Alias -Name Get-AcanoGlobalProfile -Value Get-CmsGlobalProfile
New-Alias -Name Get-AcanoInboundDialPlanRule -Value Get-CmsInboundDialPlanRule
New-Alias -Name Get-AcanoInboundDialPlanRules -Value Get-CmsInboundDialPlanRules
New-Alias -Name Get-AcanoIvr -Value Get-CmsIvr
New-Alias -Name Get-AcanoIvrBrandingProfile -Value Get-CmsIvrBrandingProfile
New-Alias -Name Get-AcanoIvrBrandingProfiles -Value Get-CmsIvrBrandingProfiles
New-Alias -Name Get-AcanoIvrs -Value Get-CmsIvrs
New-Alias -Name Get-AcanoLdapMapping -Value Get-CmsLdapMapping
New-Alias -Name Get-AcanoLdapMappings -Value Get-CmsLdapMappings
New-Alias -Name Get-AcanoLdapServer -Value Get-CmsLdapServer
New-Alias -Name Get-AcanoLdapServers -Value Get-CmsLdapServers
New-Alias -Name Get-AcanoLdapSource -Value Get-CmsLdapSource
New-Alias -Name Get-AcanoLdapSources -Value Get-CmsLdapSources
New-Alias -Name Get-AcanoLdapSync -Value Get-CmsLdapSync
New-Alias -Name Get-AcanoLdapSyncs -Value Get-CmsLdapSyncs
New-Alias -Name Get-AcanoLegacyCdrReceiverUri -Value Get-CmsLegacyCdrReceiverUri
New-Alias -Name Get-AcanoOutboundDialPlanRule -Value Get-CmsOutboundDialPlanRule
New-Alias -Name Get-AcanoOutboundDialPlanRules -Value Get-CmsOutboundDialPlanRules
New-Alias -Name Get-AcanoParticipant -Value Get-CmsParticipant
New-Alias -Name Get-AcanoParticipantCallLegs -Value Get-CmsParticipantCallLegs
New-Alias -Name Get-AcanoParticipants -Value Get-CmsParticipants
New-Alias -Name Get-AcanoRecorder -Value Get-CmsRecorder
New-Alias -Name Get-AcanoRecorders -Value Get-CmsRecorders
New-Alias -Name Get-AcanoSystemAlarm -Value Get-CmsSystemAlarm
New-Alias -Name Get-AcanoSystemAlarms -Value Get-CmsSystemAlarms
New-Alias -Name Get-AcanoSystemDatabaseStatus -Value Get-CmsSystemDatabaseStatus
New-Alias -Name Get-AcanoSystemDiagnostic -Value Get-CmsSystemDiagnostic
New-Alias -Name Get-AcanoSystemDiagnosticContent -Value Get-CmsSystemDiagnosticContent
New-Alias -Name Get-AcanoSystemDiagnostics -Value Get-CmsSystemDiagnostics
New-Alias -Name Get-AcanoSystemStatus -Value Get-CmsSystemStatus
New-Alias -Name Get-AcanoTenant -Value Get-CmsTenant
New-Alias -Name Get-AcanoTenantGroup -Value Get-CmsTenantGroup
New-Alias -Name Get-AcanoTenantGroups -Value Get-CmsTenantGroups
New-Alias -Name Get-AcanoTenants -Value Get-CmsTenants
New-Alias -Name Get-AcanoTurnServer -Value Get-CmsTurnServer
New-Alias -Name Get-AcanoTurnServers -Value Get-CmsTurnServers
New-Alias -Name Get-AcanoTurnServerStatus -Value Get-CmsTurnServerStatus
New-Alias -Name Get-AcanoUser -Value Get-CmsUser
New-Alias -Name Get-AcanoUsercoSpaces -Value Get-CmsUsercoSpaces
New-Alias -Name Get-AcanoUserProfile -Value Get-CmsUserProfile
New-Alias -Name Get-AcanoUserProfiles -Value Get-CmsUserProfiles
New-Alias -Name Get-AcanoUsers -Value Get-CmsUsers
New-Alias -Name Get-AcanoWebBridge -Value Get-CmsWebBridge
New-Alias -Name Get-AcanoWebBridges -Value Get-CmsWebBridges
New-Alias -Name Get-AcanoXmppServer -Value Get-CmsXmppServer
New-Alias -Name New-AcanoAccessQuery -Value New-CmsAccessQuery
New-Alias -Name New-AcanoCall -Value New-CmsCall
New-Alias -Name New-AcanoCallBrandingProfile -Value New-CmsCallBrandingProfile
New-Alias -Name New-AcanoCallBridge -Value New-CmsCallBridge
New-Alias -Name New-AcanoCallForwardingDialPlanRule -Value New-CmsCallForwardingDialPlanRule
New-Alias -Name New-AcanoCallLeg -Value New-CmsCallLeg
New-Alias -Name New-AcanoCallLegParticipant -Value New-CmsCallLegParticipant
New-Alias -Name New-AcanoCallLegProfile -Value New-CmsCallLegProfile
New-Alias -Name New-AcanoCallProfile -Value New-CmsCallProfile
New-Alias -Name New-AcanoCdrRecieverUri -Value New-CmsCdrRecieverUri
New-Alias -Name New-AcanocoSpace -Value New-CmsSpace
New-Alias -Name New-AcanocoSpaceAccessMethod -Value New-CmsSpaceAccessMethod
New-Alias -Name New-AcanocoSpaceMember -Value New-CmsSpaceMember
New-Alias -Name New-AcanocoSpaceMessage -Value New-CmsSpaceMessage
New-Alias -Name New-CmscoSpace -Value New-CmsSpace
New-Alias -Name New-CmscoSpaceAccessMethod -Value New-CmsSpaceAccessMethod
New-Alias -Name New-CmscoSpaceMember -Value New-CmsSpaceMember
New-Alias -Name New-CmscoSpaceMessage -Value New-CmsSpaceMessage
New-Alias -Name New-AcanoDialTransform -Value New-CmsDialTransform
New-Alias -Name New-AcanoDtmfProfile -Value New-CmsDtmfProfile
New-Alias -Name New-AcanoExternalDirectorySearchLocation -Value New-CmsExternalDirectorySearchLocation
New-Alias -Name New-AcanoInboundDialPlanRule -Value New-CmsInboundDialPlanRule
New-Alias -Name New-AcanoIvr -Value New-CmsIvr
New-Alias -Name New-AcanoIvrBrandingProfile -Value New-CmsIvrBrandingProfile
New-Alias -Name New-AcanoLdapMapping -Value New-CmsLdapMapping
New-Alias -Name New-AcanoLdapServer -Value New-CmsLdapServer
New-Alias -Name New-AcanoLdapSource -Value New-CmsLdapSource
New-Alias -Name New-AcanoLdapSync -Value New-CmsLdapSync
New-Alias -Name New-AcanoOutboundDialPlanRule -Value New-CmsOutboundDialPlanRule
New-Alias -Name New-AcanoRecorder -Value New-CmsRecorder
New-Alias -Name New-AcanoSession -Value New-CmsSession
New-Alias -Name New-AcanoTenant -Value New-CmsTenant
New-Alias -Name New-AcanoTenantGroup -Value New-CmsTenantGroup
New-Alias -Name New-AcanoTurnServer -Value New-CmsTurnServer
New-Alias -Name New-AcanoUserProfile -Value New-CmsUserProfile
New-Alias -Name New-AcanoWebBridge -Value New-CmsWebBridge
New-Alias -Name Open-AcanoAPI -Value Open-CmsAPI
New-Alias -Name Remove-AcanoCall -Value Remove-CmsCall
New-Alias -Name Remove-AcanoCallBrandingProfile -Value Remove-CmsCallBrandingProfile
New-Alias -Name Remove-AcanoCallBridge -Value Remove-CmsCallBridge
New-Alias -Name Remove-AcanoCallForwardingDialPlanRule -Value Remove-CmsCallForwardingDialPlanRule
New-Alias -Name Remove-AcanoCallLeg -Value Remove-CmsCallLeg
New-Alias -Name Remove-AcanoCallLegProfile -Value Remove-CmsCallLegProfile
New-Alias -Name Remove-AcanoCallProfile -Value Remove-CmsCallProfile
New-Alias -Name Remove-AcanoCdrRecieverUri -Value Remove-CmsCdrRecieverUri
New-Alias -Name Remove-AcanocoSpace -Value Remove-CmsSpace
New-Alias -Name Remove-AcanocoSpaceAccessMethod -Value Remove-CmsSpaceAccessMethod
New-Alias -Name Remove-AcanocoSpaceMember -Value Remove-CmsSpaceMember
New-Alias -Name Remove-AcanocoSpaceMessages -Value Remove-CmsSpaceMessages
New-Alias -Name Remove-CmscoSpace -Value Remove-CmsSpace
New-Alias -Name Remove-CmscoSpaceAccessMethod -Value Remove-CmsSpaceAccessMethod
New-Alias -Name Remove-CmscoSpaceMember -Value Remove-CmsSpaceMember
New-Alias -Name Remove-CmscoSpaceMessages -Value Remove-CmsSpaceMessages
New-Alias -Name Remove-AcanoDialTransform -Value Remove-CmsDialTransform
New-Alias -Name Remove-AcanoDtmfProfile -Value Remove-CmsDtmfProfile
New-Alias -Name Remove-AcanoExternalDirectorySearchLocation -Value Remove-CmsExternalDirectorySearchLocation
New-Alias -Name Remove-AcanoInboundDialPlanRule -Value Remove-CmsInboundDialPlanRule
New-Alias -Name Remove-AcanoIvr -Value Remove-CmsIvr
New-Alias -Name Remove-AcanoIvrBrandingProfile -Value Remove-CmsIvrBrandingProfile
New-Alias -Name Remove-AcanoLdapMapping -Value Remove-CmsLdapMapping
New-Alias -Name Remove-AcanoLdapServer -Value Remove-CmsLdapServer
New-Alias -Name Remove-AcanoLdapSource -Value Remove-CmsLdapSource
New-Alias -Name Remove-AcanoLdapSync -Value Remove-CmsLdapSync
New-Alias -Name Remove-AcanoLegacyCdrRecieverUri -Value Remove-CmsLegacyCdrRecieverUri
New-Alias -Name Remove-AcanoOutboundDialPlanRule -Value Remove-CmsOutboundDialPlanRule
New-Alias -Name Remove-AcanoRecorder -Value Remove-CmsRecorder
New-Alias -Name Remove-AcanoTenant -Value Remove-CmsTenant
New-Alias -Name Remove-AcanoTenantGroup -Value Remove-CmsTenantGroup
New-Alias -Name Remove-AcanoTurnServer -Value Remove-CmsTurnServer
New-Alias -Name Remove-AcanoUserProfile -Value Remove-CmsUserProfile
New-Alias -Name Remove-AcanoWebBridge -Value Remove-CmsWebBridge
New-Alias -Name Set-AcanoCall -Value Set-CmsCall
New-Alias -Name Set-AcanoCallBrandingProfile -Value Set-CmsCallBrandingProfile
New-Alias -Name Set-AcanoCallBridge -Value Set-CmsCallBridge
New-Alias -Name Set-AcanoCallBridgeCluster -Value Set-CmsCallBridgeCluster
New-Alias -Name Set-AcanoCallForwardingDialPlanRule -Value Set-CmsCallForwardingDialPlanRule
New-Alias -Name Set-AcanoCallLeg -Value Set-CmsCallLeg
New-Alias -Name Set-AcanoCallLegProfile -Value Set-CmsCallLegProfile
New-Alias -Name Set-AcanoCallProfile -Value Set-CmsCallProfile
New-Alias -Name Set-AcanoCdrRecieverUri -Value Set-CmsCdrRecieverUri
New-Alias -Name Set-AcanocoSpace -Value Set-CmsSpace
New-Alias -Name Set-AcanocoSpaceAccessMethod -Value Set-CmsSpaceAccessMethod
New-Alias -Name Set-AcanocoSpaceMember -Value Set-CmsSpaceMember
New-Alias -Name Set-CmscoSpace -Value Set-CmsSpace
New-Alias -Name Set-CmscoSpaceAccessMethod -Value Set-CmsSpaceAccessMethod
New-Alias -Name Set-CmscoSpaceMember -Value Set-CmsSpaceMember
New-Alias -Name Set-AcanoDialTransform -Value Set-CmsDialTransform
New-Alias -Name Set-AcanoDtmfProfile -Value Set-CmsDtmfProfile
New-Alias -Name Set-AcanoExternalDirectorySearchLocation -Value Set-CmsExternalDirectorySearchLocation
New-Alias -Name Set-AcanoGlobalProfile -Value Set-CmsGlobalProfile
New-Alias -Name Set-AcanoInboundDialPlanRule -Value Set-CmsInboundDialPlanRule
New-Alias -Name Set-AcanoIvr -Value Set-CmsIvr
New-Alias -Name Set-AcanoIvrBrandingProfile -Value Set-CmsIvrBrandingProfile
New-Alias -Name Set-AcanoLdapMapping -Value Set-CmsLdapMapping
New-Alias -Name Set-AcanoLdapServer -Value Set-CmsLdapServer
New-Alias -Name Set-AcanoLdapSource -Value Set-CmsLdapSource
New-Alias -Name Set-AcanoLegacyCdrRecieverUri -Value Set-CmsLegacyCdrRecieverUri
New-Alias -Name Set-AcanoOutboundDialPlanRule -Value Set-CmsOutboundDialPlanRule
New-Alias -Name Set-AcanoRecorder -Value Set-CmsRecorder
New-Alias -Name Set-AcanoTenant -Value Set-CmsTenant
New-Alias -Name Set-AcanoTurnServer -Value Set-CmsTurnServer
New-Alias -Name Set-AcanoUserProfile -Value Set-CmsUserProfile
New-Alias -Name Set-AcanoWebBridge -Value Set-CmsWebBridge
New-Alias -Name Set-AcanoXmppServer -Value Set-CmsXmppServer
New-Alias -Name Start-AcanocoSpaceCallDiagnosticsGeneration -Value Start-CmsSpaceCallDiagnosticsGeneration
New-Alias -Name Start-CmscoSpaceCallDiagnosticsGeneration -Value Start-CmsSpaceCallDiagnosticsGeneration
New-Alias -Name Update-AcanoWebBridgeCustomization -Value Update-CmsWebBridgeCustomization