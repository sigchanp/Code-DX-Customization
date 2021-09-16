<#
.SYNOPSIS
 
Create a single Polaris connector
 
.DESCRIPTION
Adds a single Polaris connector using the tool connector config API endpoints
 
.EXAMPLE
Add-PolarisConnector "selected_project" Polaris_Connector "myProject" latest https://samplehostname.polaris.synopsys.com/ nroa9tbbk64rt94qgkq81502n18cf454g0tiqlmqu6l3tbj5br50

Output (entry ID)

 
#>

Function Add-PolarisConnector
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
        [string]$ToolProjectBranch,
        [Parameter(Mandatory=$true)]
        [string]$HostURL,
        [Parameter(Mandatory=$true)]
        [string]$Token,
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
	$ConnectorInfo = Add-BlankConnector $ProjectID "Polaris" $NewConnectorName
	$ConnectorID = $ConnectorInfo.id
    
	
	# Get the Black Duck tool project ID
	$ToolProjectID = Get-ToolProjectToken "project" $ToolProjectName $ConnectorID $HostURL $Token

	# Get the Black Duck tool version ID
	$ToolVersionID = Get-ToolVersionToken "branch" $ToolProjectID $ToolProjectBranch $ConnectorID $HostURL $Token


	# Update the blank tool connector with the proper configuration info
    $uri = $CDXSERVER + "/x/tool-connector-config/values/" + $ConnectorID

	If($RefreshTime -ne "") {
		$RefreshInterval = @{ daily = $RefreshTime }
	}else {
		$RefreshInterval = $false
	}

    $body = Convertto-Json @{
		project = $ToolProjectID
		branch = $ToolVersionID
		connector_mode = "project"
		"auto-refresh-interval" = $RefreshInterval
		server_url = $HostURL
        api_token = $Token
		"available-during-analysis" = $true
    }
    $CreatePolaris = Invoke-RestMethod -Uri $uri -Method Put -Body $body -Headers $headers -ContentType "application/json" 
    Write-Verbose ( $CreatePolaris | Format-Table | Out-String )

}