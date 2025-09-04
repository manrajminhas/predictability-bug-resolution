# Changelog

All notable changes to this project will be documented in this file.  
This project follows a simple date-based changelog format.

---

## [July 10, 2025] – Project Setup
- Repository created with base structure. *(Eduardo)*
- Initial **README** drafted to outline goals and scope. *(Eduardo, Julia)*
- Installed required R libraries (`tidyverse`, `jsonlite`, `xgboost`, `lightgbm`, `SHAP`). *(All)*
- Basic project skeleton set up for data collection and cleaning scripts. *(Eduardo, with review by Manraj)*

---

## [July 12–20, 2025] – Data Collection, Cleaning & Background
- Queried **Apache JIRA REST API** for bug reports from:
  - **Cassandra** (10,009 raw records)
  - **Flink** (12,119 raw records)
  - **Kafka** (6,356 raw records)
  - **Spark** (16,479 raw records)  
  *(Eduardo)*
- Saved datasets as both **raw JSON** and **cleaned RDS**:
  - `CASSANDRA_raw.json`, `CASSANDRA_cleaned.rds`  
  - `FLINK_raw.json`, `FLINK_cleaned.rds`  
  - `KAFKA_raw.json`, `KAFKA_cleaned.rds`  
  - `SPARK_raw.json`, `SPARK_cleaned.rds`  
  *(Eduardo, Julia)*
- Applied cleaning & feature engineering: dropped incomplete rows, engineered predictors (`resolution_time`, `watch_count`, `num_comments`, `reporter_experience`, etc.). *(Eduardo, with review by Julia)*
- Drafted **Background & Related Work** section and collected references. *(Manraj)*
- Wrote **Data Sources, Data Description, Feature Overview**. *(Eduardo)*

---

## [July 31, 2025] – Interim Report Draft (Sections 1–4.5.6)
- Completed **Introduction & Motivation**. *(Eduardo)*
- Drafted **Research Questions** collaboratively. *(All)*
- Drafted **Data Section** with cleaning steps and engineered features. *(Eduardo, with Julia reviewing)*
- **Exploratory Data Analysis (EDA):**
  - Distribution of `resolution_time`, log transformation. *(Julia)*
  - Correlation analysis for numerical features. *(Julia)*
  - Boxplots for categorical features (priority, weekday, month). *(Julia)*
  - Outlier/tail-risk analysis (bugs >30, >90, >365 days). *(Julia, with support from Manraj)*
  - Feature selection overview. *(Manraj)*
- Identified strongest predictors: `watch_count` (ρ≈0.42), `num_comments` (ρ≈0.29). *(Julia)*

---

## [August 1–5, 2025] – Methodology & Modeling Setup
- Designed **Experimental Design & Data Splitting** strategies for RQ1–RQ3. *(Manraj, with Eduardo reviewing)*
- Drafted **Evaluation Metrics** (MAE, RMSE, R²). *(Manraj)*
- Drafted **Model Selection & Approach** (XGBoost, LightGBM). *(Manraj)*
- Drafted **Data Preprocessing for Modeling** (feature transformations, encodings). *(Manraj, Julia assisting)*
- Finalized **experimental framework and pipeline**. *(Eduardo)*

---

## [August 10–14, 2025] – Interim Findings
- Ran first experiments on Cassandra, Flink, and Kafka datasets. *(Eduardo)*
- Results:
  - XGBoost outperformed baseline but only modestly (MAE ≈19 days vs. median 8 days).  
  - Cross-project weakest; hybrid transfer strongest.  
  - Feature consistency: `watch_count` and `days_since_project_start` strongest.  
- Drafted early **Findings** section. *(Eduardo, with Julia editing)*

---

## [August 17–19, 2025] – Final Report Expansion & Presentation Prep
- Decided to **drop Spark dataset** due to inconsistencies; focused on Cassandra, Flink, and Kafka only. *(All)*
- Expanded **Data** section with updated record counts and Spark justification. *(Eduardo, reviewed by Julia)*
- Rewrote and expanded **EDA** with structured findings and visualizations:
  - Univariate, categorical, logical, multivariate predictors. *(Julia)*  
  - Feature selection refinements. *(Manraj)*
