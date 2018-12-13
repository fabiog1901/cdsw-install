# cdsw-install
### AZURE CDSW DEPLOYMENT

# PREREQUISITES

Go to Azure AD > App Registration and create an app of type Web app / API. The URL is not important.
Go to the Keys section in the App you created and create a new key. Save the secret for later
Go to your Subscription > IAM > Role assignment and add Owner to the app you created.

Azure Subscription ID = get it from the Azure Subscription section
Azure Active Directory Tenant ID = Azure AD > Properties > copy the Director ID
Azure Active Directory Client ID = Azure AD > App Registration > copy the Application ID
Azure Active Directory Client Secret = secret key you copied


Create Cloudera Director instance from Azure Marketplace
Select default values for initial details like new resource group, private/public dns names, user/pwd, etc.
Finish the wizard and wait until it is deployed.
???Once done, go to the RG and on both NSG, open ports 7180-7189,8888
Then check the public IP and ssh using the user/pwd you entered in the wizard.




Add KDC_HOST_IP to kerberos.properties

Subscription: Partner-Sales-Engineering
Resource group: fabio-ghirardello-rg
Location: East US
VM Username : director
VM Password: *************
Resource name of public IP : dir_public_ip
Public domain name prefix for Cloudera Director Server: dirdns
Private DNS domain name: cloud.lab
Cloudera Director Server VM size: Standard DS12 v2
New Virtual Network: directorvnet
Cloudera subnet: default
Cloudera subnet address prefix: 10.1.0.0/16
MySQL DB Admin Username: director
MySQL DB Admin Password: *************
Cloudera Director setup information
Azure Subscription ID :1088xxxxxxxxxxxae05be69a5f
Azure Active Directory Tenant ID: 10a0xxxxxxxxxxxxxxxxxxxxx12c924f
Azure Active Directory Client ID: 3e050xxxxxxxxxxxxxxxxxxxxx2aba7692
Azure Active Directory Client Secret: ********************************************
Cloudera Director Admin Username: director
Cloudera Director Admin User Password: *************

