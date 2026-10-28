# Master Guide: Azure Storage & Database Architecture
================================================================================
Comprehensive Reference: From Foundational Mental Models to Advanced Cloud Design

---

## 1. The Real-World Mental Model (Intuition First)

If you're confused by all the terms, think of data storage like physical spaces and tools:

| Service | Real-World Analogy | What it actually stores | When to reach for it |
| :--- | :--- | :--- | :--- |
| **Azure Blob Storage** | Massive Shipping Warehouse | Raw files: PDFs, images, MP4s, backups, CSVs | Any file you need to store cheaply or index for AI |
| **Azure Files** | Shared Office Network Drive | Mounted folder (e.g. `Z:\Shared`) | Shared folder between multiple PCs or Virtual Machines |
| **Azure Queues** | Deli Counter Ticket Machine | Short ticket tasks (`#42: Process Invoice`) | Decoupling services so web servers don't crash under load |
| **Azure Tables** | Simple Rolodex / Address Book | Fast Key-Value lists without strict columns | Basic, ultra-cheap key lookups (e.g. user sessions) |
| **Azure SQL DB** | Strict Accounting Ledger | Structured tables with exact rows & relationships | Financial records, CRM, complex SQL queries & `JOIN`s |
| **Azure Cosmos DB** | Supersonic Global Teleport | Scalable JSON documents synchronized worldwide | High-speed global apps, gaming, mobile, real-time AI |

---

## 2. Technology Comparison Matrix

| Technology | Category | Data Format | Query Capability | Latency | Pricing Model |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Blob Storage** | Object Store | Any file (binary / text) | None (retrieve file / byte range) | 10–50 ms | GB/month capacity + operations (~$0.015/GB) |
| **Azure Files** | Cloud SMB/NFS Share | File system hierarchy | File paths & folder traversal | 5–20 ms | Provisioned or Pay-as-you-go capacity |
| **Azure Queues** | Message Broker | Small text messages (≤ 64 KB) | First-in, First-out (FIFO) dequeue | 5–15 ms | Per million operations (fractions of a cent) |
| **Azure Tables** | Simple NoSQL | Key-Value entities | Filter only on `PartitionKey` + `RowKey` | 5–15 ms | GB/month + operations (ultra-cheap) |
| **Azure SQL DB** | Relational (RDBMS) | Rows & Columns | Full ANSI SQL (`JOIN`, `GROUP BY`, views) | 1–5 ms | Compute vCores / DTUs + Storage |
| **Cosmos DB** | Distributed NoSQL | JSON, Graphs, Key-Value | Rich SQL / Mongo / Vector similarity search | **< 10 ms SLA** | Provisioned Throughput (RU/s) or Serverless |

---

## 3. Deep Dive: Azure Storage Account (4 Core Services)

When you deploy a single **Azure Storage Account** (such as `stexplore12`), you automatically get 4 built-in sub-services:

```
                  ┌─────────────────────────────────────────┐
                  │    Azure Storage Account (stexplore12)  │
                  └────────────────────┬────────────────────┘
          ┌─────────────────┬──────────┴──────────┬─────────────────┐
          ▼                 ▼                     ▼                 ▼
   ┌─────────────┐   ┌─────────────┐       ┌─────────────┐   ┌─────────────┐
   │ Blob Storage│   │ Azure Files │       │Azure Queues │   │Azure Tables │
   │(Files & AI) │   │ (SMB Share) │       │ (Decoupling)│   │ (Simple KV) │
   └─────────────┘   └─────────────┘       └─────────────┘   └─────────────┘
```

### 3.1 Azure Blob Storage (Binary Large Objects)
Blob storage is designed for massive scale (petabytes). It stores unstructured data without enforcing any database schema.

#### The 3 Types of Blobs:
1. **Block Blobs** (99% of use cases):
   * Composed of individual blocks (up to 4,000 MiB each).
   * Supports parallel chunk uploading, resume capability, and streaming.
   * *Use Cases:* Documents, images, video streaming, AI Search datasets.
2. **Append Blobs**:
   * Optimized only for appending new blocks at the end of the file. Existing blocks cannot be modified.
   * *Use Cases:* Server audit logs, diagnostic telemetry streams.
3. **Page Blobs**:
   * A collection of 512-byte pages designed for random read and write operations.
   * *Use Cases:* Backing virtual hard disk (`.vhd`) drives for Azure Virtual Machines.

