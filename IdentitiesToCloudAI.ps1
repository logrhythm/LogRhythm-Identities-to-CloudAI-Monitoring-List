# ###########################################
#
# LogRhythm Identities to CloudAI Monitoring List
# IdentitiesToCloudAI.ps1
#
# ###############
#
# (c) 2020, LogRhythm
#
# ###############
#
# Change Log:
#
# v0.4 - 2020-10-01 - Tony Massé (tony.masse@logrhythm.com)
# - Prompt user for configuration
# - Save Config file
# - load Config file
# - Logging
# - Error handling
#
# v0.3 - 2020-09-30 - Tony Massé (tony.masse@logrhythm.com)
# - Command line parameters
# - Adding new Identities to List
# - Synchronising (Add new & Remove old) Identities to List
#
# v0.2 - 2020-09-29 - Tony Massé (tony.masse@logrhythm.com)
# - Pulling Identities
# - Mapping Users to Identities
#
# v0.1 - 2020-09-28 - Tony Massé (tony.masse@logrhythm.com)
# - Pulling A/D users based on given Group
# - Pulling LogRhythm list and its content
#
# ################
#
# TO DO
#
# ################

# ###########################
# Declaring the parameters
# ###########################

param (
     [Parameter(Mandatory = $false, Position = 0)]
     [string]$GroupToBringIn = ''

    ,[Parameter(Mandatory = $false, Position = 1)]
     [ValidateSet('AddNewOnesOnly', 'Synchronise', ignorecase=$true)]
     [string]$Action = 'Synchronise'

    ,[Parameter(Mandatory = $false, Position = 2)]
     [string]$LogrhythmListName = 'CloudAI: Monitored Identities'

    ,[Parameter(Mandatory = $false, Position = 3)]
     [switch]$CreateConfiguration = $false
)

# ###########################
# Import required Modules
# ###########################

Import-Module LogRhythm.Tools
Import-Module ActiveDirectory

# ###########################
# Declaring all the variables
# ###########################

# Version
$Version = "v0.4 - 2020-10-01 - Tony Masse (tony.masse@logrhythm.com)"

# Logging level
$Logginglevel = @{"INFO" = $true; # Default: True
                  "ERROR" = $true; # Default: True
                  "VERBOSE" = $true;  # Default: False
                  "DEBUG" = $true; # Default: False
                 }


# Directories and files information
# Base directory and Script name
$ScriptFileFullName = $MyInvocation.MyCommand.Path
$basePath = Split-Path $ScriptFileFullName
$ScriptFileName = $MyInvocation.MyCommand.Name

cd $basePath

# Config directory and file
$configPath = Join-Path -Path $basePath -ChildPath "config"
if (-Not (Test-Path $configPath))
{
	New-Item -ItemType directory -Path $configPath | out-null
}

$configFile = Join-Path -Path $configPath -ChildPath "config.json"

# Log directory and file
$logsPath = Join-Path -Path $basePath -ChildPath "logs"
if (-Not (Test-Path $logsPath))
{
	New-Item -ItemType directory -Path $logsPath | out-null
}

# For the Diagnostics (logs from this script)
$logFileBaseName = "LogRhythm.LogVolumesExporter."
$logFile = Join-Path -Path $logsPath -ChildPath ($logFileBaseName + (Get-Date).tostring("yyyyMMdd") + ".log")
if (-Not (Test-Path $logFile))
{
	New-Item $logFile -type file | out-null
}

# ###########################
# Declaring all the functions
# ###########################


# #################
# Logging functions
function Log-Message
{
    param
    (
        [string] $logLevel = "INFO",
        [string] $message,
        [Switch] $NotToFile = $False,
        [Switch] $NotToConsole = $False,
        [Switch] $NotToLogFile = $False,
        [Switch] $RAW = $False
    )

    if ($Logginglevel."$logLevel")
        {

        if ($RAW)
        {
            $Msg  = $message
        }
        else
        {
            $Msg  = ([string]::Format("{0}|{1}|{2}", (Get-Date).tostring("yyyy.MM.dd HH:mm:ss"), $logLevel, $message))
        }

	    if (-not($NotToFile)) 
        {
    	    if (-not($NotToLogFile))  { $Msg | Out-File -FilePath $logFile  -Append }
        }
        if (-not($NotToConsole)) { Write-Host $Msg }
    }
}

