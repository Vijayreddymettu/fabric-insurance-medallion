Architecture Design Decisions

## Purpose

This document explains the major architecture decisions behind the Microsoft
Fabric Insurance Medallion Platform.

The objective was not simply to move data between Fabric components. The
solution was designed to demonstrate separation of concerns, recoverability,
data quality, business modeling, orchestration, and governed analytical
consumption.

---

## 1. Why Medallion Architecture?

The solution uses Bronze, Silver, and Gold layers rather than transforming
source data directly into reporting tables.

### Bronze

Purpose:

- Preserve source-oriented data
- Provide a recoverable ingestion point
- Support replay and reprocessing
- Isolate source ingestion from transformation logic

### Silver

Purpose:

- Cleanse and standardize data
- Normalize schemas and data types
- Provide reusable validated datasets
- Establish a controlled data-quality boundary

### Gold

Purpose:

- Apply business transformations
- Build analytical entities
- Organize data into dimensions and facts
- Optimize data for semantic modeling and reporting

This separation reduces coupling between ingestion, engineering
transformations, and analytical consumption.

---

## 2. Why Separate Ingestion from Transformation?

Data ingestion is handled by:

`PL_Load_Insurance_Data`

Transformation is handled by PySpark notebooks.

This separation is intentional.

If ingestion and transformation are tightly coupled, changes to business
logic can unnecessarily affect source ingestion.

Separating the two provides:

- Independent deployment
- Independent troubleshooting
- Easier reruns
- Better lineage
- Reduced coupling
- Clear ownership boundaries

Source data can therefore be reprocessed without requiring it to be
re-extracted from the original source.

---

## 3. Why Use Lakehouses?

The solution uses Fabric Lakehouses for Bronze, Silver, and Gold storage.

Lakehouse architecture combines scalable data-lake storage with structured
table capabilities required by analytical workloads.

This provides a common platform for:

- Spark processing
- Delta tables
- SQL analytics
- Data engineering
- Semantic modeling
- Power BI consumption

Using OneLake also reduces the need to move data between separate analytical
storage platforms.

---

## 4. Why PySpark for Transformations?

PySpark is used for Bronze-to-Silver and Silver-to-Gold processing.

The design demonstrates a distributed transformation approach suitable for
larger enterprise datasets.

PySpark supports:

- Distributed processing
- Complex transformations
- Schema handling
- Data-quality logic
- Reusable transformation code
- Scalable joins and aggregations

For the demonstration dataset the volume is relatively small, but the
architecture pattern is designed to scale beyond the sample workload.

This distinction is important: technology selection should reflect the
target architecture rather than claiming that a small sample dataset itself
requires distributed processing.

---

## 5. Why a Dedicated Data Quality Stage?

Data-quality validation is implemented through:

`NB_Silver_Data_Quality`

rather than relying only on checks embedded inside transformation notebooks.

This creates an explicit quality gate.

The intended execution model is:

Silver Transformation
        ↓
Data Quality Validation
        ↓
Gold Promotion

If validation fails, Gold processing should not execute.

This protects business-facing analytical datasets from known invalid data.

It also makes quality failures easier to:

- Identify
- Monitor
- Troubleshoot
- Audit
- Extend with additional rules

---

## 6. Why Dimensional Modeling in Gold?

The Gold layer contains:

- `dim_policy`
- `dim_customer`
- `fact_claim`
- `fact_payment`

This structure separates descriptive business entities from transactional
facts.

Benefits include:

- Easier analytical querying
- Clear relationships
- Consistent business dimensions
- Simplified semantic modeling
- Better reporting usability

The Gold layer therefore represents business-oriented analytical data rather
than another copy of operational source structures.

---

## 7. Why a Separate Semantic Model?

Power BI does not directly own the physical transformation logic.

Instead:

`Insurance_Gold_Semantic_Model`

provides the business abstraction between Gold tables and reporting.

The semantic model centralizes:

- Relationships
- Measures
- DAX calculations
- Aggregation behavior
- Reporting metadata

For example:

- Total Claims
- Total Claim Amount
- Total Approved Amount
- Approval Rate

can be defined once and reused by report visuals.

This prevents different reports from independently implementing different
versions of the same business calculation.

---

## 8. Why Use a Master Orchestration Pipeline?

