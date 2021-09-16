<#
.SYNOPSIS
 
Returns tool version ID for given product ID and version name.
 
.DESCRIPTION
Returns tool version ID for given product ID and version name using the CodeDx endpoint.
 
.EXAMPLE
Get-ToolVersion "version" myProject "1.0.0" 63 https://samplehostname.blackducksoftware.com/ MTNmNDY0NzItNGVjNS00Yzg0LWE5NWEtOCAmYzg3NzRjMjQ1OmY1ZjRhMjM0LWZlZDUtNDliNC05NzkxLWUyY2JiNTk0Y2UyOA==

Output 
1
 
#>

Function Get-ToolVersionToken
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        [Parameter(Mandatory=$true)]
        [string]$ToolProjectID,
        [Parameter(Mandatory=$true)]
        [string]$ToolVersionName,
        [Parameter(Mandatory=$true)]
        [string]$ConnectorID,
        [Parameter(Mandatory=$true)]
        [string]$HostURL,
        [Parameter(Mandatory=$true)]
        [string]$Token
    )

	if ($ToolVersionName -eq "latest") {
		if ($FieldName -eq "branch"){
			return "cdx_default_branch"
		} else {
			return "cdx_use_latest_ver"
		}
	}
	
	$uri = $CDXSERVER + "/x/tool-connector-config/values/" + $ConnectorID + "/populate/" + $FieldName

    $body = Convertto-Json @{
		auth_type = "api_token"
		api_key = $Token
		api_token = $Token
		server_url = $HostURL
		project = $ToolProjectID
    }

    $ToolVersions = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $headers -ContentType "application/json" 
    Write-Verbose ( $ToolVersions | Format-Table | Out-String )

	# Get the tool project ID from the name
	$ToolVersions | ForEach-Object {
		if($_.display -eq $ToolVersionName) {
			$ToolVersionID = $_.value
		}
	}
	Write-Verbose ($ToolVersionID)
	return $ToolVersionID
}