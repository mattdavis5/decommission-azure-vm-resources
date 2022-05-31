# This script will prompt the user for an Azure virtual machine name, and delete the VM and any of the following objects related to the VM: network interface, public IP address, network security group, data disk(s), OS disk

Import-Module -Name Az


# Connect to an Azure Account
try 
{
    Connect-AzAccount
}
catch 
{
    Write-Host "Could not connect to an Azure account"
    exit
}

# Prompt user to enter an existing Azure virtual machine, exit the loop only when a valid virtual machine is entered
while ($true) 
{
    #Get VM Name from User
    $VMName = Read-Host("Enter the name of the Azure virtual machine to delete")

    #Verify Azure VM exists using Get-AzVM command
    #Get-AzVM retrieves VM properties to be used for variables later in this script
    $VM = Get-AzVM -Name $VMName

    if (!$VM)
    {
        Write-Host "Please enter a valid Azure virtual machine name"
    }
    else
    {
        break
    }
}


# Get OS disk name from VM's properties
$OSDiskName = $VM.StorageProfile.OsDisk.Name

# Delete Option - describes delete behavior of network interface, disks when a VM is deleted; values are 'Delete' (delete object) or 'Detach' (object is not deleted when VM is deleted)
# Get OS disk delete option from VM's properties
$OSDiskDeleteOption = $VM.StorageProfile.OsDisk.DeleteOption

Write-Host "`nOS disk name: " $OSDiskName
Write-Host "OS disk delete option: "$OSDiskDeleteOption

# Prompt user whether to delete OS disk
$DeleteOSDisk = Read-Host("Do you want to delete the OS disk? Y/N")


# Get data disk names from VM's properties
$DataDiskName = $VM.StorageProfile.DataDisks.Name

$DataDiskCount = $VM.StorageProfile.DataDisks.Count
Write-Host "`nThere are "$DataDiskCount "disks associated with " $VM.Name

# If data disks are associated with the VM, list them and prompt the user whether to delete them or not
if($DataDiskCount -gt 0)
{
    Write-Host "Data disk names: '$DataDiskName'"

    # Delete Option - describes delete behavior of network interface, disks when a VM is deleted; values are 'Delete' (delete object) or 'Detach' (object is not deleted when VM is deleted)
    # Get data disk delete option from VM's properties
    $DataDiskDeleteOption = $VM.StorageProfile.DataDisks.DeleteOption[0]
    Write-Host "Data disk delete option: " $DataDiskDeleteOption
    
    # Prompt user whether to delete data disk
    $DeleteDataDisk = Read-Host("Do you want to delete the data disk(s)? Y/N")
}
else
{
    Write-Host "There are no data disks associated with '$VMName'"
}


# Get network interface name from VM's properties
$NIName = $VM.NetworkProfile.NetworkInterfaces.Id.Split('/')[-1]
Write-Host "`nNetwork interface name: " $NIName

# Delete Option - describes delete behavior of network interface, disks when a VM is deleted; values are 'Delete' (delete object) or 'Detach' (object is not deleted when VM is deleted)
# Get network interface delete option from VM's properties
$NIDeleteOption = $VM.NetworkProfile.NetworkInterfaces.DeleteOption
Write-Host "Network interface delete option: " $NIDeleteOption

# Prompt user whether to delete network interface
$DeleteNI = Read-Host("Do you want to delete the network interface? Y/N")

$NetworkInterface = Get-AzNetworkInterface -Name $NIName


# Get public IP name from network interface properties
$PublicIPName = $NetworkInterface.IpConfigurations.PublicIpAddress.Id.Split('/')[-1]

# Retrieve public IP properties
$PublicIP = Get-AzPublicIpAddress -ResourceGroupName $VM.ResourceGroupName -Name $PublicIPName

# If a public IP is associated with the VM, list the IP and prompt the user whether to delete it or not
if(!$PublicIP)
{
    Write-Host "There are no public IP addresses associated with '$VMName'"
}
else
{
    Write-Host "`nPublic IP name: " $PublicIP.Name
    Write-Host "Public IP: " $PublicIP.IpAddress
    
    # Delete Option - describes delete behavior of network interface, disks when a VM is deleted; values are 'Delete' (delete object) or 'Detach' (object is not deleted when VM is deleted)
    # Get network interface delete option from VM's properties
    $PublicIPDeleteOption = $VM.NetworkProfile.NetworkInterfaces.DeleteOption
    Write-Host "Public IP delete option: " $PublicIPDeleteOption
    
    # Prompt user whether to delete network interface
    $DeletePublicIP = Read-Host("Do you want to delete the public IP address? Y/N")
}


# Get network security group name from VM's properties
$NSGName = $NetworkInterface.NetworkSecurityGroup.Id.Split('/')[-1]
Write-Host "`nNetwork security group name: " $NSGName

$NetworkSecurityGroup = Get-AzNetworkSecurityGroup -Name $NSGName

# If a network security group is associated with the VM, prompt the user whether to delete it or not
if(!$NetworkSecurityGroup)
{
    Write-Host "There are no network security groups associated with '$VMName'"
}
else
{
    # Prompt user whether to delete network security group
    $DeleteNSG = Read-Host("Do you want to delete the network security group? Y/N")
}



