Naming Conventions
livgolf-{component_type}-{purpose}-{instance_number}-{environment}
livgolf-run-back-office-01-dev
livgolf-lb-middleware-01-prod
Consistency: Apply the chosen convention uniformly across all components.
Readability: Names should be easy to understand and pronounce.
Conciseness: Avoid overly long names, but ensure they are descriptive enough.
Uniqueness: Each resource name should be unique within its scope.
Predictability: Names should follow a pattern that allows for easy inference of their purpose.
Lowercase: Use lowercase for all names to avoid case sensitivity issues.
Hyphen-separated: Use hyphens (-) as separators for readability. Avoid underscores (_) or spaces.
No Special Characters: Stick to alphanumeric characters and hyphens.
Environment Specificity: Clearly indicate the environment (e.g., dev, test, prod).
Component Type Codes
Compute
vm: Virtual Machine (Compute Engine)
cont: Container (GKE)
k8s: Kubernetes Cluster (GKE)
sl: Serverless Function (Cloud Functions)
dataproc: Data Processing Cluster (Dataproc, Spark cluster)
run: Serverless Compute (Cloud Run)
df: Data Streaming (Dataflow)
Storage
gcs: Object Storage (Cloud Storage)
disk: Block Storage (Persistent Disk)
filestore: File Storage (Cloud Filestore)
dl: Data Lake (Cloud Storage, typically GCS)
Databases
sql: Relational Database (Cloud SQL, Spanner)
bq: Data Warehouse (BigQuery)
nosql: NoSQL Database (Firestore, Bigtable)
cache: Cache (Memorystore)
Networking
vpc: Virtual Private Cloud (VPC Network)
snet: Subnet
fw: Firewall Rules
lb: Load Balancer (Cloud Load Balancing)
rt: Route Table (Cloud Router)
vpn: VPN Gateway (Cloud VPN)
Data Ingestion/Orchestration
pubsub: Message Queue (Pub/Sub)
etl: ETL Service (Dataflow, Data Fusion)
wf: Workflow Orchestrator (Cloud Composer)
Monitoring & Logging
log: Log Group (Cloud Logging)
dash: Monitoring Dashboard (Cloud Monitoring)
alert: Alert (Cloud Monitoring)
Security
iam: IAM Role/User
kms: Key Management Service (Cloud KMS)
secret: Secret (Secret Manager)
Other
api: API Gateway
dns: DNS Zone (Cloud DNS)
cdn: Content Delivery Network (Cloud CDN)
bck: Backup (Cloud Storage/Backup and DR)
