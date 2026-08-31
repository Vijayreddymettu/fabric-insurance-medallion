# Microsoft Fabric Interview Preparation

## Purpose

This document provides interview preparation for Microsoft Fabric with emphasis on:

- Microsoft Fabric architecture
- OneLake
- Fabric Lakehouse
- Delta tables
- Fabric Data Pipelines
- Fabric Notebooks and Spark
- Medallion Architecture
- Data Quality
- SQL Analytics Endpoint
- Semantic Models
- Power BI integration
- Orchestration
- Monitoring
- Security and governance
- Performance
- Production architecture

The examples reference the Insurance Medallion Platform implemented in this repository.

---

# 1. What is Microsoft Fabric?

Microsoft Fabric is an integrated SaaS analytics platform that brings together data ingestion, data engineering, data science, real-time analytics, data warehousing, semantic modeling, and Power BI.

Instead of building an analytics platform from many disconnected services, Fabric provides these capabilities through a common platform and storage foundation.

A simplified architecture is:

Sources
→ Data Factory / Pipelines
→ OneLake
→ Lakehouse / Warehouse
→ Data Engineering
→ Semantic Model
→ Power BI

OneLake provides the common storage foundation.

---

# 2. What problem does Microsoft Fabric solve?

Traditional analytics platforms often require separate products for:

- Data ingestion
- Data lake storage
- Spark processing
- Data warehousing
- Orchestration
- Semantic modeling
- Business intelligence

Those systems then require additional integration, security, monitoring, and data movement.

Fabric provides an integrated analytics environment.

The architectural benefit is not simply that the tools appear in one user interface.

The more important benefit is that the workloads can operate over a common data foundation through OneLake.

---

# 3. What is OneLake?

OneLake is the unified logical data lake for Microsoft Fabric.

A useful interview analogy is:

> OneLake is intended to provide an organization-wide data lake foundation for Fabric, similar to how OneDrive provides a unified storage experience for Microsoft 365 users.

Fabric workloads can access data through this common storage layer.

OneLake reduces unnecessary copies between different analytical engines.

---

# 4. Why is OneLake important?

Without a common storage layer, an architecture may look like:

Source
→ Data Lake
→ Spark platform copy
→ Warehouse copy
→ BI dataset copy

Every additional copy introduces:

- Data movement
- Storage duplication
- Latency
- Governance complexity
- Security complexity
- Synchronization problems

With Fabric, multiple workloads can operate over data stored in OneLake.

The goal is to reduce unnecessary movement and provide consistent governance and discovery.

---

# 5. What is a Fabric Lakehouse?

A Fabric Lakehouse combines data-lake storage with table-oriented analytical capabilities.

It supports:

- Files
- Delta tables
- Spark
- SQL access
- Data engineering
- Power BI integration

The Lakehouse allows engineering workloads and analytical workloads to operate over the same underlying data foundation.

---

# 6. Lakehouse vs Traditional Data Lake

A traditional data lake primarily stores files.

For example:

CSV
JSON
Parquet

A Lakehouse adds structured table capabilities and transactional metadata over data-lake storage.

Delta tables provide features such as:

- ACID transactions
- Schema management
- Reliable updates
- Table metadata
- Version-aware processing

The Lakehouse therefore supports both flexible data engineering and structured analytics.

---

# 7. What is Delta Lake?

Delta Lake is an open table format/storage layer commonly used with Spark-based lakehouse architectures.

It adds transactional capabilities over data-lake files.

Important capabilities include:

- ACID transactions
- Schema enforcement
- Schema evolution
- MERGE operations
- Update/Delete support
- Transaction logs
- Reliable concurrent processing

In this project, Fabric Lakehouse tables are stored using Delta.

---

# 8. What is Medallion Architecture?

Medallion Architecture organizes data into progressively refined layers.

The common layers are:

Bronze
→ Silver
→ Gold

Each layer has a different responsibility.

---

# 9. Bronze Layer

Bronze represents raw or source-oriented data.

Purpose:

- Preserve source data
- Support replay
- Maintain traceability
- Separate ingestion from transformation

In this project:

`LH_Bronze`

is the Bronze Lakehouse.

The ingestion pipeline is:

`PL_Load_Insurance_Data`

---

# 10. Silver Layer

Silver contains cleansed and standardized data.

Typical processing includes:

- Data-type normalization
- Date conversion
- String normalization
- Null handling
- Duplicate handling
- Schema standardization
- Data-quality validation

In this project:

`NB_Bronze_To_Silver_full`

transforms Bronze into:

`LH_Silver`

---

# 11. Gold Layer

