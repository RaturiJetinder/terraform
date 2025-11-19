# Networking module

This module provisions the shared Google Cloud networking stack used by each environment:

* A custom VPC network with dual-stack subnets.
* A regional workload subnet with secondary ranges for GKE pods and services.
* A dedicated subnet plus Serverless VPC Access connector for Cloud Run/Functions egress.
* A Private Service Access (PSA) allocation and connection that backs Cloud SQL, Memorystore, AlloyDB, etc.

## Inputs

| Name | Type | Description |
| ---- | ---- | ----------- |
| `project_id` | string | Target project ID. |
| `region` | string | Region hosting the subnets and connector. |
| `environment` | string | Short environment code (`dev`, `stg`, `prod`, ...). |
| `network_name` | string | Name of the VPC. |
| `network_description` | string | Optional VPC description. |
| `workload_subnet_name` | string | Name of the primary subnet. |
| `workload_subnet_cidr` | string | CIDR for the workload subnet. |
| `pods_secondary_range_name` | string | Name of the pods secondary range. |
| `pods_secondary_range_cidr` | string | CIDR for the pods secondary range. |
| `services_secondary_range_name` | string | Name of the services secondary range. |
| `services_secondary_range_cidr` | string | CIDR for the services secondary range. |
| `svpc_subnet_name` | string | Name of the subnet dedicated to the Serverless VPC connector. |
| `svpc_subnet_cidr` | string | CIDR for the Serverless VPC subnet. |
| `svpc_connector_name` | string | Name of the Serverless VPC Access connector. |
| `svpc_connector_min_throughput` | number | Minimum throughput for the connector (default `200`). |
| `svpc_connector_max_throughput` | number | Maximum throughput for the connector (default `300`). |
| `psa_range_name` | string | Name of the PSA address range. |
| `psa_range_cidr` | string | CIDR for the PSA range. |

## Outputs

| Name | Description |
| ---- | ----------- |
| `network_id` | ID of the provisioned VPC. |
| `workload_subnet_self_link` | Self link of the workload subnet. |
| `pods_secondary_range_name` | Pods secondary range name to feed into GKE modules. |
| `services_secondary_range_name` | Services secondary range name to feed into GKE modules. |
| `svpc_connector_id` | ID of the Serverless VPC connector. |
| `psa_connection_id` | ID of the PSA connection. |

## Notes

* The PSA range is enforced exactly via the provided CIDR so it aligns with the org-wide IP allocation sheet.
* IPv6 is enabled on the workload subnet for future dual-stack needs.
* Add additional secondary ranges or SVPC subnets by instantiating the module again or by extending the module inputs when scaling.
