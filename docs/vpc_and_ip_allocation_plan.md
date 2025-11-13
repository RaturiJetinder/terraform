GCP VPC & IP Addressing Plan 

Date: 13 Nov 2025 
Scope: Organization-wide IP strategy, per-project carving, and concrete plan for Project P1 (Staging) in us-central1. 

Shape 

1) Executive Summary 

We propose a clean, collision-free IPv4 plan with dual-stack readiness that scales across multiple projects and regions. The organization receives a single RFC1918 supernet, each project is assigned a large non-overlapping /13, and each region within a project uses a repeatable subnet template with dedicated ranges for GKE and Serverless. Private Service Access (PSA) and Apigee peering ranges are reserved centrally to avoid future re-numbering. This design emphasizes: 

Non-overlap by construction (org → project → region). 

Predictable per-region shapes (subnet + secondary ranges + SVPC connectors). 

“Set and forget” service pools (PSA /16; Apigee /22 + /28 per instance). 

Future expansion safeguards (spare project capacity and add-on secondary ranges for GKE). 

Shape 

2) Organization-Level Strategy 

2.1 Supernet 

Org pool: 10.64.0.0/10 
 

Total addresses: 4,194,304 
 

2.2 Project Carving (8 x /13) 

We divide the /10 into eight /13 blocks. One is assigned, Other  kept in reserve for future growth or dedicated environments. 
 

Block 

CIDR 

Total IPs 

B1 

10.64.0.0/13 

524,288 

B2 

10.72.0.0/13 

524,288 

B3 

10.80.0.0/13 

524,288 

B4 

10.88.0.0/13 

524,288 

B5 

10.96.0.0/13 

524,288 

B6 

10.104.0.0/13 

524,288 

B7 

10.112.0.0/13 

524,288 

B8 

10.120.0.0/13 

524,288 

Notes: - These blocks are exclusive per project, simplifying VPC Peering/Shared VPC later. - Unused blocks (B1–B8) protect future expansion and acquisitions. 

2.3 Addressing Principles 

Role separation: Workload subnets, GKE secondary ranges, Serverless VPC Access subnets, PSA ranges, and Apigee peering ranges are all disjoint. 

Dual-stack ready: Subnets enable internal IPv6 (/64 auto-assigned by GCP) for future adoption; no IPv6 carving required. 

No reuse: SVPC connector subnets are never reused by workloads; PSA ranges are never defined as subnets. 

Predictable growth: Add regions by stamping the same template; scale GKE by adding secondary ranges without renumbering. 

Shape 

3) Project-Level Strategy (applies to each /13) 

Each project (/13) contains: 

Regional workload subnets (primary IPv4; dual-stack enabled; /22 per region). 
 

GKE secondary ranges on each regional subnet: one for Pods (/19), one for Services (/24). 
 

Serverless VPC Access connector subnets (one /24 per region). 
 

Private Service Access (PSA) global allocation (single /16 per project). 
 

Apigee: For peering-based deployments, two dedicated ranges per instance: /22 and /28. 

Capacity guidance (default regional template): - Workload subnet /22 → ~1,020 usable IPs for VMs, Dataflow, misc services. - GKE Pods /19 → 8,192 pod IPs (large headroom; add a second Pods range if ever needed). - GKE Services /24 → 256 ClusterIP services (add another /24 later if needed). - SVPC /24 → ~252 usable IPs; supports many Cloud Run/Functions services via one connector. - PSA /16 → 65,536 IPs for Cloud SQL, Memorystore, AlloyDB, etc. across all regions in the project. 

Shape 

4) P1 (Staging) – Concrete Plan 

Project: P1 (Staging) 
Project block: B1 = 10.64.0.0/13 (524,288 IPs) 

4.1 Regional Subnet – us-central1 (initial rollout) 

Primary subnet (dual-stack): 10.64.0.0/22 
Usable IPs: ~1,020 (GCP reserves 4 in primary ranges). 
Use: GCE VMs, Dataflow workers, system components. 

Secondary ranges (on the same subnet): 

Pods: 10.66.0.0/19 → 8,192 IPs 
 

Services: 10.66.32.0/24 → 256 IPs 

Capacity notes: 

