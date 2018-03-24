# FortiGate Guard Duty Integration

The solutions provided in this folder are currently a work in progress and should only be used to lab, demos, and beta testing.

Once the solutions are ready for wide scale use, these will be moved to the main template directory in this repo (AWS-CloudFormationTemplates/Templates).

# This solution set:
	- Creates a Cloudwatch event that triggers when Guard Duty finding events are 
		seen which triggers a lambda function to parse the event and push dynamic
		address objects and address group objects to one or many FortiGates via the FortiOS REST API. 
		
	- The dynamic address objects are created as either IPv4 or DNS objects based on the Guard Duty event type seen.  
	
	- These address objects are then appended to dynamic address groups that map to each known Guard Duty finding type
		to provide selective use within your firewall policy.
	
	- There is also a nested aggregate address group created which contains all the dynamic address group objects
		created for each finding type.
	
	- Creates KMS keys for encypting Lambda environment variables that contain 
		sensitive information such as FortiGate IPs and credentials.  Encyrption of
		the variables is optional and can be disabled at any time.  Decryption of
		ciphertext can be acheived quickly with the use of AWS CLI and the KMS service.
		
There are two templates which deploy the same solution set described above with a key difference in where the Lambda function runs.  Lambda functions by default run within an AWS owned VPC and will connect to AWS and other services it interacts with (including FortiGates) using any public AWS IP.  These functions can be configured to run within your own VPC which would allow you to use private IP addressing to reach your FortiGates as well as connect to other FortiGates using known public IPs as well.

## Lambda running within AWS VPCs
If you use the template which uses the default VPC settings (ie use AWS owned VPC), then keep in mind you will need to allow HTTPS (TCP 443) traffic from any public IP to your FortiGates you want the Lambda function to communicate with.  

### Reference Diagram:
---

![Example Diagram](https://raw.githubusercontent.com/fortinetclouddev/FortiGate-HA-for-Azure/EastWestHA2.1/diagram1.png)

---

## Lambda running within your VPCs
If you use the other template which uses your VPC setting, then keep in mind that the subnets the Lambda function is set to initate traffic from will need to provide reachability to your FortiGate IPs provided (private or public).  Additionally if the Lambda environment variables are encrypted, either a VPC endpoint for KMS needs to be deployed within the same VPC or public internet access needs to be available for Lambda to interact with the KMS API.
### Reference Diagram:
---

![Example Diagram](https://raw.githubusercontent.com/fortinetclouddev/FortiGate-HA-for-Azure/EastWestHA2.1/diagram1.png)

---

## General template instructions

With either template you will be prompted for the same parameters for Lambda environment variables and user name for KMS key administration.  The default values can be used for all parameters except for FortiGateLoginInfoList and KeyAdministrator.

The FortiGateLoginInfoList parameter is where you enter in the list of FortiGates that you want Lambda to connect to in the relevant format.  The CloudFormation template has this parameter set to hide your input so this sensitive data can't be seen by other users via the AWS console, CLI, or API.  So it is recommended to prepare your input first and then paste it into this parameter field in the AWS console.

Keep in mind, once you have deployed the template you can go to the Lambda console and scroll down to the environment variables section to validate your input is formatted correctly or correct any issues.

	If you are using only one FortiGate, then your input should follow this format:
		<fgt-ip>,<fgt-user>,<fgt-password>
		1.1.1.1,admin,i-abcdef123456

	If you are using multiple FortiGates, then your input should follow this format:
		<fgt1-ip>,<fgt1-user>,<fgt1-password>|<fgt2-ip>,<fgt2-user>,<fgt2-password>
		1.1.1.1,admin,i-abcdef123456|2.2.2.2,admin,i-abcdef123456

The KeyAdministrator parameter should be your AWS username or the username of the individual that will be in charge of encrypt\decryptinging the variable containing the FortiGate login information above.  The username will be added to the KMS key policy as an administrator of the key and also be granted priveledges to use the key.

Once you deploy the template, you can trigger the function by generating sample events form the Guard Duty console, use one of the sample events provided as part of this solution set to create a test event for Lambda, or generate live events by running a port scan against some instances in the same region as this Lambda function.

## (Optional) Encrypt Lambda environment variables

After confirming that the value provided for the 'fgtLOGINinfo' environment variable is correct, you can encrypt this with the KMS key created by the template.  Navigate to the Lambda console and scroll down to the environment variables section and expand 'Encryption configuration'.

	- Select 'Enable helpers for encryption in transit' 
	- In 'KMS key to encrypt in transit', select the key created by the template '<stackname>-LambdaFunctionKey'
	- Select 'Enter Value' to use that key
	- Select 'Encrypt' next to the 'fgtLOGINinfo' variable
	- Finally click save in the upper right hand corner of the Lambda console

If you want to decrypt the ciphertext at a later time, you can do this with the AWS CLI.  This will allow you to see the original clear text information.  Make sure you are specifying the same region where the ciphertext was pulled from for proper decryption.

This is an example AWS CLi command where you can simply paste in your ciphertext and run this command on a linux host such as Ubuntu:
	
	aws kms decrypt --ciphertext-blob fileb://<(echo '<paste-encrypted-string-here>' | base64 -d) --region <region-value-here> --output text --query Plaintext | base64 -d

 Here is a quick example of doing this with ciphertext from the ca-central-1 region:

	# aws kms decrypt --ciphertext-blob fileb://<(echo 'AQICAHj7dXsqRQCihL+mMyEc0NPccA5sYyPSwRwMxzpnt0BFwwGUD4Tv/Wo95fa8UoDEASt+AAAAqzCBqAYJKoZIhvcNAQcGoIGaMIGXAgEAMIGRBgkqhkiG9w0BBwEwHgYJYIZIAWUDBAEuMBEEDF67d4Q7tiTt8PnmZwIBEIBklOTKrTm0EmV75X2mh0huprQHnFVgiHYw+6aLbT/Z6zqtcIfQYt1dPz4O70wpnK1Xs7gMmAOP9O1dRXgcF4T6WYN55ImzZG2l3lUDLJDFlNWL/GyztcmxPLX+9E83as0SF/aKhw==' | base64 -d) --region ca-central-1 --output text --query Plaintext | base64 -d

	# 10.0.0.254,admin,i-0f39770c95a099070|10.0.2.254,admin,i-06fee8bd7beb35185
