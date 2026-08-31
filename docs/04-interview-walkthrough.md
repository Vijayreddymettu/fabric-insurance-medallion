# Microsoft Fabric Insurance Medallion Platform

# Interview Walkthrough

## 1. 30-Second Architecture Answer

I built an end-to-end insurance data platform in Microsoft Fabric using a
Medallion architecture.

Source insurance data is ingested through a Fabric Data Pipeline into the
Bronze Lakehouse. PySpark notebooks then cleanse and standardize the data into
Silver, followed by a dedicated data-quality gate. After validation, another
notebook creates dimensional Gold tables including policy, customer, claims,
and payments.

A master Fabric pipeline orchestrates the complete workflow with success
dependencies. On top of Gold, I created a Power BI semantic model with
relationships and DAX measures, and finally a Power BI dashboard for insurance
claims analytics.

So the complete flow is:

Source
→ Bronze
→ Silver
→ Data Quality
→ Gold
→ Semantic Model
→ Power BI

---

# 2. Two-Minute Interview Answer

The architecture follows the Medallion pattern with separate Bronze, Silver,
and Gold Lakehouses in Microsoft Fabric.

The process starts with `PL_Load_Insurance_Data`, which handles source
ingestion and loads raw insurance data into the Bronze Lakehouse.

I intentionally keep Bronze close to the source representation because it
provides a recoverable ingestion layer. If downstream business logic changes,
I can reprocess from Bronze rather than extracting everything again from the
source.

The second stage is handled by the `NB_Bronze_To_Silver_full` PySpark
notebook. Here I clean and standardize the data, handle data types and prepare
reusable validated datasets in the Silver Lakehouse.

After Silver processing, I execute a separate notebook called
`NB_Silver_Data_Quality`.

That notebook acts as a quality gate. The important architectural point is
that Gold processing depends on successful completion of this validation.
If quality validation fails, the Gold transformation doesn't proceed.

After validation, `NB_Silver_To_Gold` creates the business-oriented Gold
model. I modeled the insurance data into dimensions and facts such as:

- `dim_policy`
- `dim_customer`
- `fact_claim`
- `fact_payment`

The entire workflow is orchestrated by the master pipeline
`PL_Insurance_Medallion_ETL`.

The dependency chain is:

`01_Load_Bronze`
→ `02_Bronze_To_Silver`
→ `03_Silver_Data_Quality`
→ `04_Silver_To_Gold`

Each downstream activity executes only after successful completion of the
previous stage.

Finally, the Gold layer feeds `Insurance_Gold_Semantic_Model`, where I define
relationships and reusable DAX measures.

Power BI consumes that semantic layer and provides claim, payment, approval,
product, state, and year-based analytics.

This gives me separation between ingestion, engineering transformation, data
quality, business modeling, semantic logic, and visualization.

---

# 3. Five-Minute Whiteboard Walkthrough

When explaining the architecture on a whiteboard, draw it from LEFT TO RIGHT.

## Step 1 — Source Systems

Start with:

Insurance Source Data

Policy | Customer | Claims | Payments

Explain:

"The architecture starts with operational insurance data representing policy,
customer, claim and payment information."

Do not spend much time here.

Immediately move to ingestion.

---

## Step 2 — Fabric Data Pipeline

Draw:

Source
   |
   v
PL_Load_Insurance_Data

Say:

"I separated ingestion from transformation.

The ingestion pipeline is responsible for moving source data into the
platform. Business transformations are handled separately."

Important interview phrase:

> This reduces coupling between source ingestion and downstream business
> transformation logic.

---

## Step 3 — Bronze Lakehouse

Draw:

PL_Load_Insurance_Data
        |
        v
    LH_Bronze

Say:

"Bronze is my raw ingestion layer.

I keep the data close to its source representation so that I maintain a
recoverable copy and can replay downstream processing without going back to
the original source."

Key concepts:

- Raw data
- Replay
- Recoverability
- Source isolation
- Auditability

---

## Step 4 — Bronze to Silver

Draw:

LH_Bronze
    |
    v
NB_Bronze_To_Silver_full
    |
    v
LH_Silver

Say:

"The next stage uses PySpark to clean and standardize the raw data.

This is where I handle schema normalization, data types, cleansing and
standardization."

If asked:

### Why Spark?

Answer:

"The demo dataset itself is small, so Spark isn't required because of its
current volume. I used PySpark because the architecture represents the
distributed processing pattern I would use for larger enterprise workloads."

That distinction is important.

Never claim that a tiny demonstration dataset requires a Spark cluster.

---

# 4. Data Quality Gate

Draw:

LH_Silver
    |
    v
NB_Silver_Data_Quality
    |
 SUCCESS
    |
    v