Gold contains business-oriented analytical data.

This layer should represent how the business wants to analyze information rather than simply reproducing source-system structures.

In this project Gold contains:

- `dim_policy`
- `dim_customer`
- `fact_claim`
- `fact_payment`

These tables support dimensional analytics.

---

# 12. Why not directly load Source → Gold?

Because ingestion, technical cleansing, and business modeling change for different reasons.

If everything is implemented in one transformation:

Source
→ Gold

the architecture becomes tightly coupled.

Using:

Source
→ Bronze
→ Silver
→ Gold

provides:

- Recoverability
- Reprocessing
- Reusability
- Better troubleshooting
- Clear lineage
- Separation of concerns

---

# 13. What are Fabric Data Pipelines?

Fabric Data Pipelines provide workflow orchestration and data movement capabilities.

A pipeline can coordinate activities such as:

- Copy operations
- Notebook execution
- Stored procedures
- Other pipelines
- Conditional execution
- Scheduling

Pipelines control when and in what order processing occurs.

---

# 14. Pipeline vs Notebook

This is a common interview question.

A pipeline is primarily an orchestration mechanism.

A notebook is primarily a processing mechanism.

Pipeline:

"What should execute, in what order, and under what conditions?"

Notebook:

"What transformation should be performed on the data?"

In this project:

`PL_Insurance_Medallion_ETL`

orchestrates processing.

The PySpark notebooks implement transformations.

---

# 15. Why separate pipelines and notebooks?

It creates separation of concerns.

Pipeline responsibilities:

- Orchestration
- Dependencies
- Scheduling
- Retry
- Monitoring
- Workflow control

Notebook responsibilities:

- Data transformations
- Data validation
- Spark processing
- Business logic

This makes both layers easier to maintain.

---

# 16. Master Pipeline in This Project

The master orchestration pipeline is:

`PL_Insurance_Medallion_ETL`

Execution:

01_Load_Bronze
        ↓
02_Bronze_To_Silver
        ↓
03_Silver_Data_Quality
        ↓
04_Silver_To_Gold

The first activity invokes:

`PL_Load_Insurance_Data`

The remaining activities execute notebooks.

---

# 17. What are Pipeline Dependencies?

Dependencies determine whether downstream activities execute based on the result of upstream activities.

Examples include:

- On success
- On failure
- On completion

In this project, the primary processing path uses success dependencies.

Therefore:

If Silver Data Quality fails
→ Silver-to-Gold does not execute.

This prevents invalid data from reaching the Gold layer.

---

# 18. How would you handle pipeline failures?

Production pipelines should distinguish between:

### Application failures

Examples:

- Invalid transformation logic
- Schema mismatch
- Data-quality failure

### Infrastructure failures

Examples:

- Spark capacity unavailable
- Service throttling
- Network problems

### Source failures

Examples:

- Source unavailable
- Authentication failure
- Missing input file

Handling can include:

- Retry policies
- Failure branches
- Alerts
- Operational logging
- Quarantine processing
- Restartability

---

# 19. Real Fabric Capacity Issue Encountered in This Project

During implementation, the pipeline encountered:

`TooManyRequestsForCapacity`

with HTTP 430 while Fabric attempted to create a Spark Livy session.

The notebook code itself was not the problem.

The platform did not have enough available Spark capacity to start another session.

This demonstrates why production engineering must monitor both:

- Application logic
- Platform capacity

Eventually the complete pipeline executed successfully.

This is a useful real-world example of distinguishing infrastructure failure from code failure.

---

# 20. What is Fabric Spark?

Microsoft Fabric provides managed Apache Spark capabilities for distributed data processing.

Spark can be used through:

- Fabric notebooks
- PySpark
- Spark SQL

Spark is useful for:

- Large-scale transformations
- Distributed joins
- Aggregations
- Complex data processing
- Data science workloads

---

# 21. Why PySpark?

PySpark provides the Python API for Apache Spark.

Benefits include:

- Distributed processing
- Python development model
- DataFrame API
- Integration with Delta
- Large-scale transformation capability

In this project PySpark implements:

Bronze → Silver

and:

Silver → Gold

processing.

---

# 22. Spark Performance — What Should You Mention?

Do not randomly list optimization techniques.

Start with measurement.

Say:

> I first inspect the Spark execution plan and identify expensive shuffles, skew, unnecessary scans, or small-file problems.

Then discuss possible techniques:

- Broadcast joins
- Partitioning
- Predicate pushdown
- Column pruning
- Avoiding unnecessary shuffles
- Delta optimization
- Managing small files

Optimization should be workload-driven.

---

