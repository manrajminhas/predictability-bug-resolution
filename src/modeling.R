# --- 1. SETUP ---
# Load or Install Necessary Libraries
if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
if (!requireNamespace("xgboost", quietly = TRUE)) install.packages("xgboost")
if (!requireNamespace("fastDummies", quietly = TRUE)) install.packages("fastDummies")
if (!requireNamespace("Metrics", quietly = TRUE)) install.packages("Metrics")
if (!requireNamespace("tidytext", quietly = TRUE)) install.packages("tidytext")

library(tidyverse)
library(here)
library(xgboost)
library(fastDummies)
library(Metrics)
library(tidytext)

# --- Set Working Directory and Load Data ---
# This finds the directory of the current script and sets the working directory
# to the parent folder (the project root). This requires running from RStudio.
script_dir <- dirname(getActiveDocumentContext()$path)
setwd(file.path(script_dir, ".."))

# Load data using paths relative to the project root
project_names <- c("Cassandra", "Flink", "Kafka")
project_data <- map(project_names, ~ readRDS(file.path("data", paste0(., "_cleaned.rds")))) %>%
  set_names(project_names)

# --- Create the log_resolution_time column BEFORE preprocessing ---
project_data <- map(project_data, ~ .x %>% mutate(log_resolution_time = log1p(resolution_time)))

# --- Outlier Removal Step (IQR METHOD) ---
cat("--- Removing Extreme Outliers (IQR Method) ---\n")

for (proj_name in project_names) {
  df <- project_data[[proj_name]]
  initial_rows <- nrow(df)
  
  # Calculate Q1, Q3, and the Interquartile Range (IQR)
  Q1 <- quantile(df$resolution_time, 0.25)
  Q3 <- quantile(df$resolution_time, 0.75)
  IQR <- Q3 - Q1
  
  # Define the upper bound for outlier detection (Q3 + 1.5 * IQR)
  upper_bound <- Q3 + 1.5 * IQR
  
  # Filter the dataframe to keep only rows within the upper bound
  df_filtered <- df %>% filter(resolution_time <= upper_bound)
  
  final_rows <- nrow(df_filtered)
  project_data[[proj_name]] <- df_filtered
  
  cat(paste0("  ", proj_name, ": Removed ", initial_rows - final_rows, " outliers. (Threshold: ", round(upper_bound, 1), " days)\n"))
}


# --- 2. PREPROCESSING FUNCTION ---
# This function prepares the data for modeling according to our plan
preprocess_data <- function(df) {
  # 1. Select the final features
  final_features <- c(
    "resolution_time", "log_resolution_time", # Keep targets for splitting/evaluation
    "watch_count", "num_comments", "vote_count", "description_length",
    "reporter_experience", "bugs_last_7d", "days_since_project_start",
    "has_code_block", "created_wday"
  )
  df_processed <- df %>% select(all_of(final_features))

  # 2. Convert logical to binary (0/1)
  df_processed <- df_processed %>%
    mutate(has_code_block = as.integer(has_code_block))

  # 3. One-hot encode created_wday
  df_processed <- dummy_cols(
    df_processed,
    select_columns = "created_wday",
    remove_selected_columns = TRUE,
    ignore_na = TRUE
  )
  return(df_processed)
}


