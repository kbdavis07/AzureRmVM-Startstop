<#
    .DESCRIPTION
        An example runbook which gets all the Classic VMs in a subscription using the Classic Run As Account (certificate)
		and then outputs the VM name and status

    .NOTES
        AUTHOR: MCS Automation Team
        LASTEDIT: 2017-06-23
#>

param(

#  [Parameter(Mandatory=$true)]
#  [string]
#  $SubscriptionName,
  [Parameter(Mandatory=$true)]
  [string]
  $Servicename,
  [Parameter(Mandatory=$true)]
  [bool]
  $startVM,
  [Parameter(Mandatory=$true)]
  [bool]
  $stopVM
)


$ConnectionAssetName = "AzureClassicRunAsConnection"

# Get the connection
$connection = Get-AutomationConnection -Name $connectionAssetName        

# Authenticate to Azure with certificate
Write-Verbose "Get connection asset: $ConnectionAssetName" -Verbose
$Conn = Get-AutomationConnection -Name $ConnectionAssetName
if ($Conn -eq $null)
{
    throw "Could not retrieve connection asset: $ConnectionAssetName. Assure that this asset exists in the Automation account."
}

$CertificateAssetName = $Conn.CertificateAssetName
Write-Verbose "Getting the certificate: $CertificateAssetName" -Verbose
$AzureCert = Get-AutomationCertificate -Name $CertificateAssetName
if ($AzureCert -eq $null)
{
    throw "Could not retrieve certificate asset: $CertificateAssetName. Assure that this asset exists in the Automation account."
}

Write-Verbose "Authenticating to Azure with certificate." -Verbose
Set-AzureSubscription -SubscriptionName $Conn.SubscriptionName -SubscriptionId $Conn.SubscriptionID -Certificate $AzureCert 
Select-AzureSubscription -SubscriptionId $Conn.SubscriptionID

# Get all VMs in the subscription and write out VM name and status
$VMs = Get-AzureVm  -ServiceName $Servicename
ForEach ($VM in $VMs)
{
   
    #Get vm power status
    $vmstatus = $VM.PowerState
    $vmname = $VM.Name 
     Write-Output ("Classic VM " + $vmname + " has status " +  $vmstatus)
     if($vmstatus -eq "Stopped" -and $startVM -eq $true)
    {
     # VM is turned off
     Write-Output "starting vm $vmname"
     Start-AzureVM -Name $vmname -ServiceName $Servicename
     Write-Output "started vm $vmname"
    } 
    if($vmstatus -eq "Started" -and $stopVM -eq $true)
    {
    # VM is turned on
     Write-Output "stopping vm $vmname"
     Stop-AzureRmVM -Name $vmname -ServiceName $Servicename -Force
     Write-Output "stopped vm $vmname"
     }         


}
