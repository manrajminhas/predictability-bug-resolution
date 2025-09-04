if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")
if (!requireNamespace("patchwork", quietly = TRUE)) install.packages("patchwork")
if (!requireNamespace("ggcorrplot", quietly = TRUE)) install.packages("ggcorrplot")
if (!requireNamespace("rstudioapi", quietly = TRUE)) install.packages("rstudioapi")

library(tidyverse)
library(patchwork)
library(ggcorrplot)
library(rstudioapi)

# --- Load the cleaned datasets ---

# Set Working Directory
current_dir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(file.path(current_dir, "..", "data"))

cassandra <- readRDS("CASSANDRA_cleaned.rds")
flink <- readRDS("FLINK_cleaned.rds")
kafka <- readRDS("KAFKA_cleaned.rds")

# --- Create a combined dataframe ---

# To keep track of which bug came from which project, we first add a 'project' column
# to each individual dataframe before combining them.
cassandra$project <- "Cassandra"
flink$project <- "Flink"
kafka$project <- "Kafka"

# Apply the log1p() transformation to each individual dataframe.
cassandra <- cassandra %>% mutate(log_resolution_time = log1p(resolution_time))
flink <- flink %>% mutate(log_resolution_time = log1p(resolution_time))
kafka <- kafka %>% mutate(log_resolution_time = log1p(resolution_time))

# Combine the rows of all dataframes into a single one
combined <- bind_rows(cassandra, flink, kafka)

# --- 5.1. Univariate Analysis: Target Variable ---

# Get summary statistics for the resolution_time
cat("Summary statistics for resolution_time (in days):\n")
print(summary(combined$resolution_time))

# Get summary statistics for the LOG-TRANSFORMED resolution_time
cat("\nSummary statistics for log_resolution_time (in days):\n")
print(summary(combined$log_resolution_time))

# Create an initial visualization
resolution_time_hist <- ggplot(combined, aes(x = resolution_time)) +
  geom_histogram(bins = 50, fill = "#000000ff", color = "white", alpha = 0.8) +
  labs(
    title = "Distribution of Bug Resolution Time (All Projects)",
    x = "Resolution Time (Days)",
    y = "Frequency (Number of Bugs)"
  ) +
  theme_minimal(base_size = 14)

# Display the plot
print(resolution_time_hist)

# Visualize the transformed distribution for the COMBINED dataset
log_hist_combined <- ggplot(combined, aes(x = log_resolution_time)) +
  geom_histogram(bins = 50, fill = "#000000ff", color = "white", alpha = 0.8) +
  labs(
    title = "Log-Transformed Distribution of Bug Resolution Time (All Projects)",
    x = "log(Resolution Time + 1)",
    y = "Frequency (Number of Bugs)"
  ) +
  theme_minimal(base_size = 14)

# Display the combined log plot
print(log_hist_combined)

# --- 5.2. Bivariate Analysis: Predictors vs. Resolution Time ---

# --- 5.2.2. Numerical Predictors vs. Resolution Time ---

# Define the numerical predictor columns
numerical_predictors <- c(
  "watch_count", "vote_count", "num_comments", "num_attachments",
  "description_length", "days_since_project_start",
  "bugs_last_7d", "bugs_last_30d", "reporter_experience"
)

# Reshape the data from wide to long format
# This makes it easy to create faceted plots with ggplot.
combined_long <- combined %>%
  select(all_of(numerical_predictors), log_resolution_time) %>%
  pivot_longer(
    cols = all_of(numerical_predictors),
    names_to = "predictor_variable",
    values_to = "predictor_value"
  )

# Create the faceted scatter plot
numerical_scatter_plots <- ggplot(combined_long, aes(x = predictor_value, y = log_resolution_time)) +
  geom_point(alpha = 0.1, color = "#000000ff") +
  facet_wrap(~ predictor_variable, scales = "free_x", ncol = 3) +
  labs(
    title = "Relationship Between Numerical Predictors and Resolution Time",
    x = "Predictor Value",
    y = "Log-Transformed Resolution Time"
  ) +
  theme_minimal(base_size = 12) +
  theme(strip.text = element_text(face = "bold")) # Make facet titles bold

# Display the grid of scatter plots
print(numerical_scatter_plots)

# Calculate Spearman's Correlation Coefficients

