# VPC

This creates the underlying infrastructure for a vpc, including the vpc itself, public subnet,
private subnet, and nat gateways.

## Features

* One subnet per Availability Zone for maximum redundancy
* Independent routing tables configured for every private subnet to control the flow of traffic within and outside the Amazon VPC.
* The public subnets share a single routing table, because they all use the same Internet gateway as the sole route to communicate with the Internet.