# --- 3. RQ1: WITHIN-PROJECT PREDICTION ---
cat("\n--- Running Experiment for RQ1: Within-Project Prediction ---\n")
rq1_results <- list()
rq4_feature_importance <- list()
for (proj_name in project_names) {
  cat(paste("Processing project:", proj_name, "\n"))
  
  # A. DATA SPLITTING (Chronological)
  project_df <- project_data[[proj_name]] %>% arrange(days_since_project_start)
  split_point <- floor(0.8 * nrow(project_df))
  train_df <- project_df[1:split_point, ]
  test_df <- project_df[(split_point + 1):nrow(project_df), ]
  
  # B. PREPROCESSING
  train_processed <- preprocess_data(train_df)
  test_processed <- preprocess_data(test_df)
  train_cols <- colnames(train_processed)
  for(col in train_cols){ if(!col %in% colnames(test_processed)){ test_processed[[col]] <- 0 } }
  test_processed <- test_processed[, train_cols]
  
  # C. PREPARE DATA FOR XGBOOST
  train_features <- train_processed %>% select(-resolution_time, -log_resolution_time)
  train_target <- train_processed$log_resolution_time
  test_features <- test_processed %>% select(-resolution_time, -log_resolution_time)
  test_target_actual_days <- test_processed$resolution_time
  dtrain <- xgb.DMatrix(data = as.matrix(train_features), label = train_target)
  dtest <- xgb.DMatrix(data = as.matrix(test_features))
  
  # D. MODEL TRAINING
  median_baseline_pred_log <- median(train_target)
  xgb_params <- list(objective = "reg:squarederror", eval_metric = "rmse", eta = 0.05, max_depth = 4, subsample = 0.8, colsample_bytree = 0.8)
  xgb_model <- xgb.train(params = xgb_params, data = dtrain, nrounds = 250, verbose = 0)

  # --- EXTRACT FEATURE IMPORTANCE FOR RQ4 ---
  importance <- xgb.importance(model = xgb_model)
  rq4_feature_importance[[proj_name]] <- as_tibble(importance) %>% mutate(project = proj_name)
  
  # E. PREDICTION & INVERSE TRANSFORM
  baseline_preds_days <- rep(expm1(median_baseline_pred_log), nrow(test_df))
  xgb_preds_log <- predict(xgb_model, dtest)
  xgb_preds_days <- expm1(xgb_preds_log)
  
  # F. EVALUATION
  rq1_results[[proj_name]] <- tibble(
      project = proj_name, model = c("Median Baseline", "XGBoost"),
      MAE = c(mae(test_target_actual_days, baseline_preds_days), mae(test_target_actual_days, xgb_preds_days)),
      RMSE = c(rmse(test_target_actual_days, baseline_preds_days), rmse(test_target_actual_days, xgb_preds_days))
  )
}
# G. AGGREGATE AND DISPLAY RESULTS FOR RQ1
rq1_results_df <- bind_rows(rq1_results)
rq1_summary <- rq1_results_df %>% group_by(model) %>% summarise(Avg_MAE = mean(MAE), Avg_RMSE = mean(RMSE))
cat("\n--- RQ1: Within-Project Prediction - Results by Project ---\n"); print(rq1_results_df)
cat("\n--- RQ1: Within-Project Prediction - Performance Across Projects ---\n"); print(rq1_summary)

# --- 4. RQ2: CROSS-PROJECT GENERALIZATION ---
cat("\n\n--- Running Experiment for RQ2: Cross-Project Generalization ---\n")
rq2_results <- list()

for (test_proj_name in project_names) {
  cat(paste("Holding out project for testing:", test_proj_name, "\n"))
  
  # A. DATA SPLITTING (Leave-One-Project-Out)
  train_proj_names <- setdiff(project_names, test_proj_name)
  train_df <- bind_rows(project_data[train_proj_names])
  test_df <- project_data[[test_proj_name]]
  
  # B. PREPROCESSING
  train_processed <- preprocess_data(train_df)
  test_processed <- preprocess_data(test_df)
  train_cols <- colnames(train_processed)
  for(col in train_cols){ if(!col %in% colnames(test_processed)){ test_processed[[col]] <- 0 } }
  test_processed <- test_processed[, train_cols]
  
  # C. PREPARE DATA FOR XGBOOST
  train_features <- train_processed %>% select(-resolution_time, -log_resolution_time)
  train_target <- train_processed$log_resolution_time
  test_features <- test_processed %>% select(-resolution_time, -log_resolution_time)
  test_target_actual_days <- test_processed$resolution_time
  dtrain <- xgb.DMatrix(data = as.matrix(train_features), label = train_target)
  dtest <- xgb.DMatrix(data = as.matrix(test_features))
  
  # D. MODEL TRAINING
  median_baseline_pred_log <- median(train_target)
  xgb_params <- list(objective = "reg:squarederror", eval_metric = "rmse", eta = 0.05, max_depth = 4, subsample = 0.8, colsample_bytree = 0.8)
  xgb_model <- xgb.train(params = xgb_params, data = dtrain, nrounds = 250, verbose = 0)
  
  # E. PREDICTION & INVERSE TRANSFORM
  baseline_preds_days <- rep(expm1(median_baseline_pred_log), nrow(test_df))
  xgb_preds_log <- predict(xgb_model, dtest)
  xgb_preds_days <- expm1(xgb_preds_log)
  
  # F. EVALUATION
  rq2_results[[test_proj_name]] <- tibble(
      held_out_project = test_proj_name, model = c("Median Baseline", "XGBoost"),
      MAE = c(mae(test_target_actual_days, baseline_preds_days), mae(test_target_actual_days, xgb_preds_days)),
      RMSE = c(rmse(test_target_actual_days, baseline_preds_days), rmse(test_target_actual_days, xgb_preds_days))
  )
}

# G. AGGREGATE AND DISPLAY RESULTS FOR RQ2
rq2_results_df <- bind_rows(rq2_results)
rq2_summary <- rq2_results_df %>% group_by(model) %>% summarise(Avg_MAE = mean(MAE), Avg_RMSE = mean(RMSE))
cat("\n--- RQ2: Cross-Project Generalization - Results by Project ---\n"); print(rq2_results_df)
cat("\n--- RQ2: Cross-Project Generalization - Performance Across Projects ---\n"); print(rq2_summary)