# 23. What is a Broadcast Join?

A broadcast join sends a relatively small dataset to worker nodes so a large distributed shuffle may be avoided.

Example:

Large claims fact

joined with

Small policy reference/dimension

If the dimension is appropriately small, broadcasting it can improve performance.

Do not say:

"I always broadcast dimension tables."

Say:

"I evaluate whether the smaller side is suitable for broadcasting."

---

# 24. What is Data Partitioning?

Partitioning determines how data is distributed.

Good partitioning can improve:

- Parallelism
- Data skipping
- Query performance

Poor partitioning can create:

- Data skew
- Too many small partitions
- Excessive files
- Expensive shuffles

Partitioning should reflect data distribution and access patterns.

---

# 25. What is Data Skew?

Data skew occurs when data is distributed unevenly across Spark partitions.

Example:

If one customer or product contains a disproportionately large percentage of records, one partition may process much more data than the others.

Symptoms include:

- One task running much longer
- Uneven executor utilization
- Slow joins
- Large shuffle partitions

Possible mitigation depends on the workload and can include repartitioning or redesigning the join strategy.

---

# 26. What is the SQL Analytics Endpoint?

Fabric Lakehouses provide a SQL analytical experience over Lakehouse tables.

This allows SQL-oriented users and tools to query Lakehouse data without requiring them to write Spark code.

Conceptually:

Lakehouse Delta Tables
        ↓
SQL Analytics Endpoint
        ↓
SQL / Semantic Model / BI

This provides multiple consumption patterns over the same analytical data.

---

# 27. Spark vs SQL Endpoint

Spark is primarily used for distributed engineering and transformation workloads.

The SQL endpoint is useful for SQL-based analytical access.

Use Spark when:

- Performing large-scale transformations
- Processing complex datasets
- Running engineering workloads

Use SQL when:

- Analysts need relational querying
- Building SQL views
- Performing analytical queries
- Supporting downstream SQL-based consumption

They complement each other.

---

# 28. What is a Power BI Semantic Model?

A semantic model provides a business abstraction over physical data.

It defines:

- Tables
- Relationships
- Measures
- Hierarchies
- Formatting
- Business metadata

The semantic model allows report developers to work with business concepts instead of repeatedly recreating physical joins and calculations.

---

# 29. Semantic Model in This Project

The project contains:

`Insurance_Gold_Semantic_Model`

It sits over:

- `dim_policy`
- `dim_customer`
- `fact_claim`
- `fact_payment`

The model contains relationships and DAX measures.

Examples:

- Total Claims
- Total Claim Amount
- Total Approved Amount
- Approval Rate

---

# 30. Why not calculate every metric in Spark?

Because engineering transformations and interactive analytical calculations serve different purposes.

Spark is appropriate for:

- Cleansing
- Integration
- Entity construction
- Persistent business transformations

DAX is appropriate for:

- Dynamic aggregation
- Ratios
- KPIs
- Filter-context calculations

Example:

Approval Rate should change when the user selects:

AUTO
California
2025

That makes it suitable for the semantic layer.

---

# 31. What is DAX Filter Context?

DAX measures are evaluated based on the current filter context.

Filters can come from:

- Slicers
- Visual axes
- Page filters
- Report filters
- Relationships

For example:

Total Claim Amount

can automatically recalculate when the user selects:

Product Type = AUTO

because the semantic model relationships propagate the filter to the claims fact table.

---

# 32. Power BI Integration with Fabric

One of Fabric's strengths is tight integration with Power BI.

A typical Fabric analytical flow is:

OneLake
→ Lakehouse
→ Gold Tables
→ Semantic Model
→ Power BI

Power BI can therefore consume business-ready data without creating another independent data-engineering pipeline.

---

# 33. Power BI Report in This Project

The report is:

`VM_Fabric_101`

It contains:

### KPI Cards

- Total Claims
- Total Claim Amount
- Total Approved Amount
- Approval Rate

### Analytical Visuals

- Claim Amount by Product Type
- Claims by Claim Type
- Claim Amount by State
- Claim Amount by Year

### Slicers

- Product Type
- State
- Claim Year

These slicers demonstrate semantic-model filtering across the analytical model.

---

# 34. What is Direct Lake?

Direct Lake is a Fabric semantic-model storage/access mode designed to allow Power BI to query Fabric data in OneLake with reduced need for traditional data import copies.

The architectural objective is to provide interactive BI performance while taking advantage of data already stored in Fabric.

In an interview, explain the concept rather than claiming every Fabric model automatically uses Direct Lake.

---

# 35. Import vs DirectQuery vs Direct Lake

## Import

