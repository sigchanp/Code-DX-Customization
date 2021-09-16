<#
.SYNOPSIS
 
Returns tool project ID for given project name.
 
.DESCRIPTION
Returns tool project ID for given project name using the CodeDx endpoint.
 
.EXAMPLE
Get-ToolProject "selected_project" myProject 54 https://cxprivatecloud.checkmarx.net/ username@email.com nroa9tbbk64rt94qgkq81502n18cf454g0tiqlmqu6l3tbj5br50

Output 
1
 
#>

Function Get-ToolProjectToken
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        [Parameter(Mandatory=$true)]
        [string]$ToolProjectName,
        [Parameter(Mandatory=$true)]
        [string]$ConnectorID,
        [Parameter(Mandatory=$true)]
        [string]$HostURL,
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
	
	$uri = $CDXSERVER + "/x/tool-connector-config/values/" + $ConnectorID + "/populate/" + $FieldName

    $body = Convertto-Json @{
		auth_type = "api_token"
		api_key = $Token
		api_token = $Token
		server_url = $HostURL
    }

    $ToolProjects = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $headers -ContentType "application/json" 
    Write-Verbose ( $ToolProjects | Format-Table | Out-String )

	# Get the tool project ID from the name
	$ToolProjects | ForEach-Object {
		if($_.display -eq $ToolProjectName) {
			$ToolProjectID = $_.value
		}
	}
	
	return $ToolProjectID
}