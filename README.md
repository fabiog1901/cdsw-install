# CDSW DEPLOYMENT ON AZURE VIA CLOUDERA DIRECTOR

### PREREQUISITES

Create the IAM entity with permissions to access resources in your Azure Subscription.

- Go to `Azure AD > App Registration` and create an app of type `Web app / API`. The URL is not important.
- Go to the app `Keys` section and create a new key. Save the secret key for later
- Go to your `Subscription > IAM > Role assignment` and add `Owner` to the app you created.

Get these IDs:

- `Azure Subscription ID` = get it from the `Subscription` section.
- `Azure Active Directory Tenant ID` = go to `Azure AD > Properties`, and copy the `Director ID`.
- `Azure Active Directory Client ID` = go to `Azure AD > App Registration`, and copy the `Application ID`.
- `Azure Active Directory Client Secret` = secret key you copied.

### STEPS TO CREATE CLOUDERA DIRECTOR

- Go to the Azure Marketplace and search for `Cloudera Director`, then start the wizard.
- Select default values for initial details like new resource group, private/public dns names, user/pwd, etc.
- Finish the wizard and wait until deployment is completed.
- Go to the RG, and on both NSG, open ports 7180-7189,8888.
- Check the public IP, then ssh into the vm using the user/pwd you entered in the wizard.
- Set each Availability Set for Managed Disks.

### EXAMPLE PARAMETERS FOR CLOUDERA DIRECTOR WIZARD
```
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
```

### STEPS TO CREATE CDSW DEPLOYMENT

You are now in the Director VM. Install few utils and copy this repo

```
$ sudo su 
$ yum install -y git vim wget
$ git clone https://github.com/fabiog1901/cdsw-install.git
$ cd cdsw-install
```

Adapt the properties files for your environment

```
$ TODO Add KDC_HOST_IP to kerberos.properties
```

Create a new ssh key, used by Director and CM to ssh into all cluster nodes


```
root@dirdns: /home/director/cdsw-install/azure/keys # ssh-keygen -f azurekey -t rsa
root@dirdns: /home/director/cdsw-install/azure/keys # rm azurekey.pub
```

Create the `SECRET.properties` file, and add the secret key you used before

```
$ TODO show example of secret.prop file
```

Run preliminary scripts or the wrapper
```
$ run kerberos.addprinc.sh
```

Start the bootstrap script:
```
cloudera-director bootstrap-remote director-conf/azure.conf   --lp.remote.username=director   --lp.remote.password=xxxxxxxx
```

Monitor the deployment:

```
tail -f /var/log/cloudera-director-server/application.log
```

You might find some useful info for troubleshooting here to:

```
cat /root/.cloudera-director/logs/application.log
```

If you want to SSH into a node, use the key you created previously, example:

```
$ ssh -i "azure/keys/azurekey" director@10.1.0.5
```

###

For a private CDSW cluster (no public IP address) set `PublicIP: No` in the conf file for each instance template. To access CDSW, you need to add the below to file `/etc/named/zones/db.internal`:

```
cdsw                    A       10.1.0.7
*.cdsw                  A       10.1.0.7

```

where 10.1.0.7 is the private IP address of the CDSW Master. Then restart the service:

```
# check syntax is correct:
$ named-checkconf /etc/named.conf

$ service named restart 

```

In CM, set the CDSW property `DOMAIN` to `cdsw.cloud.lab`, where `cloud.lab` is the name of the DNS service.


