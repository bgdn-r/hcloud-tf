# terraform

Create an ssh key-pair that will be used to connect to instances from the
bastion server.

The public key generated needs to be added to terraform.

```bash
# name the key pair ansible_internal
# skip enter password option
ssh-keygen -t ecdsa 

```

Create resources by running the following commands.

```bash
# init terraform configuration
terraform init

# apply the configuration
terraform apply
```

Create API key on Hetzner Cloud for the project it will be used to provision
volumes for PersistentVolumeClaims.
