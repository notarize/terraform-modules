# OBSOLETE

This repo is obsolete.

See this page for details on our current terraform infrastructure:
https://notarize.atlassian.net/wiki/spaces/DEVOPS/pages/407863698/Managing+AWS+infrastructure+via+Terraform

The original README contents follow.

# terraform-modules

Reusable terraform modules that manage our infrastructure

This is mounted to `/terraform/modules` in the terraform container.

## Module Structure

* Variables in a `variables.tf` file
    * All variables defined in a module should have a type defined as well as a description
* Terraform resources in a `main.tf` file
    * More resources can live in separate `.tf` files
* Outputs in an `outputs.tf` file
