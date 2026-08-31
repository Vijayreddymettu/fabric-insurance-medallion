

# Microsoft Fabric Insurance Medallion Platform

## Project Overview

This project demonstrates the design and implementation of an end-to-end
insurance data and analytics platform using Microsoft Fabric.

The solution implements a Medallion Architecture using Bronze, Silver,
and Gold Lakehouses, Fabric Data Pipelines, PySpark notebooks, data-quality
validation, a Power BI semantic model, and an interactive insurance claims
dashboard.

## Business Scenario

Insurance organizations typically receive operational data from multiple
business domains including:

- Policies
- Customers
- Claims
- Payments

Operational data is not immediately suitable for enterprise analytics.
It must be ingested, standardized, validated, transformed into business
entities, and exposed through a governed analytical model.

This project demonstrates that complete lifecycle.

## Solution Architecture

The high-level processing flow is:

Source Data
→ Fabric Data Pipeline
→ Bronze Lakehouse
→ PySpark Transformation
→ Silver Lakehouse
→ Data Quality Validation
→ Gold Transformation
→ Gold Lakehouse
→ Semantic Model
→ Power BI

The entire workflow is orchestrated by the master pipeline:

`PL_Insurance_Medallion_ETL`

## Microsoft Fabric Components

### Data Pipelines

`PL_Load_Insurance_Data`

Responsible for ingestion into the Bronze layer.

`PL_Insurance_Medallion_ETL`

Master orchestration pipeline coordinating the end-to-end workflow.

### Lakehouses

`LH_Bronze`

Raw ingestion layer.

`LH_Silver`

Cleansed and standardized data layer.

`LH_Gold`

Business-ready dimensional analytics layer.

### PySpark Notebooks

`NB_Bronze_To_Silver_full`

Transforms raw Bronze data into standardized Silver datasets.

`NB_Silver_Data_Quality`

Performs data-quality validation before Gold promotion.

`NB_Silver_To_Gold`

Transforms Silver data into analytics-ready Gold entities.

### Gold Data Model

The Gold layer contains:

- `dim_policy`
- `dim_customer`
- `fact_claim`
- `fact_payment`

This provides a dimensional foundation for analytical consumption.

### Semantic Model

`Insurance_Gold_Semantic_Model`

Provides relationships, business measures, DAX calculations, and reporting
metadata over the Gold analytical model.

### Power BI

`VM_Fabric_101`

Interactive claims analytics report providing:

- Total Claims
- Total Claim Amount
- Total Approved Amount
- Approval Rate
- Product analysis
- Claim-type analysis
- Geographic analysis
- Claim-year trends

## Data Quality Strategy

Data quality is implemented as an explicit processing stage rather than
being embedded only inside transformation logic.

The Silver data-quality stage provides a controlled validation point before
data is promoted to the business-facing Gold layer.

This pattern improves:

- Reliability
- Troubleshooting
- Auditability
- Data trust
- Separation of responsibilities

## Orchestration Strategy

The master pipeline executes the platform in dependency order:

1. Load source data into Bronze.
2. Transform Bronze data into Silver.
3. Validate Silver data quality.
4. Transform validated Silver data into Gold.
5. Expose Gold data through the semantic model and Power BI.

Downstream activities depend on successful completion of upstream stages,
preventing invalid or incomplete data from progressing through the platform.

## Repository Structure

```text
FABRIC-INSURANCE-MEDALLION/
├── architecture/
├── docs/
├── notebooks/
├── pipelines/
├── powerbi/
├── screenshots/
├── semantic-model/
├── sql/
└── README.md
```
