# FortiGate Guard Duty Integration for FortiGate 6.0.0

The solutions provided in this folder are currently a work in progress and should only be used to lab, demos, and beta testing.

There is the Lambda script template that can be downloaded from this GitHub for your use.

## The first steps with AWS components to use the GuardDuty integration feature:

	- Deploy FortiGate 6.0.0
    
	- Sign up for AWS S3, GuardDuty, CloudWatch, and Lambda, and enable them for a initial set-up.

	![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/GuardDuty/6.0/images/1-aws-gd.jpg)
	![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/GuardDuty/6.0/images/2-aws-gd-log.jpg)
	![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/GuardDuty/6.0/images/3-aws-lambda.jpg)
    
	- When findings occur in GuardDuty, the logs will get pushed to Cloudwatch.

	- Cloudwatch events will trigger the Lambda script for automated actions.

	- If the following criteria is met:
	  Either
	  - connected direction is inbound  & 
	    the finding contains an IP & 
	    he severity is greater than the minimum score (configurable)
	  Or
	  - connection direction is unknown & 
	    the finding contains an IP and matches certain known threat list (such as ProofPoint) that GuardDuty identifies & 
	    the severity is greater than the minimum score (configurable)
    
	![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/GuardDuty/6.0/images/4-aws-lambda-param.jpg)
 
    
	then the IP will be considered black and appended to a file located in S3 bucket.

	![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/GuardDuty/6.0/images/5-aws-s3-iplist.jpg)
 
    
## Configuration on FortiGate 6.0.0

After you deploy FortiGate 6.0.0, log in the admin console through HTTPS or connect with SSH.
Configure External IP source either from GUI or CLI like the examples below.
FortiGate will query the file as the external source of malicious IPs.

	#GUI:

	![Example Diagram](https://raw.githubusercontent.com/fortinetsolutions/AWS-CloudFormationTemplates/master/Templates/GuardDuty/6.0/images/6-fgt-gui-externalIPsource.jpg)

	#CLI:

		config system external-resource
		  edit "GuardDuty"
		    set type address
		    set resource "https://s3.us-east-2.amazonaws.com/ip-blacklist/ip.txt"
		  next
		end

Then, you can create actions against those IPs (i.e. firewall rules) to protect resources

