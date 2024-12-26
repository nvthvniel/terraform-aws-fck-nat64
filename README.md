# terraform-aws-fck-nat64
[fck-nat](https://github.com/AndrewGuenther/fck-nat) fork with IPv6 NAT64 support using [Jool](https://github.com/NICMx/Jool)

Some Terraform provided by [RaJiska's terraform-aws-fck-nat repository](https://github.com/RaJiska/terraform-aws-fck-nat/tree/nat64) is used in this module

## Packer - Build AMI
1. Install [Packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli)
2. Set variables in `fck-nat64.pkvars.hcl`
3. Set [AWS Credentials](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon#authentication)
4. Run `packer build -var-file="packer/fck-nat64.pkvars.hcl" ./packer/fck-nat64.pkr.hcl`

## Terraform - Build EC2
```
module "fck_nat64" {
  source = "git@github.com:nvthvniel/terraform-aws-fck-nat64.git//terraform?ref=vx.x.x"

  ssh_key_name = "demo"
  subnet_id    = "subnet-1234"  # Where to run fck-nat instance

  route_table_ids = [
    "rtb-aaa"                   # Where to set routes for fck-nat instance to handle requests
  ]
  ...
}
```
* Replace `x.x.x` with a [tag version](https://github.com/nvthvniel/terraform-aws-fck-nat64/tags)
* Ensure DNS64 is enabled on the route tables' subnets

## Contributing
1. Create branch
2. Commit changes to branch
3. Push branch to repo
4. Create pull request

### Tagging
* `git tag -a "vx.x.x" -m "demo"`
* `git push --follow-tags`