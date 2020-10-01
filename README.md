# LogRhythm Identities to CloudAI Monitoring List

A quick tool to help customers with rather large number of users to push to CloudAI. You put them in a Group (in A/D), then use this tool to sync up with the Group in question.A quick tool to help customers with rather large number of users to push to CloudAI. You put them in a Group (in A/D), then use this tool to sync up with the Group in question.

## Kick-start:

`.\IndentitiesToCloudAI.ps1 -CreateConfiguration`

`.\IndentitiesToCloudAI.ps1 -GroupToBringIn "CN=My Group Of Users,OU=Groups,DC=my,DC=sexy,DC=domain,DC=com"`

## Dependencies

This requires:
- [Logrhythm.Tools](https://github.com/LogRhythm-Tools/LogRhythm.Tools)
	- Publishers: some cool LogRhythm enthusiasts
	- Releases: https://github.com/LogRhythm-Tools/LogRhythm.Tools/releases
- [ActiveDirectory](https://docs.microsoft.com/en-us/powershell/module/addsadministration/)
	- Publisher: Microsoft

## Usage examples:

- To create the Configuration file:

`.\IndentitiesToCloudAI.ps1 -CreateConfiguration`

- To get all your existing user Identities that exist in the Active Directory Group *`My Group Of Users`* added to the default *`CloudAI: Monitored Identities`* LogRhythm List

`.\IndentitiesToCloudAI.ps1 -GroupToBringIn "CN=My Group Of Users,OU=Groups,DC=my,DC=sexy,DC=domain,DC=com"`

**This is equivalent to:**

`.\IndentitiesToCloudAI.ps1 -GroupToBringIn "CN=My Group Of Users,OU=Groups,DC=my,DC=sexy,DC=domain,DC=com"  -Action Synchronise`

**-or-**

`.\IndentitiesToCloudAI.ps1 -GroupToBringIn "CN=My Group Of Users,OU=Groups,DC=my,DC=sexy,DC=domain,DC=com"  -LogrhythmListName "CloudAI: Monitored Identities"`

**-or-**

`.\IndentitiesToCloudAI.ps1 -GroupToBringIn "CN=My Group Of Users,OU=Groups,DC=my,DC=sexy,DC=domain,DC=com"  -Action Synchronise -LogrhythmListName "CloudAI: Monitored Identities"`

- To get all **only the new users** (well, their Identities, if they exist) from Group `My Group Of Users` added to the default LogRhythm List (**without removing** any old entry that is not in the Group currently)

`.\IndentitiesToCloudAI.ps1 -GroupToBringIn "CN=My Group Of Users,OU=Groups,DC=my,DC=sexy,DC=domain,DC=com"  -Action AddNewOnesOnly`

- To get **all your existing user Identities that exist in the Active Directory domain** added to the default LogRhythm List

`.\IndentitiesToCloudAI.ps1`

## Parameters:

- **`-CreateConfiguration`**
	- Mandatory: *No*
	- Default: *False*
	- What does it do?
		- Prompt the user and create the configuration file (which you can then find under `config/config.json`)
		- You can re-run this command any time, but it will only prompt for the parts that are missing in the `config.json` file
		- Feel free to edit the `config/config.json` file directly after

- **`-GroupToBringIn`**
	- Mandatory: *No*
	- Default: *Empty*
	- What does it do?
		- Specify which group to pull from Active Directory (ie. `-Filter "memberOf -eq '$GroupToBringIn'"`)
		- If not provided, the tool will pull all the users from Active Directory (ie. `-Filter "*"`)

- **`-Action`**
	- Mandatory: *No*
	- Default: *Synchronise*
	- Accepted values:
		- `AddNewOnesOnly`
		- `Synchronise`
	- What does it do?
		- Decide to either:
	 		- `AddNewOnesOnly`
		 		- only add Identities that are not yet in the List
			- `Synchronise`
				- remove old entries from the List that are not in the Entities
				- add new Identities that are not yet in the List
- **`-LogrhythmListName`**
	- Mandatory: *No*
	- Default: *'CloudAI: Monitored Identities'*
	- What does it do?
		- Specifies the name **exact** of the LogRhythm List to update
