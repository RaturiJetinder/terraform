# GKE module

Creates a standard (non-Autopilot) private GKE cluster with a managed node pool and fleet registration.

## Features

* VPC-native (IP alias) zonal cluster
* Private control plane and nodes (no public endpoints)
* Standard node pool sized for 56 vCPUs / ~164 GB memory across two nodes using `n2-custom-28-83968`
* Logging and monitoring components enabled with Managed Service for Prometheus
* Fleet registration for centralized management
