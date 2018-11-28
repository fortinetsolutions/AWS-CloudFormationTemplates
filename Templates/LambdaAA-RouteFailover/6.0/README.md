# Lambda A-A failover for AWS Routes 

## Table of Contents
  - [Overview](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/Templates/LambdaAA-RouteFailover/6.0/README.md#overview)
  - [Solution Components](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/Templates/LambdaAA-RouteFailover/6.0/README.md#solution-components)
  - [Failover Process](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/Templates/LambdaAA-RouteFailover/6.0/README.md#failover-process)
  - [CloudFormation Templates](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/Templates/LambdaAA-RouteFailover/6.0/README.md#cloudformation-templates)
  - [Deployment](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/Templates/LambdaAA-RouteFailover/6.0/README.md#deployment)
  - [FAQ \ Tshoot](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/Templates/LambdaAA-RouteFailover/6.0/README.md#faq--tshoot)

## Overview
The purpose of this solution set is to provide a lambda based, dual AZ, active-active failover solution driven by TCP health checks.  The solution set provides automated AWS route table updates to maintain egress traffic flow through two independent FortiGate instances in separate availability zones.  This solution set does not provide failover for ingress traffic as this should be handled by external resources such as AWS ELB or Route53 services.

The main benefits of this solution are:
  - Fast failover of AWS SDN with external automation 
  - Automatic AWS SDN updates to route targets

**Note:**  Other Fortinet solutions for AWS such as native FortiOS FGCP A-P clustering, AutoScaling, and Transit VPC are available.  Please visit [www.fortinet.com/aws](https://www.fortinet.com/aws) for further information.	

**Reference Diagram:**
![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/net-diag1.png)

## Solution Components	
The solution is comprised of multiple components to provide the overall failover solution:
  - FortiGate Instances
  - Lambda Function
  - Cloud Watch Event Rule
  - API Gateway
  - VPC Endpoint


### Fortigate Instances
Two FortiGate instances are deployed into separate availability zones with a public and private interface. 

### Lambda Function
A single Lambda function is used to perform the TCP health checks and AWS SDN updates when needed.  This Lambda function is configured with environment variables to provide information such as the ENI ID and IP of the private interface for each AZ's FortiGate, the route table IDs to reference for each AZ, and a TCP port to use for health checks.

The Lambda function will build a list of routes found in route tables for each AZ that are targeting the private interface of either instance's private interface.

The Lambda function will perform a TCP health checks against the primary IP of ENI1 for both instances starting with the instance in the first AZ.  If a 3-way TCP handshake is successfully completed to open and close a session then the instance has passed it's health check, otherwise it is considered a failure.

Depending on the results of the TCP health checks, the Lambda function will perform different tasks:

If both AZ's instances pass the health check, the Lambda function will validate the list of routes for each AZ only point to instances in the same AZ.  Any routes in the AZ's list that are targeting the instance in the remote AZ are updated to target the instance in the expected local AZ.

If AZ1's instance passes the health check while AZ2's instance fails, the Lambda function will validate that the list of routes for each AZ only point to the instance in AZ1.  Any routes in the AZ's list that are targeting the instance in AZ2 are update to target the instance in AZ1.

If AZ1's instance fails the health check while AZ2's instance passes, the Lambda function will validate that the list of routes for each AZ only point to the instance in AZ2.  Any routes in the AZ's list that are targeting the instance in AZ1 are update to target the instance in AZ2.

If both AZ's instances fail the health check, the Lambda function will skip all AWS SDN updates.


### CloudWatch Event Rule
A single CloudWatch Event Rule is used to trigger the Lambda function on a scheduled basis (every minute).


### API Gateway
An API Gateway framework is used to allow the Lambda function to be triggered on an adhoc basis with a FortiOS stich action.  The FortiGates are dynamically bootstrapped via the CloudFormation template to use a link monitor to ping each other through the private interface (ENI1\port2).  A stich is also configured which can trigger the Lambda function through the API Gateway when there is a link monitor state change (either up or down).  

**Note:** In order for the FortiOS stich to successfully trigger the lambda function, the secret value of an API key must be manually gathered and updated on both FortiGate instances.

In order to get the secret value of the API Key, you can go to the AWS CloudFormation console, select your stack you just deployed, select the Resources tab in the detail pane for your stack and search for ‘HealthCheckAPIKey’.  Then you can simply click on the resource ID which will be a hyperlink that takes you to the correct page in the AWS API Gateway console.  Once you have the secret value for the API Key, you need to login to both FortiGates, navigate to the existing health check stitch (Security Fabric > Automation > healthcheck-stitch), and update the API Key value. 


### VPC Endpoint
A VPC interface endpoint for EC2 is created so that the Lambda function can access both the AWS EC2 API and the FortiGate instances with private IPs from within your VPC.  

**Note:** The VPC interface endpoint is using private DNS so this requires that your VPC has both DNS Resolution and DNS Hostnames enabled in your VPC settings.  Reference [AWS Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpce-interface.html#vpce-private-dns) for further information.


## Failover Process
The following network diagram will be used to illustrate a failover event from AZ1's instance (FortiGate1), to AZ2's instance (FortiGate2).  Reference the relevant CloudWatch logs showing actions taken for each step in the failover process.

**Note** inbound failover is not provided by this solution set and should be handled by external resources such as AWS ELB or Route53 services.

Outbound failover is provided by updating any routes currently targeting FortiGate1's private interface to target FortiGate2's private interface (ENI1).

When FortiGate1 comes back online and passes health checks, the list of routes for AZ1 will be updated to target FortiGate1 as it is the local instance for the AZ.
 
The AWS SDN and tag updates are performed by the Lambda function initiating API calls (from the ENI automatically created by Lambda within the VPC) through the VPC endpoint interfaces.

**Reference Logs: (failover of AZ1 routes to FortiGate2)**
```
START RequestId: 067a9460-cd7e-11e8-8446-55208fbd66ae Version: $LATEST
[INFO] 2018-10-11T17:49:39.416Z 067a9460-cd7e-11e8-8446-55208fbd66ae -=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=-
[INFO] 2018-10-11T17:49:39.417Z 067a9460-cd7e-11e8-8446-55208fbd66ae <-- Host+Port 10.0.1.25:541 is UP = True
[INFO] 2018-10-11T17:49:39.418Z 067a9460-cd7e-11e8-8446-55208fbd66ae Resetting dropped connection: ec2.us-west-1.amazonaws.com
[ERROR] 2018-10-11T17:49:44.642Z 067a9460-cd7e-11e8-8446-55208fbd66ae <--!! Exception in get_hc_status: timed out
[INFO] 2018-10-11T17:49:44.642Z 067a9460-cd7e-11e8-8446-55208fbd66ae <-- Host+Port 10.0.3.200:541 is UP = False
[INFO] 2018-10-11T17:49:44.864Z 067a9460-cd7e-11e8-8446-55208fbd66ae --> Updated 0.0.0.0/0 in rt rtb-04f35a4078382d4b6 to target eni-0d4173827c3e66584
[INFO] 2018-10-11T17:49:44.871Z 067a9460-cd7e-11e8-8446-55208fbd66ae -=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=-
END RequestId: 067a9460-cd7e-11e8-8446-55208fbd66ae 
```

**Reference Logs: (restoration of AZ1 routes to FortiGate1)**
```
START RequestId: 4e2cc405-cd7e-11e8-8c63-977ba303ae86 Version: $LATEST
[INFO] 2018-10-11T17:51:39.829Z 4e2cc405-cd7e-11e8-8c63-977ba303ae86 -=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=-
[INFO] 2018-10-11T17:51:39.830Z 4e2cc405-cd7e-11e8-8c63-977ba303ae86 <-- Host+Port 10.0.1.25:541 is UP = True
[INFO] 2018-10-11T17:51:39.831Z 4e2cc405-cd7e-11e8-8c63-977ba303ae86 Resetting dropped connection: ec2.us-west-1.amazonaws.com
[INFO] 2018-10-11T17:51:40.111Z 4e2cc405-cd7e-11e8-8c63-977ba303ae86 <-- Host+Port 10.0.3.200:541 is UP = True
[INFO] 2018-10-11T17:51:40.401Z 4e2cc405-cd7e-11e8-8c63-977ba303ae86 --> Updated 0.0.0.0/0 in rt rtb-04f35a4078382d4b6 to target eni-0b7432ff712c9b63a
[INFO] 2018-10-11T17:51:40.401Z 4e2cc405-cd7e-11e8-8c63-977ba303ae86 -=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=-
END RequestId: 4e2cc405-cd7e-11e8-8c63-977ba303ae86 
```

**Reference Diagram:**
![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/net-diag2.png)

## CloudFormation Templates
There are three CloudFormation templates that can be used for this solution set.
  - [NewVPC_BaseSetup.template](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/Templates/LambdaAA-RouteFailover/6.0/NewVPC_BaseSetup.template)
  - [FGT_LambdaAA-RouteFailover_ExistingVPC_BYOL.template.json](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/Templates/LambdaAA-RouteFailover/6.0/FGT_LambdaAA-RouteFailover_ExistingVPC_BYOL.template.json)
  - [FGT_LambdaAA-RouteFailover_ExistingVPC_PAYG.template.json](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/Templates/LambdaAA-RouteFailover/6.0/FGT_LambdaAA-RouteFailover_ExistingVPC_PAYG.template.json)

The first template is optional and deploys a base VPC with a pair of public and private subnets in 2 separate availability zones.  This template can be used to create the expected base VPC architecture for the main two templates.  For example, the VPC will have DNS Resolution and DNS Hostnames options enabled, which is required for the VPC interface endpoint to use private DNS.  Below is an example of the parameters the template will request.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/params1.png)

The last two templates will deploy the solution set into an existing VPC with all the required components.  The only difference between these templates is that either BYOL or PAYG FortiGate instances are used.  These templates not only deploy AWS infrastructure but also bootstrap the FortiGate instances with the relevant network and FortiOS stich configuration to support the VPC.  Most of this information is gathered as parameters in the templates when a stack is deployed.  These parameters are organized into these main groups:
  - VPC Configuration
  - FortiGate Instance Configuration
  - Lambda Configuration
  - External ELBv2 Configuration

### VPC Configuration
In this section the parameters will request general information for the existing VPC.  AWS resource IDs will need to be selected for the existing VPC and subnets.  Below is an example of the parameters that both templates will request.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/params2.png)

### FortiGate Instance Configuration
For this section the parameters will request general instance information such as instance type, key pair, and availability zone to deploy the instances into.  Also FortiOS specific information will be requested such as BYOL license file content.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/params3.png)

### Lambda Configuration
This section requests a TCP port to use for health checks performed by Lambda.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/params4.png)

### External ELBv2 Configuration
The last section requests if an external NLB\ALB should be deployed or not.  The default selection is None, so no ELB will be deployed with this value.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/params5.png)


## Deployment
Before attempting to create a stack with the templates, a few prerequisites should be checked to ensure a successful deployment:
1.	An AMI subscription must be active for the FortiGate license type being used in the template.  
  * [BYOL Marketplace Listing](https://aws.amazon.com/marketplace/pp/B00ISG1GUG)
  * [PAYG Marketplace Listing](https://aws.amazon.com/marketplace/pp/B00PCZSWDA)
2.	The solution requires 2 EIPs to be created so ensure the AWS region being used has available capacity.  Reference [AWS Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-resource-limits.html) for more information on EC2 resource limits and how to request increases.
3.	If BYOL licensing is to be used, ensure these licenses have been registered on the support site.  Reference the VM license registration process PDF in this [KB Article](http://kb.fortinet.com/kb/microsites/search.do?cmd=displayKC&docType=kc&externalId=FD32312).
4.  If deploying into an existing VPC that was not created with the 'NewVPC_BaseSetup.template', ensure that DNS resolution and DNS hostname support is enabled for the VPC.  Reference [AWS Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpce-interface.html#vpce-private-dns) for further information.

Once the prerequisites have been satisfied, download a local copy of the relevant template for your deployment and login to your account in the AWS console.

----
1.  In the AWS services page under All Services > Management Tools, select CloudFormation.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy1.png)

2.  Select Create New Stack.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy2.png)

3.  On the Select Template page, under the Choose a Template section select Upload a template to Amazon S3 and browse to your local copy of the chosen deployment template.  In this example, we are using the ‘FGT_LambdaAA-RouteFailover_ExistingVPC_BYOL.template.json’ template.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy3.png)

4.  On the Specify Details page, you will be prompted for a stack name and parameters for the deployment.  We are using a AWS resource IDs for a VPC created with the default values of the 'NewVPC_BaseSetup.template' template.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy4.png)

5.  In the FortiGate Instance Configuration parameters section, we have selected an Availability Zone and Key Pair to use for the FortiGates as well as BYOL licensing.  Notice, since we are using a BYOL template we are prompted for the FortiGate1LicenseFile and FortiGate2LicenseFile parameters.  For the values we are literally copying & pasting the actual BYOL license file content into these fields.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy5.png)

6.  In the Lambda Configuration parameters section, we are going with the defaults value.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy6.png)

7.  In the External ELBv2 Configuration parameters section, we are also going with the defaults so no AWS NLB or ELB will be deployed.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy7.png)

