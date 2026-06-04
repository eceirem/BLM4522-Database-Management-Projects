# BLM4522 - Database Management & Security Portfolio

Comprehensive Database Management Portfolio for **BLM4522 - Network Based Parallel and Distributed Systems**. This repository contains enterprise-level database management solutions implemented on the **ETRADE** e-commerce database using MS SQL Server.

## 🚀 Implemented Projects

### [Project 1] Performance Monitoring & Optimization
- **Objective:** Resolving performance bottlenecks and optimizing high-cost queries.
- **Key Features:** - Real-time resource tracking using **Dynamic Management Views (DMVs)**.
  - Identification and elimination of unused index structures.
  - Query cost reduction (from 138ms to 7ms) by replacing *Table Scans* with *Index Seeks* using **Covering Indexes**.

### [Project 2] Backup Strategy & Disaster Recovery (DR)
- **Objective:** Ensuring 100% data availability and minimizing Recovery Time Objective (RTO).
- **Key Features:** - Implementation of **FULL Recovery Model**.
  - **Point-in-Time Restore** using Transaction Log analysis.
  - Handling database lock contentions via **Single User Mode** (ROLLBACK IMMEDIATE).

### [Project 3] Security Hardening & Auditing
- **Objective:** Implementing Zero Trust architecture through Role-Based Access Control (RBAC).
- **Key Features:**
  - Deployment of **SQL Server Authentication** in Mixed Mode.
  - Enforcement of the **Principle of Least Privilege** with restricted user roles (`SatisDanismani`).
  - Verification of audit logs via physical `.sqlaudit` file analysis using `sys.fn_get_audit_file`.

### [Project 5] Data Cleansing & ETL Processes
- **Objective:** Standardizing unstructured big data anomalies into a clean Data Warehouse format.
- **Key Features:**
  - **Smart Extraction:** Dynamically recovering missing spatial data (Cities) from address text strings.
  - **Transformation:** Isolating stock quantities hidden inside product names using advanced string algorithms (`PATINDEX`, `CHARINDEX`).
  - Loading sanitized structured data into a new reporting layer (`ETL_CLEAN_SALES`).

### [Project 7] Automated Backup & Alert System
- **Objective:** Automating data continuity and building fault-tolerant mechanisms.
- **Key Features:**
  - Integration with **Windows Task Scheduler** for daily autonomous execution.
  - Dynamic file naming structures (`yyyyMMdd_HHmm`) to prevent backup overwrites.
  - **Fault Tolerance:** Implemented `TRY...CATCH` blocks linked to Database Mail (`sp_send_dbmail`) for real-time administrator alerts.

## 🛠 Tech Stack
- **DBMS:** Microsoft SQL Server (v16.0 Express)
- **Management:** SQL Server Management Studio (SSMS)
- **Language:** Advanced T-SQL
- **Automation:** Windows Task Scheduler, SQLCMD

## 📂 Repository Structure
- `/Scripts`: Numbered SQL scripts covering Optimization, DR, Security, ETL, and Automation.
- `/Assets`: Execution plans, architecture graphs, and ETL Before/After impact reports.
- `/Reports`: Official midterm and final project documentations (PDF).

## ✍️ Author
**Ece İrem Şişer** *Computer Engineering Student at Ankara University*
