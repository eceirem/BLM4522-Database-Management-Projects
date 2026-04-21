# BLM4522 - Database Management & Security Portfolio

Comprehensive Database Management Portfolio for **BLM4522 - Network Based Parallel and Distributed Systems**. This repository contains enterprise-level database management solutions implemented on the **ETRADE** e-commerce database using MS SQL Server.

## 🚀 Implemented Projects

### [Project 2] Backup Strategy & Disaster Recovery (DR)
- **Objective:** Ensuring 100% data availability and minimizing Recovery Time Objective (RTO).
- **Key Features:** 
  - Implementation of **FULL Recovery Model**.
  - Automated and manual backup procedures.
  - **Point-in-Time Restore** using Transaction Log analysis.
  - Handling database lock contentions via **Single User Mode** (ROLLBACK IMMEDIATE).

### [Project 3] Security Hardening & Auditing
- **Objective:** Implementing Zero Trust architecture through Role-Based Access Control (RBAC).
- **Key Features:**
  - Deployment of **SQL Server Authentication** in Mixed Mode.
  - Enforcement of the **Principle of Least Privilege** with restricted user roles (`SatisDanismani`).
  - Configuration of **Server-Side Auditing** to track DML/DDL actions.
  - Verification of audit logs via physical `.sqlaudit` file analysis using `sys.fn_get_audit_file`.

## 🛠 Tech Stack
- **DBMS:** Microsoft SQL Server (v16.0)
- **Management:** SQL Server Management Studio (SSMS)
- **Language:** T-SQL

## 📂 Repository Structure
- `/Scripts`: SQL scripts for backup, security, and auditing configurations.
- `/Reports`: Final midterm and final project documentation in PDF format.

## ✍️ Author
**Ece İrem Şişer**  
*Computer Engineering Student at Ankara University*
