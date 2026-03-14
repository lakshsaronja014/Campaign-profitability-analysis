# 📊 E-Commerce Campaign Profitability Analysis

### SQL + Power BI Root Cause Investigation

---

# 🧠 Project Summary

This project analyzes why a promotional campaign in an e-commerce company generated **high sales but resulted in a significant loss in profitability**.

Using **SQL (SSMS) for data modeling and analysis** and **Power BI for visualization**, the project identifies operational and financial factors that caused margin erosion during the campaign.

The goal is to demonstrate how **data analytics can uncover hidden business problems and support strategic decision-making.**

---

# 🎯 Business Problem

During a large promotional campaign, the company experienced:

* Rapid increase in order volume
* Heavy promotional discounts
* Increased warehouse pressure

Despite strong revenue growth, the campaign produced a **₹3.6 Cr loss**, compared to normal monthly profits of **₹1–2 Cr**.

### Key Question

**Why did revenue increase but profitability decline during the campaign?**

---

# 🧩 Analytical Workflow

The project follows a structured analytics pipeline:

```
Raw Transaction Data
        ↓
Data Cleaning (SQL)
        ↓
Fact Table Modeling
        ↓
KPI Aggregation
        ↓
Root Cause Investigation
        ↓
Power BI Dashboard
        ↓
Business Recommendations
```

---

# 📂 Repository Structure

```
ecommerce-campaign-profitability-analysis
│
├── data
│   └── ecommerce_campaign_db.bak
│
├── sql
│   ├── data_cleaning.sql
│   ├── fact_model.sql
│   ├── kpi_queries.sql
│   └── root_cause_analysis.sql
│
├── powerbi
│   ├── campaign_analysis_dashboard.pbix
│   └── dashboard_images
│
└── README.md
```

---

# ⚙️ Tools & Technologies

| Tool                                | Purpose                             |
| ----------------------------------- | ----------------------------------- |
| SQL Server Management Studio (SSMS) | Data cleaning, modeling, analysis   |
| T-SQL                               | Analytical queries                  |
| Power BI                            | Interactive dashboard visualization |
| GitHub                              | Project documentation               |

---

# 📊 Power BI Dashboard

The Power BI dashboard presents campaign performance through multiple analytical views.

---

## Executive Overview

Key metrics tracked:

* Net Sales
* Contribution Profit
* Contribution Margin
* Refund Rate
* Late Delivery Percentage

[![Executive Dashboard](https://github.com/lakshsaronja014/Campaign-profitability-analysis/blob/db7f8c573cf447ad1b521c122d2c136372afbd34/Executive%20Dashboard.png)

---

## Campaign Impact Analysis

This section analyzes how promotional discounts affected business performance.

Key insights include:

* Relationship between discount levels and refunds
* Category-level return behavior
* Profitability comparison between campaign and normal months

![Campaign Impact](https://github.com/lakshsaronja014/Campaign-profitability-analysis/blob/db7f8c573cf447ad1b521c122d2c136372afbd34/Campaign%20Impact.png)

---

## Operations & Delivery Analysis

Operational performance was evaluated to understand fulfillment challenges during the campaign.

Metrics analyzed:

* Late delivery trends
* Warehouse congestion
* Operational bottlenecks during demand spikes

![Operations Dashboard](https://github.com/lakshsaronja014/Campaign-profitability-analysis/blob/db7f8c573cf447ad1b521c122d2c136372afbd34/Operations%20Impact.png)

---

# 🔍 Key Findings

### 1️⃣ Aggressive Discounting

Heavy discounts above **30%** significantly reduced profit margins.

### 2️⃣ Increased Refund Behavior

Certain product categories experienced return rates as high as **37%**.

### 3️⃣ Operational Bottlenecks

Warehouse congestion increased late deliveries and operational costs.

---

# 📉 Business Impact

```
High Discounts
+
High Refunds
+
Operational Inefficiencies
=
₹3.6 Cr Campaign Loss
```

---

# 🚀 Strategic Recommendations

### Discount Optimization

Limit campaign discounts to **20–25%** to maintain healthy margins.

### Category-Specific Promotions

Avoid deep discounts on historically high-return product categories.

### Warehouse Load Balancing

Distribute campaign inventory across multiple fulfillment centers.

![Executive Recommendations](https://github.com/lakshsaronja014/Campaign-profitability-analysis/blob/db7f8c573cf447ad1b521c122d2c136372afbd34/Recommendations.png)

---

# 📦 Dataset

The repository includes a **SQL Server database backup (.bak)** containing the dataset used for this analysis.

To reproduce the analysis:

1. Restore the database in **SQL Server Management Studio**
2. Run the SQL scripts inside the `sql` folder
3. Open the Power BI `.pbix` file to explore the dashboard

---

# 💡 Skills Demonstrated

* Data Cleaning & Transformation (SQL)
* Analytical Data Modeling
* KPI Development
* Root Cause Analysis
* Data Visualization
* Business Problem Solving
* Data Storytelling

---

# 📌 Project Insight

This project demonstrates how **data analytics can uncover operational and pricing inefficiencies behind campaign performance and transform raw transactional data into actionable business insights.**
