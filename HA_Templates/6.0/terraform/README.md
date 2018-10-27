# FortiOS FGCP HA A-P in AWS

## Table of Contents
  - [Overview](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/HA_Templates/6.0/terraform/README.md#overview)
  - [Solution Components](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/HA_Templates/6.0/terraform/README.md#solution-components)
  - [Failover Process](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/HA_Templates/6.0/terraform/README.md#failover-process)
  - [Terraform Templates](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/HA_Templates/6.0/terraform/README.md#terraform-templates)
  - [Deployment](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/HA_Templates/6.0/terraform/README.md#deployment)
  - [FAQ \ Tshoot](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/HA_Templates/6.0/terraform/README.md#faq--tshoot)

## Overview
FortiOS now supports using FGCP (FortiGate Clustering Protocol) in unicast form to provide an active-passive clustering solution for deployments in AWS.  This feature shares a majority of the functionality that FGCP on FortiGate hardware provides with key changes to support AWS SDN (Software Defined Networking).

This solution works with two FortiGate instances configured as a master and slave pair and requires that the instances are deployed in the same subnets and same availability zone within a single VPC.  These FortiGate instances act as a single logical instance and share interface IP addressing.

The main benefits of this solution are:
  - Fast and stateful failover of FortiOS and AWS SDN without external automation\services
  - Automatic AWS SDN updates to EIPs, ENI secondary IPs, and route targets
  - Native FortiOS session sync of firewall, IPsec\SSL VPN, and VOIP sessions 
  - Native FortiOS configuration sync
  - Ease of use as the cluster is treated as single logical FortiGate

For further information on FGCP reference the High Availability chapter in the FortiOS Handbook on the [Fortinet Documentation site](https://docs.fortinet.com).
 
**Note:**  Other Fortinet solutions for AWS such as dual AZ Lambda A-P failover, AutoScaling, and Transit VPC are available.  Please visit [www.fortinet.com/aws](https://www.fortinet.com/aws) for further information.	

**Reference Diagram:**
![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/HA_Templates/6.0/terraform/content/net-diag1.png)

## Solution Components	
FGCP HA provides AWS networks with enhanced reliability through device fail-over protection, link fail-over protection, and remote link fail-over protection. In addition, reliability is further enhanced with session fail-over protection for most IPv4 and IPv6 sessions including TCP, UDP, ICMP, IPsec\SSL VPN, and NAT sessions.

A FortiGate FGCP cluster appears as a single logical FortiGate instance and configuration synchronization allows you to configure a cluster in the same way as a standalone FortiGate unit. If a fail-over occurs, the cluster recovers quickly and automatically and can also send notifications to administrator so that the problem that caused the failure can be corrected and any failed resources restored.

The FortiGate instances will use multiple interfaces for data plane and control plane traffic to achieve FGCP clustering in an AWS VPC.  The FortiGate instances require four ENIs for this solution to work as designed so make sure to use an AWS EC2 instance type that supports this.   Reference AWS Documentation for further information on this.

For data plane functions the FortiGates will use two dedicated ENIs, one for a public interface (ie ENI0\port1) and another for a private interface (ie ENI1\port2).  These ENIs will utilize secondary IP addressing to allow both FortiGate instances to share the same IP address within the actual FortiOS configuration and sync sessions natively.  AWS does not allow modification of an ENI’s primary IP, thus secondary IP addressing must be used.  Reference AWS Documentation for further information on this.

The secondary IP addresses of the data plane ENIs will be assigned to the current master FortiGate’s ENIs and will be reassigned to another instance when a new master FortiGate instance is elected.  Additionally a cluster EIP will be associated to the secondary IP of the public interface (ie ENI0\port1) of the current master FortiGate instance and will be reassociated to a new master FortiGate instance as well.  

For control plane functions, the FortiGates will use a dedicated ENI (ie ENI2\port3) for FGCP HA communication to perform tasks such as heartbeat checks, configuration sync, and session sync.  A dedicated ENI is used as this is best practice for FGCP as it ensures the FortiGate instances have ample bandwidth for all critical HA communications.  

The FortiGates will also use another dedicated ENI (ie ENI3\port4) for HA management access to each instance and also allow each instance to independently and directly communicate with the public AWS EC2 API.  This dedicated interface is critical to failing over AWS SDN properly when a new FGCP HA master is elected and is the only method of access available to the current slave FortiGate instance.

The FortiGates are configured to use the unicast version of FGCP by applying the configuration below on both the master and slave FortiGate instances.  This configuration is automatically configured and bootstrapped to the instances when deployed by the provided Terrafom Templates.

#### Example Master FGCP Configuration:
    config system ha
    set group-name "group1"
    set mode a-p
    set hbdev "port3" 50
    set session-pickup enable
    set ha-mgmt-status enable
    config ha-mgmt-interface
    edit 1
    set interface port4
    set gateway 192.168.4.1
    next
    end
    set override disable
    set priority 255
    set unicast-hb enable
    set unicast-hb-peerip 192.168.3.12
    end

#### Example Slave FGCP Configuration:
    config system ha
    set group-name "group1"
    set mode a-p
    set hbdev "port3" 50
    set session-pickup enable
    set ha-mgmt-status enable
    config ha-mgmt-interface
    edit 1
    set interface port4
    set gateway 192.168.4.1
    next
    end
    set override disable
    set priority 1
    set unicast-hb enable
    set unicast-hb-peerip 192.168.3.11
    end

The FortiGate instances will make calls to the public AWS EC2 API to update AWS SDN to failover both inbound and outbound traffic flows to the new master FortiGate instance.  There are a few components that make this possible.

FortiOS will assume IAM permissions to access the AWS EC2 API by using the IAM instance role attached to the FortiGate instances.  The instance role is what grants the required permissions for FortiOS to:
  - Reassign secondary IP addressing on the data plane ENIs
  - Reassign cluster EIPs assigned to secondary IPs assigned to the data plane ENIs
  - Update existing routes to target the new master instance ENIs

The FortiGate instances will utilize their independent and direct internet access available through the FGCP HA management interface (ie ENI3\port4) to access the public AWS EC2 API.  It is critical that this ENI is in a public subnet with an EIP assigned so that each instance has independent and direct access to the internet or the AWS SDN will not reference the current master FortiGate instance which will break data plane traffic.

For further details on FGCP and it's components, reference the High Availability chapter in the FortiOS Handbook on the [Fortinet Documentation site](https://docs.fortinet.com).


## Failover Process
The following network diagram will be used to illustrate a failover event from the current master FortiGate (FortiGate 1), to the current slave FortiGate (FortiGate 2).

Inbound failover is provided by reassigning the secondary IP addresses of ENI0\port1 from FortiGate 1's public interface to FortiGate 2's public interface.  Additionally the EIPs associated to the secondary IP addresses of ENI0\port1 are reassociated from FortiGate 1's public interface to FortiGate 2's public interface.

Outbound failover is provided by reassigning the secondary IP addresses of ENI1\port2 from FortiGate 1's private interface to FortiGate 2's private interface.  Additionally any route targets referencing FortiGate 1’s private interface will be updated to reference FortiGate 2’s private interface.

The reassignment of secondary IPs is critical to allow synchronized sessions to resume traffic flow through FortiGate 2.

The AWS SDN is updates are performed by FortiGate 2 initiating API calls from the dedicated HA management interface (ie ENI3\port4) through the AWS Internet Gateway.

**Reference Diagram:**
![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/HA_Templates/6.0/terraform/content/net-diag2.png)

## Terraform Templates
Terraform templates are available to simplify the deployment process and are available on the Fortinet Solutions GitHub repo. Here is the direct link to the [Fortinet Solutions Repo](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/).

These templates are organized into different folders based on the FortiOS version.  Once a FortiOS version is selected, four templates are available based on the license type and if the deployment is to create a new VPC or reference an existing one.  

Here is a list of the FGCP HA Terraform templates currently available in the [FortiOS 6.0 terraform folder](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/HA_Templates/6.0/terraform) of the repo:
  - [FGT_AP_NativeHA_NewVPC_BYOL](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/tree/master/HA_Templates/6.0/terraform/examples/FGT_AP_NativeHA_NewVPC_BYOL)
  - [FGT_AP_NativeHA_NewVPC_PAYG](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/tree/master/HA_Templates/6.0/terraform/examples/FGT_AP_NativeHA_NewVPC_PAYG)
  - [FGT_AP_NativeHA_ExistingVPC_BYOL](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/tree/master/HA_Templates/6.0/terraform/examples/FGT_AP_NativeHA_ExistingVPC_BYOL)
  - [FGT_AP_NativeHA_ExistingVPC_PAYG](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/tree/master/HA_Templates/6.0/terraform/examples/FGT_AP_NativeHA_ExistingVPC_PAYG)


These templates not only deploy AWS infrastructure but also bootstrap the FortiGate instances with the relevant network and FGCP HA configuration to support the VPC.  Most of this information is gathered as variables in the templates when a stack is deployed.  These variables are organized into these main groups:
-	VPC Configuration
-	FortiGate Instance Configuration
-	Interface IP Configuration for FortiGate 1
-	Interface IP Configuration for FortiGate 2
-	Interface IP Configuration for the Cluster

### VPC Configuration
In this section the variables will request general information for the existing VPC.  AWS resource IDs will need to be selected for the existing VPC and subnets.  Below is an example of the variables that both templates will request.

#### Example New VPC Template Variables:
| Variable | Default Value | Description |
| --- | --- | --- |
| access_key | none | Provide the access key to use |
| secret_key | none | Provide the secret key to use |
| region | us-east-1 | Provide the region to use |
| availability_zone | us-east-1a | Provide the availability zone to create resources in |
| vpc_cidr | 192.168.0.0/16 | Provide the network CIDR for the VPC |
| public_subnet_cidr | 192.168.1.0/24 | Provide the network CIDR for the public subnet |
| private_subnet_cidr | 192.168.2.0/24 | Provide the network CIDR for the private subnet |
| hasync_subnet_cidr | 192.168.3.0/24 | Provide the network CIDR for the hasync subnet |
| hamgmt_subnet_cidr | 192.168.4.0/24 | Provide the network CIDR for the hamgmt subnet |

#### Example Existing VPC Template Variables:
| Variable | Default Value | Description |
| --- | --- | --- |
| access_key | none | Provide the access key to use |
| secret_key | none | Provide the secret key to use |
| region | us-east-1 | Provide the region to use |
| availability_zone | us-east-1a | Provide the availability zone to create resources in |
| vpc_id | vpc-1111111111 | Provide ID for the VPC |
| vpc_cidr | 192.168.0.0/16 | Provide the network CIDR for the VPC |
| public_subnet_id | subnet-1111111111 | Provide the ID for the public subnet |
| private_subnet_id | subnet-1111111111 | Provide the ID CIDR for the private subnet |
| hasync_subnet_id | subnet-1111111111 | Provide the ID CIDR for the hasync subnet |
| hamgmt_subnet_id | subnet-1111111111 | Provide the ID CIDR for the hamgmt subnet |

### FortiGate Instance Configuration
For this section the variables will request general instance information such as instance type, key pair, and Availability Zone to deploy the instances into.  Also FortiOS specific information will be requested such as BYOL license file content (Reference the deployment section for example values) and IP addresses for AWS resources within the VPC such as the IP of the AWS intrinsic router for the public, private, and HAmgmt subnets.  The AWS intrinsic router is always the first host IP for each subnet.  Reference [AWS Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#VPC_Sizing) for further information on host IPs used by AWS services within a subnet.

| Variable | Default Value | Description |
| --- | --- | --- |
| ami | none | This value is automatically selected by the main.tf file based on the license_type |
| instance_type | c5.xlarge | Provide the instance type for the FortiGate instances |
| keypair | none | Provide a keypair for accessing the FortiGate instance |
| cidr_for_access | 0.0.0.0/0 | Provide a network CIDR for accessing the FortiGate instances |
| license_type | byol | Provide the license type for the FortiGate instances ('byol' or 'ond') |
| fgt1_byol_license | none | Provide the BYOL license filename for fgt1 and place the file in the root module folder |
| fgt2_byol_license | none | Provide the BYOL license filename for fgt2 and place the file in the root module folder |
| public_subnet_intrinsic_router_ip | 192.168.1.1 | Provide the IP address of the AWS intrinsic router (First IP from public_subnet) |
| private_subnet_intrinsic_router_ip | 192.168.2.1 | Provide the IP address of the AWS intrinsic router (First IP from private_subnet) |
| hamgmt_subnet_intrinsic_router_ip | 192.168.4.1 | Provide the IP address of the AWS intrinsic router (First IP from hamgmt_subnet) |
| tag_name_prefix | stack-1 | Provide a tag prefix value that that will be used in the name tag for all resources |

### Interface IP Configuration for FortiGate 1 & 2
The next two sections request IP addressing information to configure the primary IP addresses of ENIs of the FortiGate instances.  This information will also be used to bootstrap the configuration for both FortiGates.

| Variable | Default Value | Description |
| --- | --- | --- |
| fgt1_public_ip | 192.168.1.11/24 | Provide the IP address in CIDR form for the public interface of fgt1 (IP from public_subnet) |
| fgt1_private_ip | 192.168.2.11/24 | Provide the IP address in CIDR form for the private interface of fgt1 (IP from private_subnet) |
| fgt1_hasync_ip | 192.168.3.11/24 | Provide the IP address in CIDR form for the ha sync interface of fgt1 (IP from hasync_subnet) |
| fgt1_hamgmt_ip | 192.168.4.11/24 | Provide the IP address in CIDR form for the ha mgmt interface of fgt1 (IP from hamgmt_subnet) |
| fgt2_public_ip | 192.168.1.12/24 | Provide the IP address in CIDR form for the public interface of fgt2 (IP from public_subnet) |
| fgt2_private_ip | 192.168.2.12/24 | Provide the IP address in CIDR form for the private interface of fgt2 (IP from private_subnet) |
| fgt2_hasync_ip | 192.168.3.12/24 | Provide the IP address in CIDR form for the ha sync interface of fgt2 (IP from hasync_subnet) |
| fgt2_hamgmt_ip | 192.168.4.12/24 | Provide the IP address in CIDR form for the ha mgmt interface of fgt2 (IP from hamgmt_subnet) |

### Interface IP Configuration for the Cluster
The last section requests IP addressing information to configure the secondary IP addresses of the public and private ENIs of FortiGate 1 as this is the master FortiGate on deployment.  This information will also be used to bootstrap the configuration of FortiGate 1.

| Variable | Default Value | Description |
| --- | --- | --- |
| cluster_public_ip | 192.168.1.13/24 | Provide the IP address in CIDR form for the public interface of the cluster (IP from public_subnet) |
| cluster_private_ip | 192.168.2.13/24 | Provide the IP address in CIDR form for the private interface of the cluster (IP from private_subnet) |


## Deployment
Before attempting to create a stack with the templates, a few prerequisites should be checked to ensure a successful deployment:
1.	An AMI subscription must be active for the FortiGate license type being used in the template.  
  * [BYOL Marketplace Listing](https://aws.amazon.com/marketplace/pp/B00ISG1GUG)
  * [PAYG Marketplace Listing](https://aws.amazon.com/marketplace/pp/B00PCZSWDA)
2.	The solution requires 3 EIPs to be created so ensure the AWS region being used has available capacity.  Reference [AWS Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-resource-limits.html) for more information on EC2 resource limits and how to request increases.
3.	If BYOL licensing is to be used, ensure these licenses have been registered on the support site.  Reference the VM license registration process PDF in this [KB Article](http://kb.fortinet.com/kb/microsites/search.do?cmd=displayKC&docType=kc&externalId=FD32312).
4.  Confirm terraform is installed correctly and can be ran as a CLI command in any directory.  Reference [Terraform Documentation](https://www.terraform.io/intro/getting-started/install.html) for further information.


Once the prerequisites have been satisfied, login to your account in the AWS console and proceed with the deployment steps below.

----
1.  Download a local copy of all AWS templates available on the FortinetSoutions repo to your desktop by navigating to [HERE](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates) and click the 'clone or download' button.  Alternatively use your favorite Git tool and run the command 'git clone https://github.com/fortinetsolutions/AWS-CloudFormationTemplates'.

```
ubuntu@ip-10-7-7-25:~/Desktop$ pwd
/home/ubuntu/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform

ubuntu@ip-10-7-7-25:~/Desktop$ git clone https://github.com/fortinetsolutions/AWS-CloudFormationTemplates
Cloning into 'AWS-CloudFormationTemplates'...
remote: Enumerating objects: 268, done.
remote: Counting objects: 100% (268/268), done.
remote: Compressing objects: 100% (183/183), done.
remote: Total 1095 (delta 125), reused 209 (delta 73), pack-reused 827
Receiving objects: 100% (1095/1095), 7.01 MiB | 24.18 MiB/s, done.
Resolving deltas: 100% (648/648), done.
```

2.  Navigate to the root folder '~/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform/'.  You should see the 'examples' and 'modules' folders.  In the 'example' folder, there are 4 different Terraform templates you can use.  
```
ubuntu@ip-10-7-7-25:~/Desktop$ cd AWS-CloudFormationTemplates/HA_Templates/6.0/terraform/
ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$ ls -l
total 8
drwxrwxr-x 6 ubuntu ubuntu 4096 Oct 6 10:29 examples
drwxrwxr-x 3 ubuntu ubuntu 4096 Oct 6 10:29 modules

ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$ ls -l examples/
total 16
drwxrwxr-x 2 ubuntu ubuntu 4096 Oct 6 10:29 FGT_AP_NativeHA_ExistingVPC_BYOL
drwxrwxr-x 2 ubuntu ubuntu 4096 Oct 6 10:29 FGT_AP_NativeHA_ExistingVPC_PAYG
drwxrwxr-x 2 ubuntu ubuntu 4096 Oct 6 10:29 FGT_AP_NativeHA_NewVPC_BYOL
drwxrwxr-x 2 ubuntu ubuntu 4096 Oct 6 10:29 FGT_AP_NativeHA_NewVPC_PAYG
```

3.  In this example we will use the Terraform template in '~/examples/FGT_AP_NativeHA_NewVPC_BYOL'.  Copy all the files from that folder to the root Terraform folder '~/teraform/'
```
ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$ pwd
/home/ubuntu/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform

ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$ cp examples/FGT_AP_NativeHA_NewVPC_BYOL/* ./
ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$ ls -l
total 40
-rw-rw-r-- 1 ubuntu ubuntu 1395 Oct 6 10:38 amis.tf
drwxrwxr-x 6 ubuntu ubuntu 4096 Oct 6 10:29 examples
-rw-rw-r-- 1 ubuntu ubuntu   91 Oct 6 10:38 fgt1-license.lic
-rw-rw-r-- 1 ubuntu ubuntu   91 Oct 6 10:38 fgt2-license.lic
-rw-rw-r-- 1 ubuntu ubuntu 2268 Oct 6 10:38 main.tf
drwxrwxr-x 3 ubuntu ubuntu 4096 Oct 6 10:29 modules
-rw-rw-r-- 1 ubuntu ubuntu  378 Oct 6 10:38 outputs.tf
-rw-rw-r-- 1 ubuntu ubuntu  300 Oct 6 10:38 terraform.tfvars
-rw-rw-r-- 1 ubuntu ubuntu 4229 Oct 6 10:38 variables.tf
```

4.  We are using all the default variables and values defined in 'variables.tf' and overriding a few relevant variables and values for this example by modifying 'terraform.tfvars'. 
```
ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$ cat terraform.tfvars
access_key = ""
secret_key = ""

region = "us-west-1"
availability_zone = "us-west-1c"

instance_type = "c5.xlarge"
keypair = "kp-poc-common"
cidr_for_access="0.0.0.0/0"
license_type = "byol"
fgt1_byol_license = "fgt1-license.lic"
fgt2_byol_license = "fgt2-license.lic"
tag_name_prefix = "tfstack-1x"
```

5.  For this deployment, we updated the 'terraform.tfvars' file to provide AWS API credentials, the region, availability zone, keypair, and tagprefix to use.  Here is how the 'terraform.tfvars' file looks like after modification (sensitive information hidden).
```
ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$ cat terraform.tfvars
access_key = "A---contentremovedcontentremoved---A"
secret_key = "l------contentremovedcontentremoved------n"

region = "us-east-1"
availability_zone = "us-east-1f"

instance_type = "c5.xlarge"
keypair = "kp-poc-common"
cidr_for_access="0.0.0.0/0"
license_type = "byol"
fgt1_byol_license = "fgt1-license.lic"
fgt2_byol_license = "fgt2-license.lic"
tag_name_prefix = "FGCP-Stack"
```

6.  Since we are using a BYOL template, we also need to update the placeholder BYOL license files for fgt1 and fgt2 with correct values.  For the license values we are literally copying & pasting the actual BYOL license file content into each corresponding file.  

Here are how the files look like before modification.
```
ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$  cat fgt1-license.lic
-----BEGIN FGT VM LICENSE-----
-contentremovedcontentremoved-
-----END FGT VM LICENSE-----

ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$ cat fgt2-license.lic
-----BEGIN FGT VM LICENSE-----
-contentremovedcontentremoved-
-----END FGT VM LICENSE-----
```

Here are how the files look like after modification (sensitive information hidden).
```
ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$  cat fgt1-license.lic
-----BEGIN FGT VM LICENSE-----
QAAAAH-------contentremovedcontentremoved-------------
-------------contentremovedcontentremoved-------------
-------------contentremovedcontentremoved-------------
-------------contentremovedcontentremoved-ZwLEy7
-----END FGT VM LICENSE-----

ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$ cat fgt2-license.lic
-----BEGIN FGT VM LICENSE-----
QAAAAK-------contentremovedcontentremoved-------------
-------------contentremovedcontentremoved-------------
-------------contentremovedcontentremoved-------------
-------------contentremovedcontentremoved-3Wke/Jd
-----END FGT VM LICENSE-----
```

7.  Terraform needs to be initialized to download the necessary providers to support deploying the example Terraform template.  This performed by running the command 'terraform init'.
```
ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$ terraform init
Initializing modules...
- module.vpc
  Getting source "modules/ftnt_aws/vpc/singleAZ_public-private-mgmt-ha-subnets"
- module.fgcp-ha
  Getting source "modules/ftnt_aws/fgt/2instances_fgcp_ha_pair_byol"

Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "aws" (1.41.0)...
- Downloading plugin for provider "template" (1.0.0)...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.aws: version = "~> 1.41"
* provider.template: version = "~> 1.0"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

8.  We can check that the variables and values provided in 'terraform.tfvars' can be processed and Terrafom can generate an execution plan successfully with the command 'terraform plan'.
```
ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

data.template_file.fgt2_userdata: Refreshing state...
data.template_file.fgt1_userdata: Refreshing state...

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + module.fgcp-ha.aws_eip.cluster_eip
      id:                                                  <computed>
      allocation_id:                                       <computed>
      associate_with_private_ip:                           "192.168.1.13"
      association_id:                                      <computed>
      domain:                                              <computed>
      instance:                                            <computed>
      network_interface:                                   "${aws_network_interface.fgt1_eni0.id}"
      private_ip:                                          <computed>
      public_ip:                                           <computed>
      tags.%:                                              "1"
      tags.Name:                                           "FGCP-Stack-cluster-eip"
      vpc:                                                 "true"

---omitted-output---
---omitted-output---
---omitted-output---

Plan: 29 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

9.  If the plan was generated successfully, we can deploy the resources with the command 'terraform apply' and entering 'yes' when prompted.
```
ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$ terraform apply
data.template_file.fgt1_userdata: Refreshing state...
data.template_file.fgt2_userdata: Refreshing state...

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

---omitted-output---
---omitted-output---
---omitted-output---

Plan: 29 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.vpc.aws_vpc.vpc: Creating...
  arn:                              "" => "<computed>"
  assign_generated_ipv6_cidr_block: "" => "false"
  cidr_block:                       "" => "192.168.0.0/16"
  default_network_acl_id:           "" => "<computed>"
  default_route_table_id:           "" => "<computed>"
  default_security_group_id:        "" => "<computed>"
  dhcp_options_id:                  "" => "<computed>"
  enable_classiclink:               "" => "<computed>"
  enable_classiclink_dns_support:   "" => "<computed>"
  enable_dns_hostnames:             "" => "true"
  enable_dns_support:               "" => "true"
  instance_tenancy:                 "" => "default"
  ipv6_association_id:              "" => "<computed>"
  ipv6_cidr_block:                  "" => "<computed>"
  main_route_table_id:              "" => "<computed>"
  tags.%:                           "" => "1"
  tags.Name:                        "" => "FGCP-Stack-vpc"
module.fgcp-ha.aws_iam_instance_profile.iam_instance_profile: Creating...

---omitted-output---
---omitted-output---
---omitted-output---

Apply complete! Resources: 29 added, 0 changed, 0 destroyed.

Outputs:

cluster_login_url = https://35.175.44.85
fgt1_login_url = https://34.196.24.82
fgt2_login_url = https://52.0.217.65
password = i-05ca64e73c516de27
username = admin
```

10.  Once the stack creation has completed successfully, reference the outputs provided to get the login information for the FortiGate instances and cluster.  You can always get all the outputs for this stack with the command 'terraform output'.
```
ubuntu@ip-10-7-7-25:~/Desktop/AWS-CloudFormationTemplates/HA_Templates/6.0/terraform$ terraform output
cluster_login_url = https://35.175.44.85
fgt1_login_url = https://34.196.24.82
fgt2_login_url = https://52.0.217.65
password = i-05ca64e73c516de27
username = admin
```

11.  Using the login information in the stack outputs, login to the master FortiGate instance with the cluster_login_url.  This should put you on FortiGate 1.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/HA_Templates/6.0/terraform/content/deploy13.png)

12.  Navigate to the HA status page on the master FortiGate by going to System > HA.  Now you should see both FortiGate 1 and FortiGate 2 in the cluster with FortiGate 2 as the current slave.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/HA_Templates/6.0/terraform/content/deploy14.png)

13.  Give the HA cluster time to finish synchronizing their configuration and update files.  You can confirm that both the master and slave FortiGates are in sync by looking at the Synchronized column and confirming there is a green check next to both FortiGates.

*** **Note:** Due to browser caching issues, the icon for Synchronization status may not update properly after the cluster is in-sync.  So either close your browser and log back into the cluster or alternatively verify the HA config sync status with the CLI command ‘get system ha status’. ***

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/HA_Templates/6.0/terraform/content/deploy15.png)

14.  Navigate to the AWS EC2 console and reference the instance Description tab for FortiGate 1.  Notice the primary and secondary IPs assigned to the instance ENIs as well as the 2 EIPs associated to the instance, the Cluster EIP and the HAmgmt EIP.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/HA_Templates/6.0/terraform/content/deploy16.png)

15.  Now reference the instance Description tab for FortiGate 2.  Notice there are only primary IPs assigned to the instance ENIs and only one EIP is the HAmgmt EIP.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/HA_Templates/6.0/terraform/content/deploy17.png)

16.  Navigate to the AWS VPC console and create a default route in the PrivateRouteTable with a next hop targeting ENI1\port2 of FortiGate 1.  After saving the route to the route table, your route should look like this.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/HA_Templates/6.0/terraform/content/deploy18.png)

17.  Navigate back to the AWS EC2 console and reference the instance Description tab for FortiGate 1.  Now shutdown FortiGate 1 via the EC2 console and refresh the page after a few seconds.  Notice that the Cluster EIP and secondary IPs are no longer assigned to FortiGate 1.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/HA_Templates/6.0/terraform/content/deploy20.png)

18.  Now reference the instance Description tab for FortiGate 2.  Notice that the Cluster EIP and secondary IPs are now associated to FortiGate 2.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/HA_Templates/6.0/terraform/content/deploy21.png)

19.  Navigate back to the AWS VPC console and look at the routes for the PrivateRouteTable which is associated to the PrivateSubnet.  The default route target is now pointing to ENI1\port2 of FortiGate 2.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/HA_Templates/6.0/terraform/content/deploy22.png)

20.  Now log back into the cluster_login_url and you will be placed on the current master FortiGate, which should now be FortiGate 2.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/HA_Templates/6.0/terraform/content/deploy23.png)

21.  Now power on FortiGate 1 and confirm that it joins the cluster successfully as the slave and FortiGate 2 continues to be the master FortiGate.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/HA_Templates/6.0/terraform/content/deploy24.png)

22.  This concludes the template deployment example.
----

## FAQ \ Tshoot	
  - **Does FGCP support having multiple Cluster EIPs and secondary IPs on ENI0\port1?**
Yes.  FGCP will move over any secondary IPs associated to ENI0\port1 and EIPs associated to those secondary IPs to the new master FortiGate instance.  In order to configure additional secondary IPs on the ENI and in FortiOS for port1, reference this [use-case guide](https://www.fortinet.com/content/dam/fortinet/assets/solutions/aws/Fortinet_Multiple_Public_IPs_for_an_AWS_interface.pdf) on the Fortinet AWS micro site.

  - **Does FGCP support having multiple routes for ENI1\port2?**
Yes.  FGCP will move any routes (regardless of the network CIDR) found in AWS route tables that are referencing any of the current master FortiGate instance’s data plane ENIs (ENI0\port1, ENI1\port2, etc) to the new master on a failover event.

  - **What VPC configuration is required when deploying either of the existing VPC Terraform templates?**
The existing VPC Terraform templates are expecting the same VPC configuration that is provisioned in the new VPC Terraform templates.  The existing customer VPC would need to have 4 subnets in the same availability zone to cover the required Public, Private, HAsync, and HAmgmt subnets.  Another critical point is that both the Public and HAmgmt subnets need to be configured as public subnets.  This means that an IGW needs to be attached to the VPC and a route table, with a default route using the IGW, needs to be associated to the Public and HAmgmt subnets.  

  - **During a failover test we see successful failover to a new master FortiGate instance, but then when the original master is online, it becomes master again.**
The master selection process of FGCP will ignore HA uptime differences unless they are larger than 5 minutes.  The HA uptime is visible in the GUI under System > HA.  This is expected and the default behavior of FortiOS but can be changed in the CLI under the ‘config system ha’ table.  For further details on FGCP master selection and how to influence the process, reference primary unit selection section of the High Availability chapter in the FortiOS Handbook on the [Fortinet Documentation site](https://docs.fortinet.com/).

  - **During a failover test we see FGCP select a new master but AWS SDN is not updated to point to the new master FortiGate instance.**
Confirm the FortiGates configuration are in-sync and are properly selecting a new master by seeing the HA role change as expected in the GUI under System > HA or CLI with ‘get sys ha status’.  However during a failover the secondary IPs of ENIs, routes, and Cluster EIPs are not updated, then your issue is likely to do with direct internet access via HAmgmt interface (ENI3\port4) of the FortiGates or IAM instance role permissions issues. 

For details on the IAM instance profile configuration that should be used, reference the policy statement attached to the ‘iam-role-policy’ resource in any of the Terraform modules. 

For the HAmgmt interface, confirm this is configured properly in FortiOS under the ‘config system ha’ section of the CLI.  Reference the example master\slave CLI HA configuration in the Solutions Components section of this document.

Also confirm that subnet the HAmgmt interface is associated to, is a subnet with public internet access and that this interface has an EIP associated to it.  This means that an IGW needs to be attached to the VPC, and a route table with a default route to the IGW needs to be associated to the HAmgmt subnet.

Finally, the AWS API calls can be debugged on the FortiGate instance that is becoming master with the following CLI commands:
```
diag deb app awsd -1
diag deb enable
```

This can be disabled with the following CLI commands:
```
diag deb app awsd 0
diag deb disable
```

  - **Is it possible to remove direct internet access from the HAmgmt subnet and provide private AWS EC2 API access via a VPC interface endpoint?**
Yes.  However there are a few caveats to consider.  

First, a dedicated method of access to the FortiGate instances needs to be setup to allow dedicated access to the HAmgmt interfaces.  This method of access should not use the master FortiGate instance so that either instance can be accessed regardless of the cluster status.  Examples of dedicated access are Direct connect or IPsec VPN connections to an attached AWS VPN Gateway.  Reference [AWS Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/SetUpVPNConnections.html) for further information.

Second, the FortiGates should be configured to use the ‘169.254.169.253’ IP address for the AWS intrinsic DNS server as the primary DNS server to allow proper resolution of AWS API hostnames during failover to a new master FortiGate.  Here is an example of how to configure this with CLI commands:
```
config system dns
set primary 169.254.169.253
end
```

Finally, the VPC interface endpoint needs to be deployed into the HAmgmt subnet and must also  have ‘Private DNS’ enabled to allow DNS resolution of the default AWS EC2 API public hostname to the private IP address of the VPC endpoint.  This means that the VPC also needs to have both DNS resolution and hostname options enabled as well.  Reference [AWS Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpce-interface.html#vpce-private-dns) for further information.