function Log-Info
{
    param
    (
        [string] $message,
        [Switch] $NotToFile = $False,
        [Switch] $NotToConsole = $False,
        [Switch] $NotToLogFile = $False
    )
    Log-Message -logLevel "INFO" @PSBoundParameters
}

function Log-Verbose
{
    param
    (
        [string] $message,
        [Switch] $NotToFile = $False,
        [Switch] $NotToConsole = $False,
        [Switch] $NotToLogFile = $False
    )
    Log-Message -logLevel "VERBOSE" @PSBoundParameters
}

function Log-Error
{
    param
    (
        [string] $message,
        [Switch] $NotToFile = $False,
        [Switch] $NotToConsole = $False,
        [Switch] $NotToLogFile = $False
    )
    Log-Message -logLevel "ERROR" @PSBoundParameters
}

function Log-Debug
{
    param
    (
        [string] $message,
        [Switch] $NotToFile = $False,
        [Switch] $NotToConsole = $False,
        [Switch] $NotToLogFile = $False
    )
    Log-Message -logLevel "DEBUG" @PSBoundParameters
}

function Prompt-User
{
	param( 
		[string] [Parameter(Mandatory=$true)] $Prompt
		,[string] [Parameter(Mandatory=$false)] $PopupTitle = ''
		,[string] [Parameter(Mandatory=$false)] $DefaultValue = ''
		,[string[]] [Parameter(Mandatory=$false)] $ValueOptions = @()
		,[switch] [Parameter(Mandatory=$false)] $UseTextOnly = $false
		,[switch] [Parameter(Mandatory=$false)] $CaseInsensitive = $false
		,[switch] [Parameter(Mandatory=$false)] $DoNotTrim = $false
		,[switch] [Parameter(Mandatory=$false)] $SecureString = $false
		,[switch] [Parameter(Mandatory=$false)] $ReturnAsEncryptedString = $false
		,[switch] [Parameter(Mandatory=$false)] $ReturnAsPlainString = $false

	)

    if ($SecureString)
    {
        $UseTextOnly = $true
    }

    if (-Not $UseTextOnly)
    {
        try
        {
            Add-Type -AssemblyName Microsoft.VisualBasic
        }
        catch
        {
            $UseTextOnly = $true
        }
    }

    # Prepare the Options
    $OptionsText = ''
    if ($ValueOptions.length -gt 0)
    {
        if ($UseTextOnly)
        {
            $OptionsText += ' ( Options: '
            $Separator = ''
	        ForEach ($ValueOption in $ValueOptions) {
                $OptionsText += $Separator + $ValueOption
                $Separator = ' / '
   	        }
            if ($DefaultValue -ne '')
            {
                $OptionsText += $Separator + 'or press [Enter] to keep current value of "' + $DefaultValue + '"'
            }
            $OptionsText += ' )'
        }
        else
        {
            $OptionsText += "`n`nOptions:"
	        ForEach ($ValueOption in $ValueOptions) {
                $OptionsText += "`n - " + $ValueOption
   	        }
        }
    }
    else
    {
        if ($DefaultValue -ne '')
        {
            $OptionsText += ' ( or press [Enter] to keep current value of "' + $DefaultValue + '" )'
        }
    }

    # Prompt the user
    if ($UseTextOnly)
    {
        # If a title was provided, add a separator between it and the Prompt itself
        $TitleSeparator = ''
        if ($PopupTitle -ne '')
        {
            $TitleSeparator = ' | '
        }
        if ($SecureString)
        {
            $input = $( Read-Host ($PopupTitle + $TitleSeparator + $Prompt + $OptionsText) -AsSecureString )
        }
        else
        {
            $input = $( Read-Host ($PopupTitle + $TitleSeparator + $Prompt + $OptionsText) )
        }
        if ($DefaultValue -ne '' -And $input -eq '')
        {
            $input = $DefaultValue
        }
    }
    else
    {
        if ($PopupTitle -eq '')
        {
            $PopupTitle = ' ' # To prevent the ugly "Anonymously Hosted DynamicMethods Assembly" auto generated Pop-up Title :)
        }
        $input = $( [Microsoft.VisualBasic.Interaction]::InputBox($Prompt + $OptionsText, $PopupTitle, $DefaultValue) )
    }

    if ($SecureString)
    {
        if ($ReturnAsEncryptedString)
        {
            $input = ConvertFrom-SecureString -SecureString $input
        }
        elseif ($ReturnAsPlainString)
        {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($input) 
            $input = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            $BSTR = $null
        }
    }
    else
    {
        # Bring it to Lower Case
        if ($CaseInsensitive)
        {
            $input = $input.ToLower()
        }

        # Trim (both ends), unless asked not to
        if (-Not $DoNotTrim)
        {
            $input = $input.Trim()
        }
    }
    return $input
}

