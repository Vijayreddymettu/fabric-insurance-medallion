End-to-End Data Flow

## 1. Overview

The Microsoft Fabric Insurance Medallion Platform implements an end-to-end
data engineering flow from insurance source data through ingestion,
transformation, validation, dimensional modeling, semantic modeling, and
Power BI analytics.

The processing path is:

Source Data
→ PL_Load_Insurance_Data
→ LH_Bronze
→ NB_Bronze_To_Silver_full
→ LH_Silver
→ NB_Silver_Data_Quality
→ NB_Silver_To_Gold
→ LH_Gold
→ Insurance_Gold_Semantic_Model
→ VM_Fabric_101 Power BI Report

The overall workflow is orchestrated by:

`PL_Insurance_Medallion_ETL`

---

## 2. Source Data

The platform processes four primary insurance business domains:

- Policy
- Customer
- Claim
- Payment

These domains represent the operational inputs required for claims analytics.

The architecture intentionally separates source ingestion from downstream
business transformation.

This allows source data to be preserved before applying cleansing,
standardization, or analytical business rules.

---

## 3. Ingestion — PL_Load_Insurance_Data

The first processing stage is the Fabric pipeline:

`PL_Load_Insurance_Data`

Its responsibility is to move source data into the Bronze Lakehouse.

The ingestion pipeline is invoked by the master orchestration pipeline rather
than being tightly coupled with transformation notebooks.

### Design Purpose

Separating ingestion provides:

- Independent ingestion and transformation lifecycle
- Easier troubleshooting
- Reprocessing capability
- Clear operational boundaries
- Better pipeline lineage

### Output

The ingestion process lands data in:

`LH_Bronze`

---

## 4. Bronze Layer — LH_Bronze

The Bronze layer represents the raw landing zone of the Medallion Architecture.

Its primary purpose is to retain source-oriented data before business
transformations are applied.

### Responsibilities

The Bronze layer provides:

- Raw data persistence
- Source-level traceability
- Replay/reprocessing capability
- Isolation between source systems and transformation logic

The Bronze layer should generally remain as close as practical to the source
representation.

This is important because transformation logic can change while the original
source data remains available for reprocessing.

---

## 5. Bronze-to-Silver Transformation

The notebook:

`NB_Bronze_To_Silver_full`

reads Bronze data and performs cleansing and standardization.

### Typical Processing

The transformation includes operations such as:

- Data-type normalization
- String trimming
- Case standardization
- Date conversion
- Null handling
- Field normalization
- Technical metadata generation
- Schema standardization

PySpark is used to perform distributed transformations within Microsoft
Fabric.

### Input

`LH_Bronze`

### Output

`LH_Silver`

The result is a standardized representation suitable for validation and
business transformation.

---

## 6. Silver Layer — LH_Silver

The Silver Lakehouse contains cleansed and standardized insurance data.

At this stage, data has moved beyond raw source representation but has not yet
been promoted into the final analytical business model.

The Silver layer acts as the reusable enterprise transformation layer between
raw ingestion and business-facing Gold datasets.

### Benefits

This provides:

- Consistent schemas
- Standardized data types
- Reusable cleansed datasets
- Separation between technical cleansing and business modeling
- A controlled point for data-quality validation

---

## 7. Data Quality Gate

The notebook:

`NB_Silver_Data_Quality`

provides an explicit quality-control stage.

Rather than relying exclusively on transformation code to implicitly produce
valid data, the architecture introduces a dedicated validation stage before
Gold promotion.

### Validation Concept

Quality checks can include:

- Required-field validation
- Null checks
- Key integrity
- Duplicate detection
- Domain validation
- Referential consistency
- Record-count validation
- Business-rule validation

### Why the Quality Gate Matters

If validation fails, downstream Gold processing should not proceed.

This prevents known bad data from reaching:

- Gold analytical tables
- Semantic models
- Business measures
- Executive dashboards

The pipeline therefore treats data quality as part of orchestration rather
than merely a reporting concern.

---

## 8. Silver-to-Gold Transformation

After Silver data successfully passes validation, the notebook:

`NB_Silver_To_Gold`

performs business-oriented transformations.

The purpose of this stage is different from Bronze-to-Silver.

Bronze-to-Silver focuses primarily on technical cleansing and standardization.

Silver-to-Gold focuses on analytical business structure.

### Input

`LH_Silver`

### Output

`LH_Gold`

---

## 9. Gold Layer — LH_Gold

The Gold Lakehouse contains the analytics-ready dimensional model.

The implemented Gold model contains:

### Dimensions

`dim_policy`