#### Access Tiers & Lifecycle Management:
* **Hot Tier**: Optimized for data accessed frequently. Lowest read fees, standard storage rate.
* **Cool Tier**: Optimized for data stored for ≥ 30 days and accessed infrequently. Lower storage cost, higher read fee.
* **Cold Tier**: Optimized for data stored for ≥ 90 days with rare access.
* **Archive Tier**: Lowest storage cost (fractions of a cent), but data is offline. Rehydrating an archive blob back to Hot takes **1 to 15 hours**.
* **Lifecycle Rules**: You can automate data transitions:
  * Example: *Move to Cool after 30 days -> Move to Archive after 90 days -> Delete after 365 days.*

#### Advanced: Azure Data Lake Storage Gen2 (ADLS Gen2)
* By enabling **Hierarchical Namespace (HNS)** on a Blob account, standard blobs gain true directories and POSIX folder-level permissions.
* Essential foundation for **Databricks, Apache Spark, Azure Synapse, and Microsoft Fabric**.

---

### 3.2 Azure Files (Native Cloud File Share)
Unlike Blob Storage (accessed via REST APIs or HTTP URLs), Azure Files creates an actual network share.

* **Protocols**: SMB 3.0 (Windows / macOS / Linux) and NFS 4.1 (Linux).
* **Key Scenarios**:
  * "Lift and shift" legacy applications that expect a file path (e.g. `D:\SharedData\file.txt`).
  * Mounting persistent volumes to Docker / Azure Kubernetes Service (AKS) containers.
  * Shared development drives mounted locally across team workstations.
* **Azure File Sync**:
  * Keeps your on-premises Windows Server folders synchronized with Azure Files in the cloud.

---

### 3.3 Azure Queue Storage (Decoupling Services)
Enables asynchronous message buffering between microservices.

* **Message Size**: Up to 64 KB.
* **Max Queue Size**: Up to 500 TB.
* **Why use it?**
  * Prevents a traffic spike from taking down your database.
  * *Flow:* Frontend Website -> puts message in Queue -> Background Worker / Azure Function consumes and processes in order.
* **Queue Storage vs. Azure Service Bus**:
  * Use **Storage Queue** if you need a simple, cheap message backlog.
  * Use **Azure Service Bus** if you need pub/sub topics, FIFO strict ordering, transactions, or duplicate detection.

---

### 3.4 Azure Table Storage (Basic NoSQL)
A schemaless, key-attribute store for non-relational structured data.

* **Indexing**: Every entity is identified by two primary keys:
  * `PartitionKey`: Groups entities across physical storage nodes for scale.
  * `RowKey`: The unique identifier within that partition.
* **Limitation**: Fast only when searching by `PartitionKey` and `RowKey`. Searching by any other property performs a slow full-table scan.
* *Note:* If you outgrow Azure Tables, **Cosmos DB Table API** provides single-digit millisecond response times and global replication with zero code changes.

---

## 4. Dedicated Azure Databases (SQL vs. Cosmos DB)

```
                    ┌───────────────────────────────────────────────┐
                    │               Database Families               │
                    └───────────────────────┬───────────────────────┘
                     ┌──────────────────────┴──────────────────────┐
                     ▼                                             ▼
           ┌──────────────────┐                          ┌──────────────────┐
           │   Relational SQL │                          │      NoSQL       │
           │  (Azure SQL DB)  │                          │  (Cosmos DB)     │
           └─────────┬────────┘                          └─────────┬────────┘
                     │                                             │
      • Strict schemas & tables                     • Flexible JSON documents
      • Foreign keys & ACID                         • Schema-agnostic & flexible
      • Heavy JOIN operations                       • Scales horizontally infinitely
```

### 4.1 Azure SQL Database (Relational / RDBMS)
* Fully managed Microsoft SQL Server engine in the cloud.
* **Best for:** Core business data, transactional banking, inventory systems, complex reporting where relationships between tables are strict.
* **Features:** Automatic tuning, built-in high availability, temporal tables (point-in-time time travel), transparent data encryption (TDE).

### 4.2 Azure Cosmos DB (Planet-Scale NoSQL & Vector Search)
Cosmos DB is Microsoft's distributed, multi-model NoSQL database.

* **Multi-Model APIs**:
  1. **NoSQL API**: Native JSON document store using SQL syntax for queries.
  2. **MongoDB API**: Drop-in compatible with existing MongoDB drivers and tools.
  3. **Cassandra API**: Columnar format for high write workloads.
  4. **Gremlin API**: Graph database for social networks, fraud detection, and recommendation engines.
  5. **Table API**: Drop-in upgrade for Azure Table Storage.