function StringToBool
{
	param( 
		[string] [Parameter(Mandatory=$true)] $String
	)

    try
    {
        if ($String.substring(0, 1).ToUpper() -eq 'Y')
        {
            return $true
        }
    }
    catch
    {
    }

    return $false
}

# ################################################
# ################################################
# ################################################


# ################################################
# Starting LogRhythm Identities to CloudAI Monitoring List

Log-Info -message "Starting LogRhythm Identities to CloudAI Monitoring List"
Log-Info "Version: ", $Version


# ###################
# Reading config file
if (-Not (Test-Path $configFile))
{
    if ($CreateConfiguration)
    {
	    Log-Info "File 'config.json' doesn't exists. Starting with fresh config"
    }
    else
    {
	    Log-Error "File 'config.json' doesn't exists. Exiting"
	    return
    }
}
else
{
    Log-Info "File 'config.json' exists."
}

try
{
    if (-Not (Test-Path $configFile) -and $CreateConfiguration)
    {
        $configJson = @{}
    }
    else
    {
	    $configJson = Get-Content -Raw -Path $configFile | ConvertFrom-Json
    }
	ForEach ($attribute in @("Configuration Generated", "KeepOldLogFilesForDays")) {
		if (-Not (Get-Member -inputobject $configJson -name $attribute -Membertype Properties) -Or [string]::IsNullOrEmpty($configJson.$attribute))
		{
            if ((-Not $CreateConfiguration) -and ($attribute -ne "Configuration Generated"))
            {
			    Log-Error ($attribute + " has not been specified in 'config.json' file. Exiting")
			    return
            }
            else
            {
                try
                {
                    $configJson | Add-Member -NotePropertyName $attribute -NotePropertyValue @{}


                    if ($attribute -eq 'KeepOldLogFilesForDays')
                    {
                        $configJson.KeepOldLogFilesForDays = [int] (Prompt-User -Prompt "How many days to you want to keep the diagnostic logs of this tool?" -DefaultValue '35' -PopupTitle ("Configuration: {0}" -f $attribute))
                    }
                    # ####################
                    # Save the file so far
                    try
                    {
                        $configJson.'Configuration Generated' = @{"By" = ("Logrhythm Identities to CloudAI Monitoring List - Version {0}" -f $Version)
                                                                ; "Automatically" = $true
                                                                ; "At" = (Get-Date).tostring("yyyy.MM.dd HH:mm:ss zzz")
                                                                ; "For" = ("Logrhythm Identities to CloudAI Monitoring List - Version {0}" -f $Version)
                                                                ; "By User" = $env:USERNAME }

                        Log-Info "Saving to 'config.json' file..."
                        if (-Not (Test-Path $configFile))
                        {
                            Log-Info "File 'config.json' doesn't exist. Creating it..."
	                        New-Item $configFile -type file | out-null
                        }
                        # Write the Config into the Config file
                        $configJson | ConvertTo-Json -Depth 5 | Out-File -FilePath $configFile     
                        Log-Info "Configuration saved."
                    }
                    catch
                    {
                        Log-Error ("Failed to save config.json. Reason: {0}" -f $Error[0])
                    }

                }
                catch
                {
                	Log-Error ("Could not add branch {0} to the configuration. Skipping. Reason: {1}" -f $attribute, $Error[0])
                }

            }
		}
	}
    Log-Info "File 'config.json' parsed correctly."
}
catch
{
	Log-Error ("Could not parse 'config.json' file. Exiting. Reason: {0}" -f $Error[0])
	return
}