Gold

Explain:

"I intentionally separated data-quality validation from the transformation
notebook.

That gives me an explicit quality gate between Silver and Gold."

Then say:

"If the quality notebook fails, the Gold activity does not execute because
the orchestration uses success dependencies."

This is one of the strongest architectural points in the project.

---

# 5. Silver to Gold

Draw:

NB_Silver_Data_Quality
        |
        v
NB_Silver_To_Gold
        |
        v
     LH_Gold

Explain:

"Once the data passes validation, I apply business transformations and create
analytical entities."

Then draw:

LH_Gold

dim_policy
dim_customer
fact_claim
fact_payment

Explain:

"I separated descriptive entities into dimensions and transactional business
events into facts."

---

# 6. Semantic Layer

Draw:

LH_Gold
   |
   v
Insurance_Gold_Semantic_Model

Explain:

"I don't put every business calculation into Spark.

The Gold layer handles physical business-oriented data modeling, while the
semantic model handles reusable analytical calculations and reporting
relationships."

Examples:

- Total Claims
- Total Claim Amount
- Total Approved Amount
- Approval Rate

Explain:

"These measures are centralized so different reports don't implement
different versions of the same KPI."

---

# 7. Power BI

Finally draw:

Semantic Model
      |
      v
Power BI Dashboard

Explain:

"Power BI consumes the governed semantic layer rather than recreating business
logic independently inside individual visuals."

The dashboard provides analytics by:

- Product
- Claim type
- State
- Claim year
- Approval metrics

---

# 8. Master Pipeline

After drawing the data flow, draw a box underneath everything:

PL_Insurance_Medallion_ETL

Explain:

"This is the orchestration layer controlling the complete workflow."

Activities:

01_Load_Bronze
        ↓
02_Bronze_To_Silver
        ↓
03_Silver_Data_Quality
        ↓
04_Silver_To_Gold

Then say:

"The pipeline gives me centralized execution, dependency management,
monitoring and scheduling."

---

# 9. Interview Question:

## Why didn't you transform directly from source to Gold?

Answer:

"I wanted to separate ingestion, standardization and business modeling.

If I transform directly from source to Gold, business-rule changes can become
tightly coupled to source ingestion.

Bronze gives me recoverability, Silver gives me reusable standardized data,
and Gold gives me business-oriented analytical data."

---

# 10. Interview Question:

## What happens when the pipeline fails?

Answer:

"The activities use success dependencies, so downstream stages do not
continue after an upstream failure.

For example, if Silver data-quality validation fails, the Silver-to-Gold
notebook doesn't execute.

Operationally I can identify the failed activity through Fabric monitoring,
correct the underlying problem and rerun the appropriate processing."

For a production implementation I would extend this with:

- Retry policies
- Failure branches
- Alerting
- Operational logging
- Quarantine handling

---

# 11. Interview Question:

## How do you handle data quality?

Answer:

"I treat data quality as an architectural stage rather than only embedding
checks inside transformations.

After Bronze-to-Silver processing, a dedicated data-quality notebook validates
the Silver data before Gold promotion.

This creates a quality gate.

In a production environment I would evolve that into a metadata-driven
framework where rules, severity, thresholds and failed-record handling are
configuration driven."

---

# 12. Interview Question:

## Why separate Silver and Gold?

Answer:

"Silver represents standardized reusable enterprise data.

Gold represents business-oriented analytical structures.

That distinction allows multiple downstream business models to potentially
reuse the same standardized Silver datasets without repeating ingestion and
cleansing."

---

# 13. Interview Question:

## How would this scale?

Answer:

"The architecture scales independently at each layer.

For larger volumes I would introduce incremental ingestion and avoid full
reloads where possible.

At the Spark layer I would examine execution plans and optimize based on the
actual workload using techniques such as appropriate partitioning, broadcast
joins for suitable small dimensions, predicate pushdown, column pruning and
Delta table optimization.

The important point is that I wouldn't apply Spark optimizations blindly. I
would first identify where shuffles, skew, I/O or small-file problems are
actually occurring."

---

# 14. Interview Question:

## What would you change for production?

Answer:

"The current implementation demonstrates the architecture pattern.

For production I would add several capabilities."

Then group them instead of listing random technologies.

### Ingestion

- Incremental processing
- CDC where appropriate
- Watermark management

### Data Quality

- Metadata-driven rules
- Failed-record quarantine
- Historical quality metrics

### Operations

- Retry policies
- Failure notifications
- Centralized logging
- SLA monitoring

### Security

- Least privilege
- Workspace security
- Sensitivity classification
- Auditing

### DevOps

