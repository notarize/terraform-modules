# terraform-modules

Reusable terraform modules that manage our infrastructure

This is mounted to `/terraform/modules` in the terraform container.

## Module Structure

* Variables in a `variables.tf` file
    * All variables defined in a module should have a type defined as well as a description
* Terraform resources in a `main.tf` file
    * More resources can live in separate `.tf` files
* Outputs in an `outputs.tf` file
