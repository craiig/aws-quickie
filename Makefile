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

#you can probably leave these alone
build_dir := ./build
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
	aws ec2 describe-instances --instance-ids `jq -r '.SpotInstanceRequests[].InstanceId' $(build_dir)/active_spot_requests.json` > $(build_dir)/active_instances.json
	jq -r '.Reservations[].Instances[].PublicIpAddress' $(build_dir)/active_instances.json > $(build_dir)/active_instance_ips.txt
	echo $(EC2USER) > build/user_name

destroy:
	$(call terraform,destroy)

clean: $(build_dir)
	-rm $(build_dir)/active_instance_ips.txt
	-rm $(build_dir)/active_spot_requests.json
	-rm $(build_dir)/active_instances.json
	-rm $(build_dir)/public_ips.txt

ssh: $(AWS_IDENTITY_FILE) $(build_dir)/active_instance_ips.txt
	ssh -i $(AWS_IDENTITY_FILE) $(EC2USER)@`head -n1 $(build_dir)/active_instance_ips.txt`