if ($CreateConfiguration)
{
    # Job done. Leaving you now.
    return
}


# ###################################
# Delete Log files older than X days.
# Limit to at least 0 days, and maximum 1 year + 1 day
try
{
    if ($configJson.KeepOldLogFilesForDays -lt 0) { $configJson.KeepOldLogFilesForDays = 0 }
    if ($configJson.KeepOldLogFilesForDays -gt 366) { $configJson.KeepOldLogFilesForDays = 366 }
	Log-Info ("Delete Log files older than {0} days..." -f $configJson.KeepOldLogFilesForDays.ToString("D"))
    Get-ChildItem -Path $logsPath -include ($logFileBaseName + "*") | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-$configJson.KeepOldLogFilesForDays) } | Remove-Item
}
catch
{
	Log-Error ("Failed to delete old log files. Reason: {0}" -f $Error[0])
}


Log-Info 'Users - Getting them from A/D'

# #############################
# Get the list of users
# Directly from A/D using Get-ADUser

# Set filter
if ($GroupToBringIn.Length -gt 0)
{
    $Filter = "memberOf -eq '$GroupToBringIn'"
}
else
{
    $Filter = "*"
}
Log-Verbose ("Using filter: ""{0}""" -f $Filter)

try
{
    $UsersToBringIn = Get-ADUser -Filter $Filter -Properties * | select SAMAccountName, UserPrincipalName, mail
    Log-Info ("Number of Users to bring in: {0}" -f $UsersToBringIn.Count)
}
catch
{
    Log-Error ("Failed to get users from Active Directory. Reason: {0}" -f $Error[0])
    exit 20
}

Log-Info 'Users - Extract Identifiers'

$UsersToBringInIdentifiers = New-Object System.Collections.ArrayList
try
{
    $UsersToBringIn | ForEach-Object {
        if ($_.mail.length -gt 0)
        {
            $UsersToBringInIdentifiers.Add($_.mail) > $null
            # Write-Host '@' -NoNewline
        }
        if ($_.UserPrincipalName.length -gt 0)
        {
            $UsersToBringInIdentifiers.Add($_.UserPrincipalName) > $null
            # Write-Host '.' -NoNewline
        }
    }
}
catch
{
    Log-Error ("Failed to extract identifiers for users. Reason: {0}" -f $Error[0])
}
Log-Info ("Number of Identifiers found: {0}" -f $UsersToBringInIdentifiers.Count)

Log-Info 'LogRhythm List - Fetch List'
try
{
    $List = Get-LrList -Name $LogrhythmListName -Exact
    if ($List.name.Length -ne 0)
    {
        Log-Info ("List found. Name: ""{1}""." -f $List.Count, $List.name)
    }
    else
    {
        Log-Error "List not found. Exiting."
        exit 20
    }
}
catch
{
    Log-Error ("Failed to fetch List from LogRhythm. Exiting. Reason: {0}" -f $Error[0])
    exit 20
}

