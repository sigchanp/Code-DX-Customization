<#
.SYNOPSIS
 
Create a single Black Duck connector
 
.DESCRIPTION
Adds a single Black Duck connector using the tool connector config API endpoints
 
.EXAMPLE
Add-BlackDuckConnectorToken "selected_project" Black_Duck_Hub_Connector myProject 1.0 https://samplehostname.blackducksoftware.com/ MTNmNDY0NzItNGVjNS00Yzg0LWE5NWEtOCAmYzg3NzRjMjQ1OmY1ZjRhMjM0LWZlZDUtNDliNC05NzkxLWUyY2JiNTk0Y2UyOA== 0 low

Output (entry ID)

 
#>

Function Add-BlackDuckConnectorToken
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectName,
        [Parameter(Mandatory=$true)]
        [string]$NewConnectorName,
        [Parameter(Mandatory=$true)]
        [string]$ToolProjectName,
        [Parameter(Mandatory=$true)]
        [string]$ToolProjectVersion,
        [Parameter(Mandatory=$true)]
        [string]$HostURL,
        [Parameter(Mandatory=$true)]
        [string]$Token,
        [Parameter(Mandatory=$false)]
        [boolean]$ComLocation,
        [Parameter(Mandatory=$false)]
        [string]$MinSeverity,
        [Parameter(Mandatory=$false)]
        [string]$RefreshTime
    )
	
	# Get the Code Dx project ID from the name
	$projects = Get-Projects
	$ProjectHash = @{}
	$projects.projects | ForEach-Object {
		$ProjectHash[$_.name] = $_.id
	}
	$ProjectID = $ProjectHash.$ProjectName
	
	# Create a blank tool connector
	$ConnectorInfo = Add-BlankConnector $ProjectID "Black Duck Hub" $NewConnectorName
	$ConnectorID = $ConnectorInfo.id
    
	
	# Get the Black Duck tool project ID
	$ToolProjectID = Get-ToolProjectToken "project" $ToolProjectName $ConnectorID $HostURL $Token

	# Get the Black Duck tool version ID
	$ToolVersionID = Get-ToolVersionToken "version" $ToolProjectID $ToolProjectVersion $ConnectorID $HostURL $Token


	# Update the blank tool connector with the proper configuration info
    $uri = $CDXSERVER + "/x/tool-connector-config/values/" + $ConnectorID

	If($RefreshTime -ne "") {
		$RefreshInterval = @{ daily = $RefreshTime }
	}else {
		$RefreshInterval = $false
	}

	If($ComLocation -ne $true) {
		$ComLocation = $false
	}else {
		$ComLocation = $true
	}

	If($MinSeverity -eq "") {
		$MinSeverity = "info"
	}

    $body = Convertto-Json @{
		project = $ToolProjectID
		version = $ToolVersionID
		"auto-refresh-interval" = $RefreshInterval
		server_url = $HostURL
		auth_type = "api_token"
        api_key = $Token
		matched_files = $ComLocation
        minimum_severity = $MinSeverity
		"available-during-analysis" = $true
    }
    $CreateBlackDuck = Invoke-RestMethod -Uri $uri -Method Put -Body $body -Headers $headers -ContentType "application/json" 
    Write-Verbose ( $CreateBlackDuck | Format-Table | Out-String )

}