# Select only the relevant columns
correlation_data <- combined %>%
  select(log_resolution_time, all_of(numerical_predictors))

# Calculate the full correlation matrix
correlation_matrix <- cor(correlation_data, method = "spearman", use = "complete.obs")

# Extract and format the correlations with the target variable
correlation_with_target <- as.data.frame(correlation_matrix["log_resolution_time", ])
# Rename the column for clarity
colnames(correlation_with_target) <- "spearman_correlation"
# Remove the self-correlation (target with itself)
correlation_with_target <- correlation_with_target %>%
  filter(row.names(.) != "log_resolution_time") %>%
  arrange(desc(abs(spearman_correlation))) # Sort by the absolute strength

# Print the results
cat("\n--- Spearman's Correlation with log_resolution_time ---\n")
print(correlation_with_target)

# --- 5.2.2. Categorical Predictors vs. Resolution Time ---

# Plot 1: Resolution Time by Priority for Each Project
priority_plot <- ggplot(combined, aes(x = priority, y = log_resolution_time, fill = project)) +
  geom_boxplot(show.legend = FALSE) +
  facet_wrap(~ project, scales = "free_x") + 
  scale_fill_manual(values = c("Cassandra" = "#d93955", 
                               "Flink" = "#d9bd39", 
                               "Kafka" = "#d96d39")) +
  labs(
    title = "Resolution Time by Bug Priority",
    x = "Priority Level",
    y = "Log-Transformed Resolution Time"
  ) +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Display the priority plot
print(priority_plot)

# Plot 2: Resolution Time by Day of the Week
day_of_week_plot <- ggplot(combined, aes(x = created_wday, y = log_resolution_time)) +
  geom_boxplot(fill = "#dadadaff") +
  labs(
    title = "Resolution Time by Day of Week",
    x = "Day Bug Was Created",
    y = "Log-Transformed Resolution Time"
  ) +
  theme_minimal(base_size = 12)

# Display the day of week plot
print(day_of_week_plot)

# Plot 3: Resolution Time by Month
month_plot <- ggplot(combined, aes(x = created_month, y = log_resolution_time)) +
  geom_boxplot(fill = "#dadadaff") +
  labs(
    title = "Resolution Time by Month",
    x = "Month Bug Was Created",
    y = "Log-Transformed Resolution Time"
  ) +
  theme_minimal(base_size = 12)

# Display the month plot
print(month_plot)

# --- 5.2.3. Logical Predictors vs. Resolution Time ---

# Plot 1: Resolution Time by Presence of Code Block
code_plot <- ggplot(combined, aes(x = has_code_block, y = log_resolution_time)) +
  geom_boxplot(fill = "#dadadaff") +
  labs(
    title = "Resolution Time by Presence of Code Block",
    x = "Has Code Block",
    y = "Log-Transformed Resolution Time"
  ) +
  theme_minimal(base_size = 12)

# Display the code plot
print(code_plot)

# Plot 2: Resolution Time by Presence of Inline Attachment
attach_plot <- ggplot(combined, aes(x = has_inline_attachment, y = log_resolution_time)) +
  geom_boxplot(fill = "#dadadaff") +
  labs(
    title = "Resolution Time by Presence of Inline Attachment",
    x = "Has Inline Attachment",
    y = "Log-Transformed Resolution Time"
  ) +
  theme_minimal(base_size = 12)

# Display the attachment plot
print(attach_plot)

# --- 5.3. Multivariate Analysis: Interactions Between Predictors ---

# Define the numerical predictor columns (same as before)
numerical_predictors <- c(
  "watch_count", "vote_count", "num_comments", "num_attachments",
  "description_length", "days_since_project_start",
  "bugs_last_7d", "bugs_last_30d", "reporter_experience"
)

# Select only the numerical predictor columns
correlation_data_predictors <- combined %>%
  select(all_of(numerical_predictors))

# Calculate the Spearman correlation matrix
predictor_corr_matrix <- cor(correlation_data_predictors, method = "spearman", use = "complete.obs")

# Create the correlation heatmap
correlation_heatmap <- ggcorrplot(
  predictor_corr_matrix,
  method = "circle",
  type = "lower",
  lab = TRUE,
  lab_size = 3,
  colors = c("#E41A1C", "white", "#377EB8"),
  title = "Correlation Matrix of Numerical Predictors"
) +
theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Display the heatmap
print(correlation_heatmap)
