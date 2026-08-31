# Architecture — Microsoft Fabric Insurance Medallion Platform

## Overview

This project implements an end-to-end insurance analytics platform using
Microsoft Fabric and the Medallion Architecture pattern.

The solution separates ingestion, transformation, data quality, business
modeling, semantic modeling, and analytics into independently maintainable
layers.

## Architecture Flow

Insurance Source Data
→ PL_Load_Insurance_Data
→ LH_Bronze
→ NB_Bronze_To_Silver_full
→ LH_Silver
→ NB_Silver_Data_Quality
→ NB_Silver_To_Gold
→ LH_Gold
→ Insurance_Gold_Semantic_Model
→ Power BI

## 1. Source Layer

The platform processes insurance-domain data including:

- Policy
- Customer
- Claims
- Payments

The ingestion process is orchestrated through the Fabric data pipeline
`PL_Load_Insurance_Data`.

## 2. Bronze Layer

### LH_Bronze

The Bronze Lakehouse provides the raw ingestion layer.

Purpose:

- Preserve source data
- Establish a recoverable ingestion layer
- Separate source ingestion from downstream transformations
- Support reprocessing when transformation logic changes

## 3. Silver Layer

### NB_Bronze_To_Silver_full

The Bronze-to-Silver notebook performs cleansing and standardization of
raw insurance data.

Typical responsibilities include:

- Data type standardization
- String normalization
- Date conversion
- Null handling
- Business-field normalization
- Technical metadata generation

Processed data is written to `LH_Silver`.

### NB_Silver_Data_Quality

A dedicated data-quality notebook validates Silver data before it is
promoted to the Gold layer.

This creates a quality gate between data engineering transformations and
business-facing analytical data.

## 4. Gold Layer

### NB_Silver_To_Gold

The Silver-to-Gold transformation creates analytics-ready business
entities.

### LH_Gold

The Gold Lakehouse contains the dimensional analytical model:

- `dim_policy`
- `dim_customer`
- `fact_claim`
- `fact_payment`

This layer is optimized for downstream semantic modeling and reporting.

## 5. Semantic Model

`Insurance_Gold_Semantic_Model` provides the business semantic layer over
the Gold model.

It contains:

- Table relationships
- Business measures
- DAX calculations
- Reporting metadata

This separates business metrics from physical data transformation logic.

## 6. Power BI Analytics

The `VM_Fabric_101` Power BI report consumes the Gold semantic model.

The report provides insurance claims analytics including:

- Total Claims
- Total Claim Amount
- Total Approved Amount
- Approval Rate
- Claims by Product Type
- Claims by Claim Type
- Claim Amount by State
- Claim Amount by Year

Interactive slicers allow analysis by product, state, and claim year.

## 7. Orchestration

`PL_Insurance_Medallion_ETL` acts as the master orchestration pipeline.

Execution sequence:

1. Invoke `PL_Load_Insurance_Data`
2. Execute `NB_Bronze_To_Silver_full`
3. Execute `NB_Silver_Data_Quality`
4. Execute `NB_Silver_To_Gold`

Success dependencies ensure that downstream processing only occurs after
the preceding stage completes successfully.

## Design Principles

The architecture demonstrates:

- Medallion Architecture
- Lakehouse-based data engineering
- Separation of ingestion and transformation
- Layered data quality controls
- Dimensional data modeling
- Pipeline orchestration
- Semantic modeling
- End-to-end lineage
- Power BI analytical consumption
- Version-controlled engineering artifacts

## Architecture Diagram

See:

`fabric-insurance-medallion-architecture.md`
