#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <key_name>"
    exit 1
fi

key_name=$1

ssh-keygen -t ecdsa -f $key_name -N ""

echo "SSH key pair generated: $key_name and $key_name.pub"
