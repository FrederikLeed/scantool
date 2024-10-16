# PowerShell Script to Create an Array of Strings of All Domains in a Forest

# Ensure the Active Directory module is loaded
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "Active Directory module is not available. Please install RSAT tools."
    exit
}

# Import the Active Directory module
Import-Module ActiveDirectory

# Try to retrieve the forest and domain information
try {
    $forest = Get-ADForest
    $domains = $forest.Domains
    $domainNames = @($domains)  # Directly assign domains to the array
} catch {
    Write-Error "Failed to retrieve domain information: $_"
    exit
}

# Get the directory where the script is running
$SHBaseDir = Split-Path -Parent $PSCommandPath

# Bloodhound configuration
$zipFilePath = "$SHBaseDir\sharphound-v2.4.1.zip"
$destinationPath = "$SHBaseDir\sharphound-v2.4.1"
$sharphoundPath = "$destinationPath\Sharphound.exe"
$OutputDirectory =  "$SHBaseDir\scans"

# Check if "scans" directory exists, and create it if not
if (-not (Test-Path -Path $OutputDirectory)) {
    Write-Host "Output directory 'scans' not found. Creating directory..."
    try {
        New-Item -Path $OutputDirectory -ItemType Directory
        Write-Host "'scans' directory created at: $OutputDirectory"
    } catch {
        Write-Error "Failed to create 'scans' directory: $_. Exception: $($_.Exception.Message)"
        exit
    }
} else {
    Write-Host "'scans' directory already exists at: $OutputDirectory"
}

# Check if Sharphound.exe exists, extract from ZIP if missing
if (-not (Test-Path -Path $sharphoundPath)) {
    Write-Host "Sharphound.exe not found. Attempting to extract from ZIP..."
    try {
        Expand-Archive -Path $zipFilePath -DestinationPath $destinationPath -Force
        Write-Host "Extraction successful: $destinationPath"
    } catch {
        Write-Error "Failed to extract ZIP file: $_. Exception: $($_.Exception.Message)"
        exit
    }
} else {
    Write-Host "Sharphound.exe found: $sharphoundPath"
}

# Scan each domain with Sharphound
$domainNames | ForEach-Object {
    $domainName = $_
    Write-Host "Starting scan for $domainName"
    
    Invoke-Command -ScriptBlock {
        param($domainName)
        & "$using:destinationPath\Sharphound.exe" --CollectionMethods DCOnly --Domain $domainName --OutputPrefix $domainName --NoZip --OutputDirectory $using:OutputDirectory
    } -ArgumentList $domainName
}
