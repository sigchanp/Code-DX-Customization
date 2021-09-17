PowerShell module is based on https://www.powershellgallery.com/packages/codedx/1.9.5

		Install-Module -Name codedx
    Get-Module -ListAvailable
    
    Set-ExecutionPolicy Unrestricted
    
    # Add the following Environmental vars to your system for ease of use:
		# CDXAPI = yourapikey
		# CDXURL = http://yourhost/codedx
    
    *put new function files in installation location (e.g. C:\Program Files\WindowsPowerShell\Modules\codedx\1.9.5\functions) and add the function name to psd1 FunctionsToExport*
    
    Import-Module -name codedx -Force -Verbose
    
    Then execute the function in PowerShell (e.g. Add-Project test)
