# M365 User License Assignment Type by Sku

Get Microsoft 365 users license assignment type by Sku

## Usage Instructions

This script requires connection to Microsoft Graph PowerShell with these minimum permissions: LicenseAssignment.Read.All, User.ReadBasic.All

```PowerShell
Connect-MgGraph -TenantId org_name.onmicrosoft.com -Scopes LicenseAssignment.Read.All, User.ReadBasic.All
```

### Example 1 - Get all users with Microsoft 365 E5 license assigned

```PowerShell
$result = .\Get-UserLicenseAssignmentBySku.ps1 -SkuPartNumber SPE_E5
```

![Example 1 - Get all users with Microsoft 365 E5 license assigned](docs/images/example1.png)

### Example 2 - Get all users with Microsoft 365 E5 license assigned and export to CSV

```PowerShell
$result = .\Get-UserLicenseAssignmentBySku.ps1 -SkuPartNumber SPE_E5
$result | Export-Csv .\result.csv -NoTypeInformation
```

![Example 2 - Get all users with Microsoft 365 E5 license assigned and export to CSV](docs/images/example2_01.png)

![Example 2 - CSV Result](docs/images/example2_02.png)