The platform uses:

`PL_Insurance_Medallion_ETL`

as the master orchestration pipeline.

The master pipeline coordinates:

1. Bronze ingestion
2. Bronze-to-Silver transformation
3. Silver data-quality validation
4. Silver-to-Gold transformation

This provides one operational entry point for the complete ETL workflow.

Benefits include:

- Centralized orchestration
- Dependency management
- Operational visibility
- Failure tracking
- Scheduling
- Easier production support

---

## 9. Why Use Success Dependencies?

Pipeline activities are connected through success dependencies.

Conceptually:

Load Bronze
    ↓ success
Bronze → Silver
    ↓ success
Data Quality
    ↓ success
Silver → Gold

This ensures that downstream processing does not continue after an upstream
failure.

For example, if the data-quality notebook fails, the Gold transformation
should not execute.

This protects downstream analytical datasets from partial or invalid
processing.

---

## 10. Why Keep Business Metrics Out of ETL Where Appropriate?

Not every calculation belongs in PySpark.

Physical data transformations belong primarily in the engineering layer.

Interactive analytical calculations and reusable business measures can be
implemented in the semantic layer.

For example:

`Approval Rate`

is appropriate as a semantic measure when it needs to respond dynamically to
Power BI filter context.

This provides clearer separation between:

### Data Engineering Logic

- Cleansing
- Standardization
- Entity construction
- Data integration

### Semantic / Analytical Logic

- Aggregations
- Ratios
- KPI calculations
- Filter-aware business measures

---

## 11. Why Version-Control the Artifacts?

The project stores implementation artifacts in a local repository structure:

- Notebooks
- Pipeline definitions
- Semantic model TMDL
- Power BI report
- Architecture-as-code
- Documentation

This makes the solution easier to:

- Review
- Explain
- Reproduce
- Maintain
- Place under Git version control
- Use as a technical portfolio project

Architecture documentation is also represented using Mermaid so that the
diagram itself can be maintained as code.

---

## 12. Production Considerations

The project demonstrates the core architecture pattern, but a production
enterprise implementation would extend it further.

Potential production enhancements include:

### Incremental Processing

Instead of processing complete datasets on every execution:

- Watermark-based ingestion
- Change Data Capture
- Incremental Delta processing

could be introduced.

### Data Quality Framework

The dedicated quality notebook could evolve into a metadata-driven framework
containing:

- Rule definitions
- Rule severity
- Failed-record quarantine
- Quality scores
- Historical quality metrics

### Observability

Production monitoring could include:

- Pipeline duration
- Record counts
- Failed records
- Data freshness
- Spark execution metrics
- SLA compliance
- Capacity utilization

### Failure Handling

Production orchestration could add:

- Retry policies
- Failure branches
- Alerting
- Operational logging
- Dead-letter/quarantine processing

### Security and Governance

Enterprise implementation should include:

- Workspace access controls
- Least-privilege permissions
- Sensitivity classification
- Data lineage
- Data ownership
- Auditability

### CI/CD

Fabric artifacts should ultimately move through controlled environments such
as:

Development
→ Test
→ Production

using source control and deployment automation.

---

## 13. Scalability Considerations

As data volume grows, Spark optimization becomes increasingly important.

Potential optimization techniques include:

- Appropriate partitioning
- Avoiding unnecessary shuffles
- Broadcast joins for suitable small dimensions
- Predicate pushdown
- Column pruning
- Efficient Delta table design
- Avoiding excessive small files
- Monitoring Spark execution plans

These optimizations should be applied based on measured workload behavior
rather than automatically applied to every transformation.

---

## 14. Architecture Trade-offs

No architecture is free of trade-offs.

The layered design introduces additional processing stages and artifacts.

However, that additional structure provides:

- Recoverability
- Reusability
- Quality control
- Clear lineage
- Separation of concerns
- Easier troubleshooting

For enterprise analytics, those benefits generally outweigh the additional
pipeline complexity.

---

## Key Architecture Principle

The core design principle is:

> Raw data should remain recoverable, standardized data should be reusable,
> business data should be trusted, and business metrics should be defined
> consistently.

The Bronze, Silver, Gold, data-quality, semantic, and orchestration layers
each exist to support a specific part of that principle.
