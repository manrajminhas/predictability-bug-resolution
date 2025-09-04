# Predicting Bug Resolution Using Machine Learning

This repository contains the data, analysis scripts, and final report for a project investigating the predictability of bug resolution time in large-scale open-source software projects.

Large raw files (300–400 MB) are **not stored directly in this repository** due to GitHub’s size limits.  
Instead, they are included as downloadable **Release assets**.  

👉 You can find them under the [Releases page](../../releases).

---

## Project Team

* **Eduardo Bassani:** [@eduardobassanii](https://github.com/eduardobassanii)
* **Manraj Minhas:** [@manrajminhas](https://github.com/manrajminhas)
* **Julia Ishibashi:** [@juliaishibashi](https://github.com/juliaishibashi)

---

## Topic and Motivation

Accurately estimating how long a software bug will take to resolve is a critical challenge in software development, essential for project planning, resource allocation, and managing stakeholder expectations. This project explores the feasibility of using machine learning to predict this metric.

Our research is guided by four main questions:

1. **Within-Project:** How accurately can a project predict its own future bug fix times?
2. **Cross-Project:** Can a model trained on other projects predict fix times for a new, unseen project?
3. **Hybrid Transfer:** Does augmenting a project's local data with data from other projects improve its own predictions?
4. **Feature Consistency:** Which features are the most important predictors, and are they consistent across projects?

By analyzing data from three major Apache projects (Cassandra, Flink, and Kafka), we aim to provide a comprehensive picture of how to best predict bug resolution times.

---

## Reproducing the Results

### Requirements
- **R:** The analysis is written in the R programming language.
- **RStudio:** The scripts rely on RStudio for setting the file paths correctly via the `rstudioapi` package. Please run all scripts from within the RStudio IDE.

### Step-by-Step Instructions

The analysis is broken down into four main R scripts located in the `src/` directory. They should be run in the following order.

**1. Fetching the Raw Data (`fetch_asf_jira_issues.R`)**
This script connects to the public Apache JIRA API to download the raw bug report data.

- **Action:** You must run this script **three times**, once for each project. Before each run, you need to open the script and change the `projectKey` variable at the top to one of the following: `"CASSANDRA"`, `"FLINK"`, `"KAFKA"`.
- **Artifacts:** This will produce three files in the `data/` directory: `CASSANDRA_raw.json`, `FLINK_raw.json`, and `KAFKA_raw.json`.

**2. Cleaning and Preparing the Data (`data_cleaning_and_preparation.R`)**
This script loads the raw JSON files, cleans the data, and engineers the features used for the analysis.

- **Action:** You must also run this script **three times**. Before each run, open the script and change the `projectKey` variable to match the project you are processing.
- **Artifacts:** This will produce three cleaned data files in the `data/` directory: `CASSANDRA_cleaned.rds`, `FLINK_cleaned.rds`, and `KAFKA_cleaned.rds`.

**3. Exploratory Data Analysis (`exploratory_data_analysis.R`)**
This script loads the three cleaned `.rds` files and generates all the plots and correlation tables used in the EDA section of the report.

- **Action:** Run this script once.
- **Artifacts:** This script will output all EDA plots to the RStudio "Plots" pane and print correlation tables to the console.

**4. Modeling and Evaluation (`modeling.R`)**
This script runs the full modeling pipeline, including outlier removal, preprocessing, and the experiments for all four research questions.

- **Action:** Run this script once.
- **Artifacts:** The script will print the final performance tables (MAE and RMSE) for RQ1, RQ2, and RQ3 to the console. It will also generate and display the final feature importance plot for RQ4 in the "Plots" pane.

---

## Related Work

The challenge of predicting bug fix times is well-studied in software engineering. Early research demonstrated that structured metadata like component and priority are strong predictors [[1]](https://www.researchgate.net/publication/261199445_An_Empirical_Study_on_Factors_Impacting_Bug_Fixing_Time). Subsequent work has expanded on this by incorporating static code metrics [[2]](https://arxiv.org/abs/2407.21241) and bug report details like the reporter and type, finding that these factors account for significant differences in resolution time [[3]](https://arxiv.org/abs/2312.06005).

The availability of large, curated datasets like BugsRepo [[4]](https://arxiv.org/abs/2504.18806) and GitBugs [[5]](https://arxiv.org/abs/2504.09651) has been crucial for these modeling efforts.

More recent studies have shown that the unstructured text within bug reports is also a powerful signal. Techniques like topic modeling [[6]](https://arxiv.org/abs/2505.01108) and using LLMs to decompose bug reports into sub-issues [[7]](https://arxiv.org/abs/2504.20911) have surfaced features that correlate closely with fix latency. Other research has explored different parts of the bug lifecycle, showing that a bug's priority changing over time [[8]](https://arxiv.org/abs/2403.05059) and the programming language ecosystem [[9]](https://arxiv.org/abs/1801.01025) also have significant impacts on resolution time.
