#!/usr/bin/env bash

vault secrets enable ssh
vault write ssh/config/ca private_key=@ca public_key=@ca.pub
vault write ssh/roles/role -<<EOF                                 
{"allow_user_certificates": true, "key_type": "ca"}
EOF
vault write ssh/sign/role public_key=@user.pub