Data is loaded into the Power BI semantic model.

Advantages:

- Strong interactive performance

Trade-off:

- Requires refresh and another data copy.

## DirectQuery

Queries are sent to the underlying source during report interaction.

Advantages:

- Less data duplication

Trade-offs:

- Query latency
- Source performance dependency

## Direct Lake

Designed for Fabric/OneLake scenarios.

It provides analytical access over Fabric data while reducing traditional import-copy requirements.

The appropriate mode depends on workload requirements.

---

# 36. What is OneLake Shortcuts?

OneLake shortcuts allow Fabric to reference data without necessarily creating another physical copy.

Conceptually:

External / Other Data Location
        ↓
OneLake Shortcut
        ↓
Fabric Workload

This supports data virtualization and reduces unnecessary movement.

Potential sources can include other OneLake locations and supported external storage systems.

---

# 37. Why are Shortcuts important?

Enterprise organizations frequently already have data stored in multiple locations.

Copying every dataset into another platform creates:

- Storage duplication
- Latency
- Governance problems
- Synchronization complexity

Shortcuts provide a way to expose data through OneLake while minimizing unnecessary copying.

---

# 38. How would you implement incremental processing?

Production systems should avoid complete reloads when datasets become large.

Possible techniques:

- Watermarks
- Last-modified timestamps
- CDC
- Incremental Delta MERGE

Example:

Read last successful watermark
        ↓
Extract changed records
        ↓
Bronze
        ↓
Incremental Silver processing
        ↓
MERGE into Gold

---

# 39. What is Delta MERGE?

MERGE supports insert/update logic against Delta tables.

Conceptually:

If business key exists:
    UPDATE

If business key does not exist:
    INSERT

This is useful for:

- Incremental loading
- Upserts
- Dimension maintenance
- CDC processing

---

# 40. What is Idempotency?

An idempotent pipeline can safely be rerun without incorrectly duplicating data.

For example, rerunning the same batch should not create a second copy of every claim.

Techniques include:

- Business keys
- Batch identifiers
- MERGE
- Watermarks
- Deduplication

Idempotency is important for recoverability.

---

# 41. How would you monitor a Fabric platform?

Think in layers.

## Pipeline Monitoring

- Status
- Duration
- Failed activities
- Retry count

## Spark Monitoring

- Job duration
- Stage performance
- Shuffle behavior
- Capacity utilization

## Data Monitoring

- Row counts
- Data quality
- Freshness
- Schema changes

## Business Monitoring

- Expected KPI availability
- Refresh completion
- SLA compliance

Monitoring should cover both technical execution and business data availability.

---

# 42. What is Fabric Capacity?

Fabric workloads execute against allocated compute capacity.

Different workloads compete for available capacity.

Capacity planning therefore matters for:

- Spark
- Pipelines
- Warehousing
- Power BI
- Concurrent users

The HTTP 430 Spark issue encountered in this project is a practical example of capacity contention.

---

# 43. How would you handle capacity problems?

Possible strategies include:

- Monitor concurrency
- Schedule heavy workloads appropriately
- Reuse Spark sessions where applicable
- Configure retry behavior
- Avoid unnecessary concurrent processing
- Optimize Spark workloads
- Scale capacity when justified

Capacity should be treated as an architectural resource, not an unlimited service.

---

# 44. Fabric Security

A production design should consider security at several levels.

### Workspace

Control who can access Fabric items.

### Data

Restrict access to sensitive datasets.

### Semantic Model

Control analytical access and potentially apply row-level security.

### Power BI

Control report and app distribution.

### Identity

Use managed/workspace/service identities where appropriate rather than embedding credentials.

---

# 45. What is Row-Level Security?

Row-Level Security restricts which rows a user can see.

Example:

A regional claims manager may see only claims for their assigned region.

The report can remain the same while the semantic model restricts the visible data based on user identity.

---

# 46. Governance in Fabric

Enterprise governance includes:

- Data ownership
- Lineage
- Classification
- Sensitivity
- Access control
- Auditing
- Discoverability

A platform is not governed simply because the data is stored in one place.

Governance requires policies, metadata, ownership, and operational controls.

---

# 47. Development / Test / Production

Production Fabric implementations should separate environments.

Example:

DEV
→ TEST
→ PROD

Changes should not be made directly in production.

Artifacts should move through controlled deployment and validation processes.

---

# 48. Git and CI/CD

Fabric artifacts should be version controlled where supported.

Version control provides:

- Change history
- Collaboration
- Review
- Rollback
- Controlled deployment

This repository captures:

