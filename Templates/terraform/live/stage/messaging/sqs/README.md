# SNS Topic for Lambda worker server cluster example (staging environment)

## Pre-requisites

* You must have [Terraform](https://www.terraform.io/) installed on your computer. 
* You must have an [Amazon Web Services (AWS) account](http://aws.amazon.com/).

Please note that this code was written for Terraform 0.8.x.

## Quick start

**Please note that this example will deploy real resources into your AWS account. We have made every effort to ensure 

Configure your [AWS access keys]
(http://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys) as environment variables:

```
export AWS_ACCESS_KEY_ID=(your access key id)
export AWS_SECRET_ACCESS_KEY=(your secret access key)
```

In `vars.tf`, fill in the name of the SNS Topic

```hcl
```

Validate the templates:

```
terraform plan
```

Deploy the code:

```
terraform apply
```

Clean up when you're done:

```
terraform destroy
```
