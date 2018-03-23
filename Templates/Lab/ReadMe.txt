There are two templates you can use.  They are the same except for one is bound to run the lambda function from within a VPC's subnets while the other does not require this.  

If you run the VPC bound template, you will need to make sure the private subnets selected have a NAT GW or FGT providing internet access as this is needed for boto3 calls to KMS to decrypt environment variables.

With either template the lambda function will make REST API calls over HTTPS to the FGT.  So make sure your SecGrps allow HTTPS from the relevant IPs.  If you use the non VPC bound template you basically need to have HTTPS open to the world.

With either templates, you can stick with the defaults wherever they are presented except for FortiGateLoginInfoList and KeyAdministrator.

Once you have deployed the SAM\CF template of your choice, then go to the lambda console and scroll down to the environment variables and validate your 'fgtLOGINinfo' variable looks correct for the FGT(s) you are wanting to run this against.

If your using the VPC bound template, then you can use private IPs like this
# 10.0.0.254,admin,i-abcdef123456|10.0.2.254,admin,i-abcdef123456

If your using the non VPC bound template, then you need to use public IPs like this
# 1.1.1.1,admin,i-abcdef123456|2.2.2.2,admin,i-abcdef123456

If you are only using one FGT, you do not need to use the pipe symbol, it would just be 'ip,admin.passwd'.
# 1.1.1.1,admin,i-abcdef123456

	
Once you have this properly configured, then in the environment variables section, expand 'Encryption configuration'.

	- Then check 'Enable helpers for encryption in transit' 
	- In 'KMS key to encrypt in transit', select the key created by the template '<stackname>-LambdaFunctionKey'
	- Select 'Enter Value' to use that key
	- Then select 'Encrypt' next to the 'fgtLOGINinfo' variable
	- Finally click save in the upper right hand corner of the console
	
At this point you can run the function by generating sample events form the Guard Duty console, use one of the sample events to create a test event for Lambda, or generate live events by running a port scan against some instances in the same region.

If you log out and back into the console, you will need to use the AWS CLI to decrypt the encrypted 'fgtLOGINinfo' variable info if you want to see what the clear text value is.  Here is the CLI syntax where you juyst paste in the encrypted value and run it.  Make sure your region is the correct region where the KMS key and Lambda function are where you copied the encrypted variable value.

# aws kms decrypt --ciphertext-blob fileb://<(echo '<paste-encrypted-string-here>' | base64 -d) --region <region-value-here> --output text --query Plaintext | base64 -d

Here is a quick example of doing this with info from the ca-central-1 region under the FTNT account:

# aws kms decrypt --ciphertext-blob fileb://<(echo 'AQICAHj7dXsqRQCihL+mMyEc0NPccA5sYyPSwRwMxzpnt0BFwwGUD4Tv/Wo95fa8UoDEASt+AAAAqzCBqAYJKoZIhvcNAQcGoIGaMIGXAgEAMIGRBgkqhkiG9w0BBwEwHgYJYIZIAWUDBAEuMBEEDF67d4Q7tiTt8PnmZwIBEIBklOTKrTm0EmV75X2mh0huprQHnFVgiHYw+6aLbT/Z6zqtcIfQYt1dPz4O70wpnK1Xs7gMmAOP9O1dRXgcF4T6WYN55ImzZG2l3lUDLJDFlNWL/GyztcmxPLX+9E83as0SF/aKhw==' | base64 -d) --region ca-central-1 --output text --query Plaintext | base64 -d

#10.0.0.254,admin,i-0f39770c95a099070|10.0.2.254,admin,i-06fee8bd7beb35185