- Completed **Findings** section (RQ1–RQ4 results, tables, feature importance charts). *(Eduardo)*
- Wrote **Discussion** section. *(Manraj, Julia editing)*
- Wrote **Conclusion** section. *(Manraj)*
- Drafted **Limitations** (limited features, skew, model bias). *(Manraj, reviewed by Eduardo)*
- Created **8-slide presentation deck** with visuals and scripts:  
  1. Problem & Motivation  
  2. Research Questions  
  3. Data Collection & Preprocessing  
  4. Exploratory Data Analysis  
  5. Modeling  
  6. Findings  
  7. What We Learned  
  8. How AI Helped/Didn’t Help  
  *(Eduardo & Manraj, Julia reviewing)*

---

## [August 18, 2025] – EDA Expansion & Modeling Refinement
- Expanded **EDA scripts** with advanced visualizations:
  - Log-transformed distributions, Spearman heatmaps, faceted scatterplots. *(Julia, with Manraj assisting)*
  - Boxplots for categorical features (priority, weekday, month). *(Julia)*  
  - Logical predictor plots (code block, inline attachment). *(Julia)*  
- Added plots to `/images` folder:  
  - `correlation_matrix_numerical_predictors.png`  
  - `distribution_of_bug_resolution_time.png`  
  - `distribution_of_log_bug_resolution_time.png`  
  - `most_important_features_by_project.png`  
  - `numerical_predictor_and_resolution_time_scatter_plots.png`  
  - `resolution_time_by_code_presence.png`  
  - `resolution_time_by_day_of_week.png`  
  - `resolution_time_by_inline_attachment_presence.png`  
  - `resolution_time_by_month.png`  
  - `resolution_time_by_priority.png`  
  *(All contributed to visualization selection)*
- Updated **modeling script**:
  - Refined preprocessing (binary conversion, one-hot encoding). *(Manraj, Eduardo)*  
  - Tuned XGBoost parameters (`eta=0.05`, `max_depth=4`, `subsample=0.8`, `colsample_bytree=0.8`). *(Eduardo, Julia verifying)*  
  - Increased training rounds (`nrounds=250`) for stability. *(Eduardo)*  
  - Aggregated feature importance across projects. *(Eduardo, Julia)*

---

## [August 20–23, 2025] – Final Polishing & ACM Formatting
- Reviewed full report against course submission guidelines. *(All)*
- Reformatted report into **ACM proceedings format (8–12 pages)**:
  - Adjusted structure: Intro, Motivation, Related Work, Methodology, Results, Discussion, Limitations, Conclusion/Future Work. *(All, with major edits by Manraj)*  
  - Reformatted **references** into ACM style. *(All)*  
- Added **Appendix A** (supplementary materials/replication). *(Eduardo)*  
- Added **Appendix B** (team contributions). *(All)*
- Conducted peer review and editing for clarity. *(All, Julia polished EDA visuals, Manraj focused on discussion/limitations, Eduardo on findings consistency)*  
- Final submission-ready PDF prepared. *(All)*

---

## Summary of Major Changes
- **July 10–20:** Repo setup (Eduardo), raw + cleaned datasets prepared (Eduardo, Julia), Background & Related Work drafted (Manraj).  
- **July 31:** Interim skeleton completed (Eduardo: Intro/Data; Julia: EDA; Manraj: feature selection).  
- **Aug 1–5:** Methodology drafted (Manraj main, Julia supporting, Eduardo pipeline integration).  
- **Aug 10–14:** Interim findings generated (Eduardo main, Julia editing).  
- **Aug 17–19:** Spark dropped (All). Final report expanded (Eduardo: Findings, Julia: EDA visuals, Manraj: Discussion/Conclusion/Limitations). Presentation prepared (Eduardo & Manraj, Julia reviewing).  
- **Aug 18:** EDA expansion & modeling refinements (Julia main, Eduardo + Manraj supporting).  
- **Aug 20–23:** Report polished into ACM format; appendices, references, peer review done (All, balanced contributions).  