# Delete Azure virtual machine
try 
{
    Write-Host "`nStopping and deleting the Azure VM '$VMName'"
    Stop-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name
    Remove-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name
}
catch 
{
    Write-Host "Could not delete Azure VM" $VM.Name
}


# If user selects OS disk to be deleted, and the OS disk delete option is to detach it when its connected VM is deleted, delete the OS disk
if ($DeleteOSDisk -eq "Y" -and $OSDiskDeleteOption -eq "Detach") 
{
    Write-Host "`nDeleting the VM OS disk '$OSDiskName'"
    try 
    {
        # Delete OS disk
        Remove-AzDisk -ResourceGroupName $VM.ResourceGroupName -DiskName $OSDiskName
    }
    catch 
    {
        Write-Host "Could not delete OS Disk '$OSDiskName'"
    }
}
# If user selects OS disk to not be deleted, notify user
elseif ($DeleteOSDisk -eq "N") 
{
    Write-Host "`nUser chose to not delete the OS disk '$OSDiskName'"
}
# If the user selects the OS disk to be deleted, and its delete option is "delete", notify the user that Azure will automatically delete this resource with VM
else 
{
    Write-Host "`nThe OS disk '$OSDiskName' will be automatically deleted along with the VM, per its delete option property"
}


# If data disks exist, run deletion conditionals
if ($DataDiskCount -gt 0)
{
    # If user selects data disk(s) to be deleted, and the data disk delete option is to detach it when its connected VM is deleted, delete the data disk(s)
    if ($DeleteDataDisk -eq "Y" -and $DataDiskDeleteOption -eq "Detach") 
    {
        Write-Host "`nDeleting the VM data disk(s) '$DataDiskName'"
        try 
        {
            # Delete each data disk found from VM properties - $VM.StorageProfile.DataDisks.Name
            foreach ($Disk in $DataDiskName) 
            {
                Write-Host "Deleting data disk '$Disk'"
                Remove-AzDisk -ResourceGroupName $VM.ResourceGroupName -DiskName $Disk  
            }
        }
        catch 
        {
            Write-Host "Could not delete Data Disk '$DataDiskName'" 
        }
    }
    # If user selects data disk(s) to not be deleted, notify user
    elseif ($DeleteDataDisk -eq "N") 
    {
        Write-Host "`nUser chose to not delete the data disk(s) '$DataDiskName'"
    }
    # If the user selects the data disk(s) to be deleted, and its delete option is "delete", notify the user that Azure will automatically delete this resource with VM
    else 
    {
        Write-Host "`nThe data disk(s) '$DataDiskName' will be automatically deleted along with the VM, per its delete option property"
    }
}


# If user selects network interface to be deleted, and the network interface delete option is to detach it when its connected VM is deleted, delete the network interface
if ($DeleteNI -eq "Y" -and $NIDeleteOption -eq "Detach") 
{
    Write-Host "`nDeleting the VM network interface '$NIName'"
    try 
    {
        # Delete Network Interface
        Remove-AzNetworkInterface -Name $NetworkInterface.Name -ResourceGroupName $VM.ResourceGroupName
    }
    catch 
    {
        Write-Host "Could not delete Network Interface '$NIName'"
    }
}
# If user selects network interface to not be deleted, notify user
elseif ($DeleteNI -eq "N") 
{
    Write-Host "`nUser chose to not delete the network interface '$NIName'"
}
# If the user selects the network interface to be deleted, and its delete option is "delete", notify the user that Azure will automatically delete this resource with VM
else 
{
    Write-Host "`nThe network interface '$NIName' and public IP address '$PublicIPName' will be automatically deleted along with the VM, per the network interface delete option property"
}


# If user selects public IP address to be deleted, and the network interface delete option is to detach it when its connected VM is deleted, delete the public IP
# The public IP delete option is typically the same as the network interface delete option - therefore skipping else case
if ($DeletePublicIP -eq "Y" -and $NIDeleteOption -eq "Detach") 
{
    Write-Host "`nDeleting the VM public IP '$PublicIPName'"
    try 
    {
        # Delete public IP address
        Remove-AzPublicIpAddress -Name $publicIP.Name -ResourceGroupName $VM.ResourceGroupName
    }
    catch 
    {
        Write-Host "Could not delete public IP address '$PublicIPName'"
    }
}
# If user selects public IP address to not be deleted, notify user
elseif ($DeletePublicIP -eq "N") 
{
    Write-Host "`nUser chose to not delete the publice IP address '$PublicIPName'"
}


# If user selects network security group to be deleted, delete the network security group
if ($DeleteNSG -eq "Y") 
{
    Write-Host "`nDeleting the VM network security group '$NSGName'"
    try 
    {
        # Delete Network Security Group
        Remove-AzNetworkSecurityGroup -Name $NetworkSecurityGroup.Name -ResourceGroupName $VM.ResourceGroupName
    }
    catch 
    {
        Write-Host "Could not delete Network Security Group '$NSGName'"
    }
}
else
{
    Write-Host "`nUser chose to not delete the network security group '$NSGName'"
}