- Git integration
- Environment promotion
- CI/CD
- Development, Test and Production separation

---

# 15. Interview Question:

## Where would you optimize Spark?

Answer:

"I would first look at the Spark execution plan and identify expensive
shuffles, skewed joins, unnecessary scans or excessive small files.

For example, if I have a large claims fact dataset joining to a relatively
small reference or dimension dataset, a broadcast join could avoid a large
shuffle.

For larger fact processing I would evaluate partition strategy based on the
actual access pattern and data distribution."

Do NOT say:

"I always use broadcast joins."

Say:

"I use them when the smaller side of the join is appropriate for
broadcasting."

---

# 16. Interview Question:

## Why Fabric instead of separate Azure services?

Answer:

"One advantage of Fabric is that ingestion, Spark engineering, OneLake
storage, orchestration, semantic modeling and Power BI can operate within an
integrated analytics platform.

That reduces some of the integration overhead involved in assembling
completely separate services.

However, I would still select the architecture based on enterprise
requirements rather than choosing Fabric simply because everything is
available in one product."

---

# 17. Interview Question:

## How do you prevent duplicate processing?

Answer:

"For production I would design the transformations to be idempotent.

That means rerunning a processing window should produce the same intended
state rather than creating duplicate business records.

Depending on the use case I could implement this through Delta MERGE
operations, business keys, ingestion batch identifiers, watermarks or
deduplication rules."

---

# 18. Interview Question:

## How would you implement incremental loading?

Answer:

"I would avoid scanning and reprocessing the complete dataset on every run.

Depending on the source, I could use CDC, a source modification timestamp or
a watermark.

The pipeline would identify the last successfully processed point, retrieve
only the new or changed records, land those changes in Bronze and then
incrementally propagate them through Silver and Gold."

---

# 19. Interview Question:

## How do you monitor this architecture?

Answer:

"I think about monitoring at multiple levels.

At the pipeline level I monitor execution status, activity duration and
failures.

At the Spark level I monitor execution behavior, job duration, resource
utilization, shuffles and failures.

At the data level I monitor record counts, quality-rule results and data
freshness.

At the business layer I can monitor whether expected analytical data is
available and current.

For production I would centralize these operational metrics rather than
requiring engineers to inspect individual jobs manually."

---

# 20. Interview Question:

## What was a real problem you encountered?

Answer:

"One issue I encountered during implementation was Fabric Spark capacity
contention.

The orchestration successfully completed ingestion and Bronze-to-Silver, but
a downstream notebook couldn't create a Livy session because the available
Spark capacity limit had been reached.

The important lesson was that application logic can be completely valid while
the workload still fails because of platform capacity.

I used Fabric monitoring to distinguish an infrastructure-capacity failure
from a transformation-code failure.

That reinforced the importance of capacity monitoring, workload concurrency
management and retry strategy in production."

This is a strong answer because it describes something that actually happened
while building the project.

---

# 21. Interview Question:

## What did YOU architect?

Answer:

"I designed the separation between ingestion, transformation, quality
validation, business modeling and semantic consumption.

I implemented the Bronze-Silver-Gold processing flow, created the notebook
transformation stages, built the master orchestration pipeline, established
the quality gate, created the Gold dimensional structures and connected the
Gold model to the semantic and reporting layers.

I also structured the implementation artifacts so the architecture, notebooks,
pipelines, semantic model and Power BI report can be reviewed together."

Avoid saying:

"I was instrumental architected..."

Use:

"I designed..."
"I architected..."
"I implemented..."
"I made the decision to..."
"The reason I chose that approach was..."

---

# 22. The Story to Remember

If you forget everything else during an interview, remember this sequence:

SOURCE

"What data am I receiving?"

↓

BRONZE

"How do I preserve it?"

↓

SILVER

"How do I make it clean and reusable?"

↓

QUALITY GATE

"How do I know I can trust it?"

↓

GOLD

"How does the business want to analyze it?"

↓

SEMANTIC MODEL

"How do I define business metrics consistently?"

↓

POWER BI

"How does the user consume it?"

↓

ORCHESTRATION + MONITORING

"How do I operate the whole platform reliably?"

---

# 23. Final Interview Summary

My architecture separates six major responsibilities:

1. Ingestion
2. Storage
3. Transformation
4. Data Quality
5. Business/Semantic Modeling
6. Consumption

Fabric Pipeline provides orchestration.

OneLake/Lakehouse provides the data foundation.

PySpark provides scalable transformation.

The quality stage protects trusted analytical data.

Gold provides dimensional business structures.

The semantic model provides consistent KPIs.

Power BI provides analytical consumption.

That separation is what makes the architecture maintainable, scalable and
operationally understandable.