Contains policy-related descriptive attributes.

`dim_customer`

Contains customer-related descriptive attributes.

### Facts

`fact_claim`

Contains claim transactions and claim-related metrics.

`fact_payment`

Contains payment-related transactional information.

The separation between dimensions and facts provides a business-oriented
analytical structure suitable for semantic modeling and reporting.

---

## 10. Semantic Layer

The Gold tables feed:

`Insurance_Gold_Semantic_Model`

The semantic model creates a business-friendly analytical abstraction over the
physical Gold tables.

### Responsibilities

The semantic model provides:

- Table relationships
- Business measures
- DAX calculations
- Aggregation behavior
- Reporting metadata

Examples of exposed business metrics include:

- Total Claims
- Total Claim Amount
- Total Approved Amount
- Approval Rate

This design prevents business calculations from being duplicated independently
across reports.

---

## 11. Power BI Consumption

The final analytical layer is:

`VM_Fabric_101`

The Power BI report consumes the Gold semantic model.

The report provides KPI and analytical views across the claims domain.

### KPI Cards

- Total Claims
- Total Claim Amount
- Total Approved Amount
- Approval Rate

### Analytical Visuals

- Total Claim Amount by Product Type
- Total Claims by Claim Type
- Total Claim Amount by State
- Total Claim Amount by Claim Year

### Interactive Filtering

The report supports filtering by:

- Product Type
- State
- Claim Year

This allows business users to analyze claim behavior across different
insurance products, geographies, and time periods.

---

## 12. Master Orchestration

The entire engineering workflow is coordinated through:

`PL_Insurance_Medallion_ETL`

The pipeline executes the major stages sequentially.

### Execution Flow

1. `01_Load_Bronze`

   - Invokes `PL_Load_Insurance_Data`
2. `02_Bronze_To_Silver`

   - Executes `NB_Bronze_To_Silver_full`
3. `03_Silver_Data_Quality`

   - Executes `NB_Silver_Data_Quality`
4. `04_Silver_To_Gold`

   - Executes `NB_Silver_To_Gold`

Each downstream stage uses a success dependency on the preceding activity.

Conceptually:

PL_Load_Insurance_Data
        ↓ success
NB_Bronze_To_Silver_full
        ↓ success
NB_Silver_Data_Quality
        ↓ success
NB_Silver_To_Gold

This prevents downstream processing when an upstream stage fails.

---

## 13. Failure Handling

The orchestration design follows a fail-fast pattern.

For example, if:

`NB_Silver_Data_Quality`

fails, then:

`NB_Silver_To_Gold`

does not execute.

This protects Gold datasets from invalid Silver data.

During implementation, Fabric Spark capacity contention was also encountered.

The pipeline correctly surfaced the notebook execution failure rather than
silently continuing downstream processing.

This demonstrates the importance of separating:

- Data failures
- Code failures
- Infrastructure/capacity failures

in production data platforms.

---

## 14. Scheduling

The master pipeline supports scheduled execution through the Microsoft Fabric
job scheduler.

A daily schedule was configured during implementation and subsequently
disabled after validation/documentation.

This demonstrates that the pipeline can operate both:

- On demand
- On a scheduled production cadence

---

## 15. End-to-End Lineage

The resulting lineage is:

Insurance Sources
        ↓
PL_Load_Insurance_Data
        ↓
LH_Bronze
        ↓
NB_Bronze_To_Silver_full
        ↓
LH_Silver
        ↓
NB_Silver_Data_Quality
        ↓
NB_Silver_To_Gold
        ↓
LH_Gold
        ↓
Insurance_Gold_Semantic_Model
        ↓
VM_Fabric_101 Power BI Report

This provides clear traceability from source ingestion to business
consumption.

---

## Interview Summary

A concise explanation of the architecture is:

> I designed the solution using Microsoft Fabric's Medallion Architecture.
> Source insurance data is first ingested through a Fabric pipeline into the
> Bronze Lakehouse so that we retain a recoverable raw layer. PySpark then
> cleanses and standardizes that data into Silver. Before promoting anything
> to Gold, I introduced a dedicated data-quality gate so invalid data cannot
> reach the analytical layer. The Silver-to-Gold transformation creates a
> dimensional model with policy and customer dimensions and claim and payment
> facts. A Power BI semantic model sits over Gold and centralizes relationships
> and DAX business measures such as Total Claims, Claim Amount, Approved Amount,
> and Approval Rate. Power BI consumes that semantic layer for claims
> analytics. The entire process is orchestrated through a master Fabric
> pipeline with success dependencies between each processing stage.