- PySpark notebooks
- Pipeline JSON
- Semantic model TMDL
- Power BI PBIX
- Architecture
- Documentation

---

# 49. TMDL

TMDL stands for Tabular Model Definition Language.

It provides a text-based representation of tabular semantic models.

This is useful for:

- Version control
- Model inspection
- Code review
- Automation

This project stores:

`Insurance_Gold_Semantic_Model.tmdl`

in the repository.

---

# 50. End-to-End Fabric Architecture Answer

If an interviewer asks:

"Walk me through how you would build an analytics platform using Microsoft Fabric."

Use this answer:

> I would start with the source and ingestion requirements and use Fabric Data
> Pipelines to orchestrate ingestion into OneLake. I would normally preserve a
> Bronze layer so the original source data remains recoverable.
>
> For engineering transformations I would use a Fabric Lakehouse and Spark,
> standardizing the data into Silver. I would introduce explicit data-quality
> validation before promoting trusted data into Gold.
>
> Gold would represent the business-oriented analytical model, typically using
> dimensions and facts where appropriate.
>
> I would expose that through a semantic model where relationships and reusable
> DAX business measures are defined centrally.
>
> Power BI would consume that semantic layer rather than duplicating business
> logic inside individual reports.
>
> Fabric Data Pipelines would orchestrate the workflow, while monitoring,
> capacity management, security, governance, incremental processing and CI/CD
> would be treated as production architecture concerns.
>
> OneLake is the common data foundation connecting those Fabric workloads and
> reducing unnecessary data movement.

---

# 51. Rapid-Fire Interview Questions

## What is Fabric?

An integrated SaaS analytics platform covering ingestion, engineering,
analytics, semantic modeling and BI.

## What is OneLake?

The unified logical data lake foundation for Microsoft Fabric.

## What is a Lakehouse?

A data architecture combining data-lake flexibility with structured table and
analytical capabilities.

## What table format does Fabric Lakehouse commonly use?

Delta.

## Bronze?

Raw/source-oriented data.

## Silver?

Cleaned, standardized and reusable data.

## Gold?

Business-oriented analytical data.

## Pipeline?

Orchestration and data movement.

## Notebook?

Processing and transformation.

## Semantic model?

Business abstraction containing relationships, measures and analytical
metadata.

## DAX?

Expression language used for analytical calculations in Power BI semantic
models.

## Direct Lake?

Fabric analytical access mode designed around data stored in OneLake.

## Shortcut?

A OneLake reference to data without necessarily physically copying it.

## TMDL?

Text-based definition language for tabular semantic models.

## Data quality gate?

A validation stage that prevents invalid data from progressing downstream.

## Idempotency?

Ability to rerun processing without incorrectly duplicating or corrupting the
result.

## Watermark?

A marker identifying the last successfully processed point for incremental
processing.

---

# 52. What You Should Be Able to Draw From Memory

Practice drawing this without looking at the repository:

```text
                         Microsoft Fabric
                                |
                            OneLake
                                |
Source
   |
   v
Data Pipeline
   |
   v
LH_Bronze
   |
   v
PySpark
   |
   v
LH_Silver
   |
   v
Data Quality
   |
   v
PySpark
   |
   v
LH_Gold
   |
   +-------------------+
   |                   |
SQL Endpoint      Semantic Model
                       |
                       v
                    Power BI
```

Then draw the orchestration underneath:

```text
PL_Insurance_Medallion_ETL

01 Load Bronze
       ↓
02 Bronze → Silver
       ↓
03 Data Quality
       ↓
04 Silver → Gold
```

If you can draw and explain these two diagrams naturally, you can answer a
large percentage of Microsoft Fabric architecture questions.

---

# 53. Avoid These Interview Mistakes

Do not say:

"OneLake is just another storage account."

Do not say:

"Lakehouse and Warehouse are basically the same."

Do not say:

"Spark is always faster than SQL."

Do not say:

"I always use broadcast joins."

Do not say:

"Everything should be calculated in Gold."

Do not say:

"Fabric removes the need for architecture."

Instead explain the trade-offs and why each component exists.

---

# 54. Final Memory Framework

When answering Fabric questions, remember:

## STORE

OneLake + Lakehouse

## MOVE

Data Pipelines

## PROCESS

Spark + PySpark

## TRUST

Silver + Data Quality

## MODEL

Gold + Semantic Model

## CALCULATE

DAX

## CONSUME

Power BI

## OPERATE

Pipeline Orchestration + Monitoring + Capacity

## GOVERN

Security + Lineage + Access Control

## DEPLOY

Git + CI/CD + DEV/TEST/PROD

That is the complete Fabric architecture story.
