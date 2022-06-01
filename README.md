# decommission-azure-vm-resources
PowerShell script that deletes Azure virtual machines and associated resources, including network interfaces, public IP addresses, network security groups, and disks. 
<br />
<br />
Users will be prompted for which resources to be deleted along with their associated virtual machine, therefore any combination of these resources may be deleted. 
<br />
<br />
If a resource has a -DeleteOption property value of 'Delete', the resource will be automatically deleted when the virtual machine is deleted, and this script will skip its delete operation. Those with a -DeleteOption property of 'Detach' will re-prompt the user if they should be deleted prior to performing the delete operation.
<br />
<br />
## Get Started  <br />
### Install Modules

To install the required modules to run this script, follow the instructions below.

1. Open PowerShell as Administrator
2. Run the command to install the [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-8.0.0) module -
    ```powershell
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
    ```
    


### Azure Requirements  

This script requires an Azure account to connect to, with privileges that allow administration of virtual machines.   