8.  On the Options page, you can scroll to the bottom and select Next.
9.  On the Review page, confirm that the stack name and parameters are correct.  This is what the parameters look like in this example.  Notice the parameter values for the FortiGate License Files.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy8.png)

10.  On the Review page, scroll down to the capabilities section.  As the template will create IAM resources, you need to acknowledge this by checking the box next to ‘I acknowledge that AWS CloudFormation might create IAM resources’ and then click Create.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy9.png)

11.  On the main AWS CloudFormation console, you will now see your stack being created.  You can monitor the progress by selecting your stack and then select the Events tab.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy10.png)

12.  Once the stack creation has completed successfully, select the Resources tab and search for 'HealthCheckAPIKey’, then click on the resource ID which will take you to the AWS API Gateway console.  Click on the 'show' button next to API Key so you can copy the secret API Key value to complete the FortiOS stich configuration.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy11.png)

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy12.png)

13.  Navigate back to the AWS CloudFormation console and select the Outputs tab to get the login information for the FortiGate instances.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy13.png)

14.  Log into both FortiGates and navigate to (Security Fabric > Automation > healthcheck-stitch), then update the API Key value with the secret key data and save your changes.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy14.png)
 
15.  Navigate to the AWS EC2 console and reference the instance Description tab for FortiGate1.  Notice the public and private ENIs attached to the instance.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy15.png)

