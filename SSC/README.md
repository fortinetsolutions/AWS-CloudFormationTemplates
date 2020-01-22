## FortiGate-VM CloudFormation Template:  Fabric Connectors for AWS

FortiGate NGFWs that are protecting applications in the AWS public cloud can be integrated into a company’s broader Fortinet Security Fabric using a software-defined networking (SDN) tool: the Fortinet Fabric Connector with AWS Infrastructure-as-a-Service (IaaS). Connecting FortiGate NGFWs in this way ensures that changes to attributes in the AWS environment are automatically updated in the Security Fabric. Fortinet Fabric Connectors can connect to a customer’s IaaS environment to retrieve tags and metadata that can be used to create dynamic address objects. Those objects can in turn be used in the source and/or destination of security policies.

This solution deploys a FortiGate-VM Security Fabric connection using an [AWS CloudFormation template](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/SSC/CloudFormationTemplate.json). It provisions two VPCs—one for the FortiGate Cloud Services hub, which facilitates interconnectivity and traffic inspection, and one for a single spoke VPC where a test workload instance is present. Users can deploy the FortiGate connection, use the demo environment to test it, and then clean up the test environment once the demo is completed. If they want to continue using the FortiGate solution to protect their existing production environment, this approach enables them to do so without redeploying the NGFW.


![](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/SSC/content/deployment-steps.png)


Watch this [video demonstration](https://www.youtube.com/watch?v=ugBcxymf1s4%26feature=youtu.be) of how to deploy the solution and utilize the demo.



### Architecture
---

![](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/SSC/content/architecture.png "CFT topology")

The FortiGate–Security Fabric connection is developed using a reference architecture of hub-and-spoke topology within AWS. The hub is a virtual private cloud (VPC) in AWS in which the FortiGate VM resides. The spokes consist of one or more AWS VPCs that host VM-based workloads; this architecture enables the organization to isolate workloads in their own spoke VPCs. Each spoke VPC can include multiple subnets or a single subnet with a web server or other workloads deployed.


### Deployment Guide
---
The [Deployment Guide](https://www.fortinet.com/content/dam/maindam/PUBLIC/02_MARKETING/02_Collateral/DeploymentGuide/dg-fortigate-aws.pdf) describes how to roll out a FortiGate–Security Fabric connection using the [FortiGate-VM AWS CloudFormation template](https://github.com/fortinetsolutions/AWS-CloudFormationTemplates/blob/master/SSC/CloudFormationTemplate.json). Navigate to specific sections using these links:


[Introduction](https://www.fortinet.com/content/dam/maindam/PUBLIC/02_MARKETING/02_Collateral/DeploymentGuide/dg-fortigate-aws.pdf#page=5)

[Deploying the FortiGate CFT Solution](https://www.fortinet.com/content/dam/maindam/PUBLIC/02_MARKETING/02_Collateral/DeploymentGuide/dg-fortigate-aws.pdf#page=6)

[How to configure the FortiGate](https://www.fortinet.com/content/dam/maindam/PUBLIC/02_MARKETING/02_Collateral/DeploymentGuide/dg-fortigate-aws.pdf#page=24)

Use Case Testing:
 - [Blocking an URL](https://www.fortinet.com/content/dam/maindam/PUBLIC/02_MARKETING/02_Collateral/DeploymentGuide/dg-fortigate-aws.pdf#page=34)
 - [Enabling Web Filtering](https://www.fortinet.com/content/dam/maindam/PUBLIC/02_MARKETING/02_Collateral/DeploymentGuide/dg-fortigate-aws.pdf#page=39)
  - [Intrusion Prevention](https://www.fortinet.com/content/dam/maindam/PUBLIC/02_MARKETING/02_Collateral/DeploymentGuide/dg-fortigate-aws.pdf#page=44)
  - [Botnet C&C IP Blocking](https://www.fortinet.com/content/dam/maindam/PUBLIC/02_MARKETING/02_Collateral/DeploymentGuide/dg-fortigate-aws.pdf#page=51)
[Cleaning up Demo Resources](https://www.fortinet.com/content/dam/maindam/PUBLIC/02_MARKETING/02_Collateral/DeploymentGuide/dg-fortigate-aws.pdf#page=52)


### Additional Information
---
 - [FortiGate-VM Data sheet](https://www.fortinet.com/content/dam/fortinet/assets/data-sheets/FortiGate_VM_AWS.pdf)
 - [FortiGate-VM for AWS Cookbook](https://docs2.fortinet.com/vm/aws/fortigate/6.2/aws-cookbook/6.2.0/685891/about-fortigate-vm-for-aws)
 - [AWS Solution Architectures](https://www.fortinet.com/products/public-cloud-security/aws/usecases1.html)
 - [FortiCare Support Portal](https://support.fortinet.com/?_ga=2.5831988.6234537.1579113033-1006566595.1571781627)

<br/><br/>

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=fortinet-fabric-connector-aws&templateURL=https://s3-us-west-2.amazonaws.com/fortinet-aws/fabric-connector-aws.template"><img alt="Launch Stack" src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png"></a>
 
