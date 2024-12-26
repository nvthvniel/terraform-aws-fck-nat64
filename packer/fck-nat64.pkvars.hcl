fck_nat_version = "1.3.0"
jool_version = "4.1.13"
region = "eu-west-2"
vpc_filters = {
    "tag:Name": "fck-nat64-packer-build",
    "isDefault": "false"
}
subnet_filters = {
    "tag:Name": "fck-nat64-packer-build-public",
    "mapPublicIpOnLaunch" = true
}