# --- 5. RQ3: HYBRID TRANSFER ---
cat("\n\n--- Running Experiment for RQ3: Hybrid Transfer ---\n")
rq3_results <- list()
for (target_proj_name in project_names) {
  cat(paste("Target project:", target_proj_name, "\n"))
  
  # A. DATA SPLITTING (Hybrid)
  source_proj_names <- setdiff(project_names, target_proj_name)
  target_df <- project_data[[target_proj_name]] %>% arrange(days_since_project_start)
  split_point <- floor(0.8 * nrow(target_df))
  target_train_df <- target_df[1:split_point, ]
  test_df <- target_df[(split_point + 1):nrow(target_df), ]
  source_df <- bind_rows(project_data[source_proj_names])
  train_df <- bind_rows(source_df, target_train_df)
  
  # B. PREPROCESSING
  train_processed <- preprocess_data(train_df)
  test_processed <- preprocess_data(test_df)
  train_cols <- colnames(train_processed)
  for(col in train_cols){ if(!col %in% colnames(test_processed)){ test_processed[[col]] <- 0 } }
  test_processed <- test_processed[, train_cols]
  
  # C. PREPARE DATA FOR XGBOOST
  train_features <- train_processed %>% select(-resolution_time, -log_resolution_time)
  train_target <- train_processed$log_resolution_time
  test_features <- test_processed %>% select(-resolution_time, -log_resolution_time)
  test_target_actual_days <- test_processed$resolution_time
  dtrain <- xgb.DMatrix(data = as.matrix(train_features), label = train_target)
  dtest <- xgb.DMatrix(data = as.matrix(test_features))
  
  # D. MODEL TRAINING
  median_baseline_pred_log <- median(train_target)
  xgb_params <- list(objective = "reg:squarederror", eval_metric = "rmse", eta = 0.05, max_depth = 4, subsample = 0.8, colsample_bytree = 0.8)
  xgb_model <- xgb.train(params = xgb_params, data = dtrain, nrounds = 250, verbose = 0)
  
  # E. PREDICTION & INVERSE TRANSFORM
  baseline_preds_days <- rep(expm1(median_baseline_pred_log), nrow(test_df))
  xgb_preds_log <- predict(xgb_model, dtest)
  xgb_preds_days <- expm1(xgb_preds_log)
  
  # F. EVALUATION
  rq3_results[[target_proj_name]] <- tibble(
      target_project = target_proj_name, model = c("Median Baseline", "XGBoost"),
      MAE = c(mae(test_target_actual_days, baseline_preds_days), mae(test_target_actual_days, xgb_preds_days)),
      RMSE = c(rmse(test_target_actual_days, baseline_preds_days), rmse(test_target_actual_days, xgb_preds_days))
  )
}
# G. AGGREGATE AND DISPLAY RESULTS FOR RQ3
rq3_results_df <- bind_rows(rq3_results)
rq3_summary <- rq3_results_df %>% group_by(model) %>% summarise(Avg_MAE = mean(MAE), Avg_RMSE = mean(RMSE))
cat("\n--- RQ3: Hybrid Transfer - Results by Project ---\n"); print(rq3_results_df)
cat("\n--- RQ3: Hybrid Transfer - Performance Across Projects ---\n"); print(rq3_summary)


# --- 6. RQ4: FEATURE CONSISTENCY ---
cat("\n\n--- Analyzing Results for RQ4: Feature Consistency ---\n")

# A. AGGREGATE FEATURE IMPORTANCE
feature_importance_df <- bind_rows(rq4_feature_importance)

cat("\n--- RQ4: Feature Importance Scores by Project ---\n")
print(feature_importance_df)

# B. VISUALIZE FEATURE IMPORTANCE
# To make the plot readable, we'll show the top 7 features for each project
top_features <- feature_importance_df %>%
  group_by(project) %>%
  slice_max(order_by = Gain, n = 7) %>%
  ungroup()

importance_plot <- top_features %>%
  mutate(Feature = reorder_within(Feature, Gain, project)) %>%
  ggplot(aes(x = Gain, y = Feature, fill = project)) +
  geom_col(show.legend = FALSE) +
  scale_y_reordered() +
  facet_wrap(~ project, scales = "free") +
  scale_fill_manual(values = c("Cassandra" = "#d93955", 
                               "Flink"     = "#d9bd39", 
                               "Kafka"     = "#d96d39")) +
  labs(
    title = "Top 7 Most Important Features by Project",
    subtitle = "Comparison of feature importance (Gain) across within-project models",
    x = "Importance (Gain)",
    y = "Feature"
  ) +
  theme_minimal()

print(importance_plot)
