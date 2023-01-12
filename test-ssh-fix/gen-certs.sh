#!/usr/bin/env bash

ssh-keygen -C ca -t ed25519 -f ca -N ''
ssh-keygen -C user -f user -N ''