16.  Now reference the instance Description tab for FortiGate2.  Notice the public and private ENIs attached to the instance.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy16.png)

17.  Navigate to the AWS VPC console and look at the routes for the AZ1PrivateRouteTable and AZ2PrivateRouteTable which are associated to the corresponding private subnets for each AZ.  The default route target is pointing to ENI1\port2 of the FortiGate in the same AZ.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy17.png)

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy18.png)

18.  Navigate back to the AWS EC2 console and shutdown FortiGate1 via the EC2 console.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy19.png)

19.  Navigate back to the AWS VPC console and look at the routes for the AZ1PrivateRouteTable and AZ2PrivateRouteTable.  Notice that the routes for AZ1PrivateRouteTable and AZ2PrivateRouteTable are both pointing to ENI1\port2 of the FortiGate2.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy20.png)

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy21.png)

20.  Now power on FortiGate1 and wait for the instance to fully boot. 

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy22.png)
 
21.  Navigate back to the AWS VPC console and look at the routes for the AZ1PrivateRouteTable and AZ2PrivateRouteTable.  Notice that the routes for AZ1PrivateRouteTable have been updated to point to ENI1\port2 of the FortiGate1.

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy23.png)

![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/LambdaAA-RouteFailover/6.0/content/deploy24.png)
 