VM/Dataflow: ~1,020 private IPs in the primary range now; add another /22 later if required. 
 

GKE: Thousands of pods supported under common node/pod-CIDR defaults; if a single region needs more, attach an additional Pods secondary (e.g., another /19 or /20) without renumbering existing clusters. 
 

ClusterIP Services: 256; add a second /24 later if needed. 

4.2 Serverless VPC Access – us-central1 

Connector subnet: 10.70.0.0/24 
Usable IPs: ~252. 
Use: Cloud Run/Cloud Functions/App Engine egress into the VPC. Multiple services can share one connector. This subnet is connector-only (no workloads). 

4.3 Private Service Access (PSA) – Project-wide 

Allocated range (not a subnet): 10.71.0.0/16 
IPs: 65,536 (covers all regions in the project). 
Use: Private IPs for Google-managed services (Cloud SQL, AlloyDB, Memorystore, etc.) once the private connection is created. Sizing is intentionally generous to avoid fragmentation or future renumbering. 
 
 

4.4 Apigee Peering Ranges (reserve for up to 5 instances) 

Important: Apigee X peering requires two ranges per instance: a /22 and a /28. 
(Correction: prior shorthand “/38” was a typo; it is /28.) 

From the Apigee reserved block (within project space), pre-cut:  

- Instance A: /22 → 10.70.128.0/22, /28 → 10.70.192.0/28  

- Instance B: /22 → 10.70.132.0/22, /28 → 10.70.192.16/28  

- Instance C: /22 → 10.70.136.0/22, /28 → 10.70.192.32/28  

- Instance D: /22 → 10.70.140.0/22, /28 → 10.70.192.48/28  

- Instance E: /22 → 10.70.144.0/22, /28 → 10.70.192.64/28 

Notes: - These ranges are exclusive to Apigee and not reused elsewhere. 
- They do not limit the number of proxies (logical APIs) you can define; they ensure network peering and troubleshooting IPs are isolated. 

Shape 

5) Future Scope & Expansion Safeguards 

5.1 Regional Growth 

Additional regions: Stamp the same template (primary /22 + Pods /19 + Services /24 + SVPC /24). 
 

High-density regions: If pods are the constraint, attach an additional Pods range (e.g., another /19) and target new nodepools at the new range—no renumbering required. 

5.2 GKE Scale Patterns 

Default Pods /19 fits most clusters. For extreme growth, add one more Pods range or use a larger secondary in that region. 
 

Services /24 can be extended by adding another Services secondary when ClusterIP usage approaches capacity. 

5.3 Serverless Expansion 

Add more SVPC connector subnets (/24 each) to segregate egress policies (e.g., “restricted” vs “all-egress”) or to scale concurrent connections. 

5.4 Managed Services (PSA) 

The PSA /16 is ample for hundreds/thousands of endpoints; add an additional PSA allocation later only if you deliberately want to segment service families. 

5.5 Apigee Options 

Current plan reserves five peering profiles. If you later adopt PSC-based Apigee (no VPC peering), the peering ranges become optional for new instances; existing peering-based instances remain unaffected. 

5.6 Address Governance 

Maintain a simple registry (sheet or IaC outputs) that maps region → subnet/secondaries/SVPC to prevent overlap. 
 

Enforce IaC (Terraform/Terragrunt) to prevent drift and keep future changes auditable. 

Shape 

6) Assumptions & Constraints 

RFC1918 only; no BYOIP considered at this time. 
 

IPv6 enabled internally on subnets (GCP allocates /64 automatically); IPv6 egress controlled by NAT/LB as needed. 
 

No on-prem overlap assumed; if peering with on-prem, confirm non-overlap with corporate networks. 
 

Apigee plan targets peering-based deployment; PSC-based can be accommodated later. 

Shape 

7) Implementation Order (us-central1 first) 

Create subnet 10.64.0.0/22 with secondary ranges 10.66.0.0/19 (Pods) and 10.66.32.0/24 (Services); enable internal IPv6. 
 

Allocate PSA range 10.71.0.0/16 and create the private connection. 
 

Create Serverless VPC Access connector subnet 10.70.0.0/24 and then the connector. 
 

Reserve Apigee ranges (/22 + /28) for up to five instances (do not overlap with other uses). 
