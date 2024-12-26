Creates AMI

1. Install [Packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli)
2. Set variables in `fck-nat64.pkvars.hcl`
3. Set [AWS Credentials](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon#authentication)
4. Run `packer build -var-file="packer/fck-nat64.pkvars.hcl" ./packer/fck-nat64.pkr.hcl`