Log-Info 'LogRhythm List - Compile values into simple list'
$ListItemsId = New-Object System.Collections.ArrayList
try
{
    $List.items | ForEach-Object {
        if ($_.value -ne $null)
        {
            $ListItemsId.Add($_.value) > $null
        }
    }
}
catch
{
    Log-Error ("Failed to compile List's values. Reason: {0}" -f $Error[0])
}


Log-Info 'LogRhythm Identities - Get Identities from LogRhythm appliance'

try
{
    $Identities = Get-LrIdentities
}
catch
{
    Log-Error ("Failed to fetch Identities from LogRhythm. Reason: {0}" -f $Error[0])
}
Log-Info ("Number of Identities found: {0}" -f $Identities.Count)

Log-Info 'LogRhythm Identities - Map to Users to Bring in '
try
{
    $IdentitiesToBringIn = $Identities | Where-Object { $_.displayIdentifier.ToLower() -in $UsersToBringInIdentifiers } # | select  identityID, nameFirst, nameLast, groups # Works
}
catch
{
    Log-Error ("Failed to map Users to Identities. Reason: {0}" -f $Error[0])
}
Log-Info ("Number of Identities to bring in: {0}" -f $IdentitiesToBringIn.Count)

$ItemsAdded = 0
$ItemsRemoved = 0

switch ($Action.ToUpper()) { 
    ("AddNewOnesOnly").ToUpper() {
        try
        {
            Log-Info 'Identities > List - Add only new Identities to List'
            Write-Host "Adding items: " -NoNewline
            $IdentitiesToBringIn | ForEach-Object {
                if ($_.identityID -notin $ListItemsId)
                {
                    Add-LrListItem -Name $LogrhythmListName -Value $_.identityID -ItemType "Identity" > $null
                    Write-Host "+" -NoNewline -ForegroundColor Green
                    $ItemsAdded++
                }
            }
        }
        catch
        {
            Log-Error ("Failed to add Identities to LogRhythm's List. Reason: {0}" -f $Error[0])
        }
        Write-Host ""
        break
    } 
    ("Synchronise").ToUpper() {
        Log-Info 'Identities > List - Synchronise List (Remove non-provided Identities and Add new ones)'
        $IdentityIDList = New-Object System.Collections.ArrayList
        $IdentitiesToBringIn | ForEach-Object {
            $IdentityIDList.Add($_.identityID) > $null
        }

        try
        {
            Write-Host 'Removing items: ' -NoNewline
            $ListItemsId | ForEach-Object {
                if ($_ -notin $IdentityIDList)
                {
                    Remove-LrListItem -Name $LogrhythmListName -Value $_ -ItemType "Identity" > $null
                    Write-Verbose ("Removing '{0}' from list" -f $_)
                    Write-Host '-' -NoNewline -ForegroundColor Red
                    $ItemsRemoved++
                }
            }
        }
        catch
        {
            Log-Error ("Failed to remove Identities from LogRhythm's List. Reason: {0}" -f $Error[0])
        }

        try
        {
            Write-Host "`nAdding items: " -NoNewline
            $IdentitiesToBringIn | ForEach-Object {
                if ($_.identityID -notin $ListItemsId)
                {
                    Add-LrListItem -Name $LogrhythmListName -Value $_.identityID -ItemType "Identity" > $null
                    Write-Verbose ("Adding {0} to list" -f $_.identityID)
                    Write-Host '+' -NoNewline -ForegroundColor Green
                    $ItemsAdded++
                }
            }
        }
        catch
        {
            Log-Error ("Failed to add Identities to LogRhythm's List. Reason: {0}" -f $Error[0])
        }

        Write-Host ""

        break
    }
    default {
        Write-Error "Unknown Action: ""$Action"". Doing nothing."
        break
    }
}

Log-Info 'DONE'
Log-Info ("Summary - Identities Removed from List: {0}" -f $ItemsRemoved)
Log-Info ("Summary - Identities Added to List: {0}" -f $ItemsAdded)

