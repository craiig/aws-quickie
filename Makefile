#set these variables
machine_name ?= ventrilo
key_pair_name ?= ventrilo
instance_type ?= t1.micro
spot_price ?= 0.0032 
#amazon linux on us-west-2
ami ?= ami-81f7e8b1
user_data = ./user_data.sh

#set this depending on your ami, set this to be the user that the private key
# woudl be for. on Amazon Linux this will be ec2-user, this also might be root
EC2USER := ec2-user

# these are paths that might be useful to other scripts you build with this
build_dir := ./build
#plaintext list of ips
active_instance_ips := $(build_dir)/active_instance_ips.txt
#username
active_instance_username := $(build_dir)/user_name
#all aws instances launched
active_instances := $(build_dir)/active_instances.json
#all spot requests made
active_spot_requests := $(build_dir)/active_spot_requests.json

#you can probably leave these alone
terraform = terraform $(1) \
	-var 'machine_name=$(machine_name)' \
	-var 'key_pair_name=$(key_pair_name)' \
	-var 'spot_price=$(spot_price)' \
	-var 'instance_type=$(instance_type)' \
	-var 'ami=$(ami)' \
	-var 'user_data=$(user_data)' \
       	-state=$(build_dir)/terraform.tfstate

$(build_dir)/kp_$(key_pair_name)_response.json:
	aws ec2 create-key-pair --key-name $(key_pair_name) > $@

#NOTE: used ordering dependency below so that we don't acidentally overwrite an existing identity file
$(AWS_IDENTITY_FILE): | $(build_dir)/kp_$(key_pair_name)_response.json
	jq -r '.["KeyMaterial"]' build/kp_$(key_pair_name)_response.json > $(AWS_IDENTITY_FILE)

$(build_dir):
	mkdir -p $(build_dir)

show: | $(build_dir)
	$(call terraform,show)

apply: $(build_dir) $(AWS_IDENTITY_FILE)
	$(call terraform,apply)
	aws ec2 describe-spot-instance-requests  --spot-instance-request-ids `jq -r '.modules[].outputs.sir_ids' $(build_dir)/terraform.tfstate` > $(build_dir)/active_spot_requests.json
	aws ec2 describe-instances --instance-ids `jq -r '.SpotInstanceRequests[].InstanceId' $(active_spot_requests)` > $(active_instances)
	jq -r '.Reservations[].Instances[].PublicIpAddress' $(active_instances) > $(active_instance_ips)
	echo $(EC2USER) > $(active_instance_username)
destroy:
	$(call terraform,destroy)

clean: $(build_dir) | destroy
	-rm $(active_instance_ips)
	-rm $(active_spot_requests)
	-rm $(active_instances)
	-rm $(active_instance_username)

ssh: $(AWS_IDENTITY_FILE) $(build_dir)/active_instance_ips.txt
	ssh -i $(AWS_IDENTITY_FILE) $(EC2USER)@`head -n1 $(build_dir)/active_instance_ips.txt`

