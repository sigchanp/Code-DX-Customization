<#
.SYNOPSIS
Disable a Tool
 
.DESCRIPTION
Disable a Tool as if it is done via the "Tool Config" UI
 
.EXAMPLE
Invoke-AnalysisPrep 17 31

#>

function Disable-ToolConfig
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ToolID,
        [Parameter(Mandatory=$true)]
        [string]$ProjectID
    )
    
    $uri = $CDXSERVER + "/x/descriptor-groups/" + $ToolID + "/enabled-on/" + $ProjectID

	$body = Convertto-Json $false

    Invoke-RestMethod -Uri $uri -Method Put -Body $body -Headers $headers -ContentType "application/json" 

}