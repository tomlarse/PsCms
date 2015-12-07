function Add-Participant {
<#
.SYNOPSIS  
	Add a participant to an Acano coSpace
.DESCRIPTION
    Use to add participants to a coSpace. Use to test dial out from the callbridge or as a support tool. 
.EXAMPLE
	Add-Participant -CoSpace df2d3e44-91ff-48f4-aeca-ffd951641ebe -SipUri anne.wallace@contoso.com
.PARAMETER CoSpace
	GUID of the coSpace to add a participant to
.PARAMETER SipUri
    SIP address of the participant to add. 
#>
    Param (
        $CoSpace,
        $SipUri
    )

    $call = Get-AcanoCalls -coSpaceFilter $CoSpace

    if ($call -eq $null) { #No calls exist on the CoSpace, need to create one
        $call = New-AcanoCall -coSpaceId $CoSpace
    }

    $callLeg = New-AcanoCallLeg -CallId $call.id -RemoteParty $SipUri

    Get-AcanoCallLeg -CallLegID $callLeg.id
    
}