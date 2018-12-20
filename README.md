# CDSW DEPLOYMENT ON AZURE VIA CLOUDERA DIRECTOR

Following are instructions to deploy a CDH+CDSW cluster on Azure using Cloudera Director's bootstrap script.

For simplicity, the MIT KDC server is installed on the same instance of Cloudera Director. 

Along with deploying the CDH+CDSW cluster, the bootstrap script calls some other scripts 
to create usernames and their folders in HDFS, and to add the Kerberos principals. 
Make sure you check those scripts in the `scripts` folder to configure how many users you want to create, and the password to kinit.

### PREREQUISITES

In the **Azure Portal**, create the IAM entity with permissions to access resources in your Azure Subscription.

- Go to `Azure Active Directory > App Registration` and create an app of type `Web app / API`. The URL is not important.
- Go to the app `Keys` section and create a new key. Save the secret key for later
- Go to your `Subscription > IAM > Role assignment` and add `Owner` to the app you created.

Get these IDs:

- `Azure Subscription ID` = get it from the `Subscription` section.
- `Azure Active Directory Tenant ID` = go to `Azure Active Directory > Properties`, and copy the `Director ID`.
- `Azure Active Directory Client ID` = go to `Azure Active Directory > App Registration`, and copy the `Application ID`.
- `Azure Active Directory Client Secret` = secret key you copied.

### STEPS TO CREATE CLOUDERA DIRECTOR

- Go to the Azure Marketplace and search for `Cloudera Director`, then start the wizard.
- Complete the wizard; example values are below. 
- Finish the wizard and wait until deployment is completed. 
- Go to the RG, and on both NSGs, open ports 80,7180-7189,8888.
- Go to the RG, and `Convert to managed` each Availability Set.
- At the end of the wizard, you will see a summary just like the below example. Save it for later reference.

### EXAMPLE PARAMETERS FOR CLOUDERA DIRECTOR WIZARD
```
Subscription:Partner-Sales-Engineering
Resource group: nyc1-rg
Location: East US
VM Username : director
VM Password: *************
Resource name of public IP : dir_public_ip
Public domain name prefix for Cloudera Director Server: director
Private DNS domain name: mydnsdomain
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

SSH into the Director VM using the Username and Password. Install few utils and copy this repo:

```
$ sudo su 
$ yum install -y git vim wget
$ git clone https://github.com/fabiog1901/cdsw-install.git
$ cd cdsw-install
$ chmod +x scripts/*
```

Install MIT Kerberos, Java 8 and JCE Policy Kit, and add Kerberos principals:

```
$ ./scripts/create-log-dir.sh
$ ./scripts/install-mit-kdc.sh
$ ./scripts/install-java8.sh
$ ./scripts/kerberos-addprinc.sh
```
Check the log files on ```/var/log/cdsw-workshop/``` for any errors.

Edit the `azure/azure.conf` file for your environment and requirements. Pay special interest to these sections:

- `provider`: update all Azure IDs with the IDs you used before when you setup Director.
- `instances > base`: update all env details with proper RG, VNet, etc; you need to set `hostFqdnSuffix` to the `Private DNS domain name` you set while creating the Director instance.
- Kerberos: update the `KDC_HOST` to the Director/MIT KDC host Private IP (get it with `$hostname -I` or check in the Azure Portal)
- VM types, images and counts.
- Software to be installed, versions and repository URLs.

The Director bootstrap conf file is very complex and this guide is not meant to explain every bit of it; 
unfortunately you will need to do your own homework and go through your fair share of trial and error!
There are some reference guides available though, check the Cloudera Director client reference files in ```/usr/lib64/cloudera-director/client/```.



Create a new ssh key, used by Director and CM to ssh into all cluster nodes

```
$ ssh-keygen -f azure/azurekey -t rsa
$ rm azure/azurekey.pub
```

Create the `SECRET.properties` file, and add the secret key you used before. Example file below:

```
$ cat azure/SECRET.properties
CLIENTSECRET=iaoegrgvvbregeriophdfogeoiqgreh
```

Start the bootstrap script:
```
$ cloudera-director bootstrap-remote azure/azure.conf   --lp.remote.username=director   --lp.remote.password=xxxxxxxx
```

Once the script has terminated, login into Cloudera Director UI to open Cloudera Manager and navigate to the CDSW service, from which you can open the CDSW Web UI.

Alternatively, go to [cdsw.\<CDSW-master-public-IP\>.nip.io](cdsw.<CDSW-master-public-IP>.nip.io) 

### MONITORING AND TROUBLESHOOTING

Monitor the deployment for errors:

```
$ tail -f /var/log/cloudera-director-server/application.log
```

You can also login into Cloudera Director UI via SOCKS proxy. On your home computer, open a SSH tunnel:

```
$ ssh -CND 1080 director@director-dns-name
```

Then launch the browser using that SOCKS proxy port, as explained [here](https://www.cloudera.com/documentation/director/latest/topics/director_get_started_azure_socks.html#concept_b4z_trl_zw)


You might find some useful info here too:

```
$ cat /root/.cloudera-director/logs/application.log
```

If you want to SSH into a node, use the key you created previously, example:

```
$ ssh -i "azure/azurekey" centos@10.1.0.5
```

### EXTRAS

For a private CDSW cluster (no public IP addresses) set `PublicIP: No` in the conf file for each instance template. To access CDSW, you need to add the below to file `/etc/named/zones/db.internal`:

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

In CM, set the CDSW property `DOMAIN` to `cdsw.mydnsdomain`, where `mydnsdomain` is the name of the DNS service. 
Then restart the CDSW service.



