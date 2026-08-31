
/* ============================================================
   Microsoft Fabric Insurance Medallion Platform
   Gold Layer - SQL Analytics Endpoint

   Lakehouse: LH_Gold
   Purpose:
     - Validate Gold tables
     - Demonstrate dimensional joins
     - Create reusable claims analytics view
     - Provide business analytical queries
   ============================================================ */


/* ============================================================
   1. VALIDATE GOLD TABLES
   ============================================================ */

SELECT TOP 10 *
FROM dbo.dim_customer;

SELECT TOP 10 *
FROM dbo.dim_policy;

SELECT TOP 10 *
FROM dbo.fact_claim;

SELECT TOP 10 *
FROM dbo.fact_payment;


/* ============================================================
   2. CUSTOMER + POLICY + CLAIM ANALYTICAL JOIN
   ============================================================ */

SELECT TOP 20
    c.customer_id,
    c.first_name,
    c.last_name,
    c.state,

    p.policy_id,
    p.product_type,
    p.policy_status,
    p.annual_premium,

    cl.claim_id,
    cl.claim_date,
    cl.claim_type,
    cl.claim_status,
    cl.claim_amount,
    cl.approved_amount,
    cl.approval_percentage

FROM dbo.fact_claim AS cl

INNER JOIN dbo.dim_policy AS p
    ON cl.policy_key = p.policy_key

INNER JOIN dbo.dim_customer AS c
    ON cl.customer_key = c.customer_key

ORDER BY
    cl.claim_amount DESC;


/* ============================================================
   3. CLAIM ANALYTICS BY PRODUCT TYPE
   ============================================================ */

SELECT
    p.product_type,

    COUNT(*) AS claim_count,

    SUM(cl.claim_amount)
        AS total_claim_amount,

    SUM(cl.approved_amount)
        AS total_approved_amount,

    AVG(cl.claim_amount)
        AS average_claim_amount,

    AVG(cl.approval_percentage)
        AS average_approval_percentage

FROM dbo.fact_claim AS cl

INNER JOIN dbo.dim_policy AS p
    ON cl.policy_key = p.policy_key

GROUP BY
    p.product_type

ORDER BY
    total_claim_amount DESC;


/* ============================================================
   4. CLAIM ANALYTICS BY STATE
   ============================================================ */

SELECT
    c.state,

    COUNT(DISTINCT c.customer_id)
        AS customer_count,

    COUNT(DISTINCT p.policy_id)
        AS policy_count,

    COUNT(cl.claim_id)
        AS claim_count,

    SUM(cl.claim_amount)
        AS total_claim_amount,

    SUM(cl.approved_amount)
        AS total_approved_amount

FROM dbo.fact_claim AS cl

INNER JOIN dbo.dim_customer AS c
    ON cl.customer_key = c.customer_key

INNER JOIN dbo.dim_policy AS p
    ON cl.policy_key = p.policy_key

GROUP BY
    c.state

ORDER BY
    total_claim_amount DESC;


/* ============================================================
   5. CLAIM ANALYTICS BY YEAR
   ============================================================ */

SELECT
    cl.claim_year,

    COUNT(*) AS claim_count,

    SUM(cl.claim_amount)
        AS total_claim_amount,

    SUM(cl.approved_amount)
        AS total_approved_amount,

    AVG(cl.claim_amount)
        AS average_claim_amount

FROM dbo.fact_claim AS cl

GROUP BY
    cl.claim_year

ORDER BY
    cl.claim_year;


/* ============================================================
   6. CREATE BUSINESS-FRIENDLY ANALYTICS VIEW
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_claims_analytics
AS

SELECT
    /* Customer */
    c.customer_key,
    c.customer_id,
    c.first_name,
    c.last_name,
    c.state,

    /* Policy */
    p.policy_key,
    p.policy_id,
    p.product_type,
    p.policy_status,
    p.annual_premium,
    p.coverage_limit,
    p.deductible,

    /* Claim */
    cl.claim_key,
    cl.claim_id,
    cl.claim_date,
    cl.incident_date,
    cl.claim_year,
    cl.claim_type,
    cl.claim_status,
    cl.claim_amount,
    cl.approved_amount,
    cl.approval_percentage

FROM dbo.fact_claim AS cl

INNER JOIN dbo.dim_customer AS c
    ON cl.customer_key = c.customer_key

INNER JOIN dbo.dim_policy AS p
    ON cl.policy_key = p.policy_key;


/* ============================================================
   7. VALIDATE BUSINESS VIEW
   ============================================================ */

SELECT TOP 20 *
FROM dbo.vw_claims_analytics
ORDER BY claim_amount DESC;


/* ============================================================
   8. PRODUCT + CLAIM TYPE ANALYTICS
   ============================================================ */

SELECT
    product_type,
    claim_type,

    COUNT(*) AS claim_count,

    SUM(claim_amount)
        AS total_claim_amount,

    SUM(approved_amount)
        AS total_approved_amount,

    AVG(claim_amount)
        AS average_claim_amount

FROM dbo.vw_claims_analytics

GROUP BY
    product_type,
    claim_type

ORDER BY
    total_claim_amount DESC;