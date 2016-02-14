A quick way to setup an AWS instance.
Let's you bring it up and down via the command line.
Uses Terraform to start/stop instances.

requires:
* terraform
* pip install awscli
* jq
* pip install boto3

setup:
* cd to/your/project/dir
* git clone [this repo]
* run get_lowest_price.py to find the spot price for your chosen instance
* cp aws-quickie/instance.tf instance.tf; vim instance.tf; //edit terraform file to your liking
* cp aws-quickie/set_aws.sh.example set_aws.sh; vim aws.sh; //add your aws keys
* source set_aws.sh
* add/edit the makefile template below to your project's makefile
* make apply (boot the instance)
* make ssh (connect to the instance)
* make destroy (kill the instance)

ideal usage:

Here's how I use it from another makefile:
```Makefile
#variables will get picked up by submake calls
export terraform_dir=`pwd`
export machine_name ?= ventrilo
export key_pair_name ?= ventrilo
export instance_type ?= t1.micro
export spot_price ?= 0.0033
#amazon linux on us-west-2
export ami ?= ami-81f7e8b1
#relative to aws-quickie dir
export user_data = ../vent_setup.sh

aws := make -C ./aws-quickie
apply:
	$(aws) apply

destroy:
	$(aws) destroy

ssh:
	$(aws) ssh
```
