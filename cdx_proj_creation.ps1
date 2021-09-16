param(
        [Parameter(Mandatory=$true)]
        [boolean]$CreateProj,
		[Parameter(Mandatory=$true)]
        [string]$ProjectName,
        [Parameter(Mandatory=$true)]
        [string]$BDConnectorName,
        [Parameter(Mandatory=$true)]
        [string]$BDProjectName,
        [Parameter(Mandatory=$true)]
        [string]$BDProjectVersion,
        [Parameter(Mandatory=$true)]
        [string]$BDURL,
        [Parameter(Mandatory=$true)]
        [string]$BDToken,
        [Parameter(Mandatory=$true)]
        [string]$PolarisConnectorName,
        [Parameter(Mandatory=$true)]
        [string]$PolarisProjectName,
        [Parameter(Mandatory=$true)]
        [string]$PolarisProjectBranch,
        [Parameter(Mandatory=$true)]
        [string]$PolarisURL,
        [Parameter(Mandatory=$true)]
        [string]$PolarisToken,
		[Parameter(Mandatory=$false)]
        [string]$ProjectParentId,
        [Parameter(Mandatory=$false)]
        [boolean]$BDComLocation,
        [Parameter(Mandatory=$false)]
        [string]$BDMinSeverity,
        [Parameter(Mandatory=$false)]
        [boolean]$DisableTools,
        [Parameter(Mandatory=$false)]
        [string]$RefreshTime
    )

if ($CreateProj -eq $true){
	Write-Host "Project $ProjectName Creation..."
	$proj = Add-Project $ProjectName
	If($ProjectParentId -ne "") {
		Write-Host "Moving project into group $ProjectParentId..."
		Set-ProjectParent $proj.id $ProjectParentId
	}
}

Write-Host "Black Duck Connector $BDConnectorName Creation..."
Add-BlackDuckConnectorToken $ProjectName $BDConnectorName $BDProjectName $BDProjectVersion $BDURL $BDToken $BDComLocation $BDMinSeverity

Write-Host "Polaris Connector $PolarisConnectorName Creation..."
Add-PolarisConnector $ProjectName $PolarisConnectorName $PolarisProjectName $PolarisProjectBranch $PolarisURL $PolarisToken

if ($DisableTools -eq $true){
	Write-Host "Disable embedded tools"
	$toolIDs = @(17, 48, 49, 181, 952, 297, 331, 346, 414, 537, 881, 888, 915, 920, 927)
	Foreach ($toolID in $toolIDs){
		Disable-ToolConfig $toolID $proj.id
	}
}

Write-Host "All Done"

return $proj.id