* **Global Replication**: Distribute data to any number of Azure regions globally with a single click.
* **Latency SLA**: Financially backed 99.999% SLA guaranteeing **< 10ms read/write times**.
* **Vector Indexing**: Native storage and vector search (cosine / dot product / Euclidean) directly inside your JSON documents for AI / RAG workloads.

---

## 5. Storage Security, Redundancy & Disaster Recovery

### 5.1 Redundancy Options

| Tier | Name | Copies | Locations | Protects Against |
| :--- | :--- | :--- | :--- | :--- |
| **LRS** | Locally Redundant Storage | 3 | Within 1 data center rack/room | Hardware drive/rack failure |
| **ZRS** | Zone Redundant Storage | 3 | Across 3 independent Availability Zones | Facility power outage, fire, flood |
| **GRS** | Geo-Redundant Storage | 6 | 3 in primary region + 3 in secondary paired region | Regional catastrophe |
| **GZRS**| Geo-Zone-Redundant | 6 | 3 across 3 zones in primary + 3 in secondary | Maximum possible cloud protection |

### 5.2 Security & Authentication
* **Access Keys (Account Key 1 & 2)**: Full administrative "root" access. Should rarely be shared with apps.
* **Shared Access Signatures (SAS)**: Time-limited, permission-scoped tokens (e.g. "read-only access to folder `reports` for 2 hours").
* **Microsoft Entra ID (RBAC)**: Role-Based Access Control using Azure identities without any shared secrets.
* **Private Endpoints**: Keeps all traffic on your private virtual network (VNet), completely disabling public internet exposure.

---

## 6. Decision Tree: Which One Should I Pick?

```
What are you trying to store?
 │
 ├── Unstructured Files (PDFs, Images, Audio, Logs, Backups)?
 │    ├── Do you need to mount it as a Windows/Linux drive? ──────► Azure Files
 │    └── Do you access it via URLs, API, or for AI Search? ─────► Azure Blob Storage
 │
 ├── Temporary Messages / Task Queue?
 │    ├── Simple, low-cost worker backlog? ───────────────────────► Azure Queue Storage
 │    └── Enterprise Pub/Sub, strict FIFO, transactions? ────────► Azure Service Bus
 │
 └── Structured or Semi-Structured Application Data?
      ├── Strict schemas, foreign keys, SQL JOIN queries? ────────► Azure SQL Database
      ├── Ultra-low cost, simple key-value lookups? ──────────────► Azure Table Storage
      └── High-throughput, global distribution, JSON, Vector AI? ──► Azure Cosmos DB
```

---

## 7. Master Azure CLI Reference (Tested on `stexplore12`)

### 1. Azure Blob Storage
```powershell
# Create a container
az storage container create --name documents --account-name stexplore12

# Upload a file
az storage blob upload --container-name documents --file sample.pdf --name sample.pdf --account-name stexplore12

# List all blobs in container
az storage blob list --container-name documents --account-name stexplore12 --output table

# Generate a 1-hour read-only SAS URL for a blob
$expiry = (Get-Date).AddHours(1).ToString("yyyy-MM-ddTHH:mm:ssZ")
az storage blob generate-sas --container-name documents --name sample.pdf --permissions r --expiry $expiry --account-name stexplore12 --full-uri
```

### 2. Azure Files
```powershell
# Create an SMB file share (100 GB quota)
az storage share create --name team-share --quota 100 --account-name stexplore12

# Mount to Windows Drive Z:
$key = (az storage account keys list -n stexplore12 --query "[0].value" -o tsv)
net use Z: \\stexplore12.file.core.windows.net\team-share /u:Azure\stexplore12 $key
```

### 3. Azure Queues
```powershell
# Create a queue
az storage queue create --name task-queue --account-name stexplore12

# Push a message
az storage message put --queue-name task-queue --content "ProcessDocument_99" --account-name stexplore12

# Peek at the top message without deleting it
az storage message peek --queue-name task-queue --account-name stexplore12 --output table

# Pop / get and delete message after processing
az storage message get --queue-name task-queue --account-name stexplore12 --output table
```

### 4. Azure Tables
```powershell
# Create a table
az storage table create --name CustomerCache --account-name stexplore12

# Insert an entity
az storage entity insert --table-name CustomerCache --account-name stexplore12 `
  --entity PartitionKey=US RowKey=user_101 FullName="John Doe" Plan="Enterprise"

# Query the entity
az storage entity show --table-name CustomerCache --partition-key US --row-key user_101 --account-name stexplore12
```