22.  This concludes the template deployment example.
----

## FAQ \ Tshoot	
 - **How do I share firewall policy and objects between the FortiGates?**

The FortiGate instances are deployed as standalone instances, however centralized configuration management can be fully provided with the use of a FortiManager and policy packages.  This would allow a single firewall policy package and objects to be deployed to both of the FortiGate instances.

The FortiManager can be an existing physical\virtual appliance or you can deploy a new FortiManager instance.

For further information on FortiManager, such as the Administration Guide or FortiManager to FortiGate compatibility matrix, please visit (docs.fortinet.com)[https://docs.fortinet.com/fortimanager/admin-guides] for further information. 

Alternatively, the FortiGates can be fully configured via the GUI, CLI, or API by applying changes to each FGT manually.

  - **Are multiple routes table IDs supported per AZ?**

Yes.  Additional route table IDs for each AZ can be added to the Lambda function environment variables (az1RouteTables, az2RouteTables).  The string value needs to be entered in as a comma delimited list of route table IDs (ie rtb-aaaaaa,rtb-bbbbb).

  - **What are the expected CloudWatch logs when both instances are passing health checks?**
```
START RequestId: 95686482-cd7e-11e8-8b68-d3746dd4c444 Version: $LATEST
[INFO] 2018-10-11T17:53:39.181Z 95686482-cd7e-11e8-8b68-d3746dd4c444 -=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=-
[INFO] 2018-10-11T17:53:39.182Z 95686482-cd7e-11e8-8b68-d3746dd4c444 <-- Host+Port 10.0.1.25:541 is UP = True
[INFO] 2018-10-11T17:53:39.183Z 95686482-cd7e-11e8-8b68-d3746dd4c444 Resetting dropped connection: ec2.us-west-1.amazonaws.com
[INFO] 2018-10-11T17:53:39.431Z 95686482-cd7e-11e8-8b68-d3746dd4c444 <-- Host+Port 10.0.3.200:541 is UP = True
[INFO] 2018-10-11T17:53:39.514Z 95686482-cd7e-11e8-8b68-d3746dd4c444 -=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=-
END RequestId: 95686482-cd7e-11e8-8b68-d3746dd4c444 
```

  - **What are the expected CloudWatch logs when both instances are failing health checks?**
```
START RequestId: 4877a097-cd7f-11e8-9904-9f802c79b117 Version: $LATEST
[INFO] 2018-10-11T17:58:39.603Z 4877a097-cd7f-11e8-9904-9f802c79b117 -=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=-
[ERROR] 2018-10-11T17:58:44.608Z 4877a097-cd7f-11e8-9904-9f802c79b117 <--!! Exception in get_hc_status: timed out
[INFO] 2018-10-11T17:58:44.609Z 4877a097-cd7f-11e8-9904-9f802c79b117 <-- Host+Port 10.0.1.25:541 is UP = False
[INFO] 2018-10-11T17:58:44.610Z 4877a097-cd7f-11e8-9904-9f802c79b117 Resetting dropped connection: ec2.us-west-1.amazonaws.com
[ERROR] 2018-10-11T17:58:49.855Z 4877a097-cd7f-11e8-9904-9f802c79b117 <--!! Exception in get_hc_status: timed out
[INFO] 2018-10-11T17:58:49.855Z 4877a097-cd7f-11e8-9904-9f802c79b117 <-- Host+Port 10.0.3.200:541 is UP = False
[INFO] 2018-10-11T17:58:49.941Z 4877a097-cd7f-11e8-9904-9f802c79b117 -=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=-
END RequestId: 4877a097-cd7f-11e8-9904-9f802c79b117 
```
