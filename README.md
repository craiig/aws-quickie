A quick way to setup an AWS instance
Let's you bring it up and down via the command line
Uses Terraform to start/stop instances

requires:
* terraform
* pip install awscli
* jq
* pip install boto3

usage:
* run ./get_lowest_price.py to find the spot price for your chosen instance

* edit set_aws.sh.example -> save as set_aws.sh
* source set_aws.sh
* edit Makefile (and maybe instance.tf) to configure the instance as you want
* make apply (boot the instance)
* make destroy (kill the instance)
