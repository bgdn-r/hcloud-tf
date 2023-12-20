# hcloud

Infrastructure configuration for Hetzner cloud Kubernetes cluster.

> IMPORTANT! Keep the `terraform.tfvars` encrypted since it contains
the Hetzner API token.

You must provide a Hetzner Cloud API token as the `hcloud_token` 
variable in the `terraform.tfvars`.

You can modify the `terraform.tfvars` to adjust the number of nodes,
cidr blocks, names etc..

Create an SSH key pair to access the servers.
```bash
./keygen.sh kubekey
```

Initialize the terraform.
```bash
terraform init
```

Create a plan to verify the changes that are going to be applied.
```bash
terraform plan
```

If everything is as you expect, you can apply the configuration.
```bash
terraform apply
```

Once the infrastructure is provisioned, store the Terraform's state in the
S3 bucket created.

Uncomment the following lines in the `cluster.tf` file.
```terraform
  # After you run the terraform apply command
  # the first time, uncomment the following code
  # to start storing tfstate remotly

  backend "s3" {
    bucket  = var.s3_bucket_name
    region  = "your_region"
    profile = "your_aws_profile_name"
    key     = "hcloud-tf"
  }
```

Apply Terraform again to move the state to the S3 bucket.
```bash
terraform apply
```
