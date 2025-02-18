
<#PSScriptInfo

.VERSION 1.0

.GUID 2eee8ead-d4a6-43f2-a295-db545aa76530

.AUTHOR June Castillote

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI https://github.com/junecastillote/M365-User-License-Assignment-Type-by-Sku

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<#

.DESCRIPTION
Get Microsoft 365 users license assignment type by Sku

.SYNOPSIS
Get Microsoft 365 users license assignment type by Sku

.EXAMPLE

$result = .\Get-UserLicenseAssignmentBySku.ps1 -SkuPartNumber SPE_E5

Finding the Sku Id for SPE_E5
Getting all users with [06ebc4ee-1bb5-47dd-8120-11324bc54e06 | SPE_E5] license...
Checking license assignment type (Direct or Inherited)

License     : 06ebc4ee-1bb5-47dd-8120-11324bc54e06 | SPE_E5
Assigned    : 3970
Direct      : 14
Inherited   : 3956

This command gets all users with Microsoft 365 E5 license assigned and store the output to the $result variable.

.EXAMPLE

.\Get-UserLicenseAssignmentBySku.ps1 -SkuPartNumber SPE_E5 | Export-Csv .\result.csv -NoTypeInformation

This command gets all users with Microsoft 365 E5 license assigned and exports the result to a CSV file called result.csv

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String]
    $SkuPartNumber
)

if (!(Get-Module Microsoft.Graph.Authentication)) {
    "ERROR: Connect to Microsoft Graph PowerShell first with the following minimum permissions: LicenseAssignment.Read.All, User.ReadBasic.All" | Out-Default
    return $null
}

if (!(Get-MgContext)) {
    "ERROR: Connect to Microsoft Graph PowerShell first with the following minimum permissions: LicenseAssignment.Read.All, User.ReadBasic.All" | Out-Default
    return $null
}

# Find the Sku Id ('SPE_E5' = Microsoft 365 E5). Refer to "https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference"
"Finding the Sku Id for $SkuPartNumber" | Out-Default
try {
    $sku = Get-MgSubscribedSku -ErrorAction Stop | Where-Object { $_.SkuPartNumber -eq $SkuPartNumber }
}
catch {
    "ERROR: $($_.Exception.Message)" | Out-Default
    return $null
}


# Verify SKU exists. Exit if not.
if (!$sku) {
    "SKU [$($SkuPartNumber)] does not exist in the tenant." | Out-Default
    "Refer to 'https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference' for the list of valid SKUs." | Out-Default
    "Or run Get-MgSubscribedSku" | Out-Default
    return $null
}

# Get all users with the specified license.
$property_set = @('id', 'UserPrincipalName', 'DisplayName', 'Mail', 'LicenseAssignmentStates', 'AssignedLicenses')

"Getting all users with [$($sku.SkuId) | $($sku.SkuPartNumber)] license..." | Out-Default
try {
    $licensed_users = @(Get-MgUser -All -Select $property_set -ErrorAction Stop | Where-Object { @($_.AssignedLicenses.SkuId) -contains $sku.SkuId } | Select-Object $property_set)
}
catch {
    "ERROR: $($_.Exception.Message)" | Out-Default
    return $null
}


if ($licensed_users.Count -lt 1) {
    "No users were found with [$($sku.SkuId) | $($sku.SkuPartNumber)] license assigned." | Out-Default
    return $null
}

# Determine direct or inheritec license assignment
$result = [System.Collections.Generic.List[System.Object]]@()
"Checking license assignment type (Direct or Inherited)" | Out-Default
foreach ($user in ($licensed_users | Sort-Object DisplayName)) {
    $license_state = $user.LicenseAssignmentStates | Where-Object { $_.SkuId -eq $sku.SkuId }
    $result.Add(
        [PSCustomObject](
            [ordered]@{
                Username          = $user.UserPrincipalName
                DisplayName       = $user.DisplayName
                Mail              = $user.Mail
                License           = "$($sku.SkuId) | $($sku.SkuPartNumber)"
                LicenseAssignment = $(
                    if (-not([string]::IsNullOrEmpty($license_state.AssignedByGroup))) {
                        "Inherited"
                    }
                    else {
                        "Direct"
                    }
                )
                LicenseGroup = $($license_state.AssignedByGroup -join ";")
            }
        )
    )
}

$result

# Display summary
"" | Out-Default
"License     : $($sku.SkuId) | $($sku.SkuPartNumber)" | Out-Default
"Assigned    : $($licensed_users.Count)" | Out-Default
"Direct      : $(($result | Where-Object {$_.LicenseAssignment -eq 'Direct'}).Count)" | Out-Default
"Inherited   : $(($result | Where-Object {$_.LicenseAssignment -eq 'Inherited'}).Count)" | Out-Default
"" | Out-Default


