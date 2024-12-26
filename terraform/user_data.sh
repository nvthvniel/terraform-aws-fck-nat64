#!/bin/sh

# https://github.com/RaJiska/terraform-aws-fck-nat/blob/main/templates/user_data.sh
: > /etc/fck-nat.conf
echo "eni_id=${TERRAFORM_ENI_ID}" >> /etc/fck-nat.conf
echo "eip_id=${TERRAFORM_EIP_ID}" >> /etc/fck-nat.conf
echo "cwagent_enabled=${TERRAFORM_CWAGENT_ENABLED}" >> /etc/fck-nat.conf
echo "cwagent_cfg_param_name=${TERRAFORM_CWAGENT_CFG_PARAM_NAME}" >> /etc/fck-nat.conf

service fck-nat restart



cat << EOF > /etc/jool/jool.conf
{
	"instance": "fck-nat",
	"framework": "netfilter",

	"global": {
		"pool6": "64:ff9b::/96",
        "lowest-ipv6-mtu": 1280,
		"logging-debug": ${TERRAFORM_LOGGING_DEBUG},
        "logging-bib": ${TERRAFORM_LOGGING_BIB},
		"logging-session": ${TERRAFORM_LOGGING_SESSION}
	}
}
EOF


systemctl enable jool
systemctl start jool