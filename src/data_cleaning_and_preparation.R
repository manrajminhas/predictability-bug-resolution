#!/usr/bin/env Rscript

# Loads raw bug JSON, cleans it, engineers features,
# selects only the useful columns, and saves as an RDS.

# Install / load needed packages
if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite")
if (!requireNamespace("dplyr",    quietly = TRUE)) install.packages("dplyr")
if (!requireNamespace("lubridate",quietly = TRUE)) install.packages("lubridate")
if (!requireNamespace("stringr",  quietly = TRUE)) install.packages("stringr")

library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)

# Set the working directory to the data folder
script_dir <- dirname(rstudioapi::getActiveDocumentContext()$path)
output_dir <- file.path(script_dir, "..", "data")
setwd(output_dir)

# USER CONFIGURATION
# Change this key to process a different project's data
projectKey <- "CASSANDRA"

# Load & flatten raw JSON
input_file <- paste0(projectKey, "_raw.json")
dataset <- fromJSON(input_file, flatten = TRUE)

# Filter out rows missing created or resolution dates
valid_rows <- !is.na(dataset$fields.created) &
              lengths(dataset$fields.resolutiondate) > 0
dataset <- dataset[valid_rows, ]

# Pull out atomic predictor columns & summarize lists
dataset <- dataset %>%
  mutate(
    # basic metadata
    priority         = fields.priority.name,
    reporter         = fields.reporter.name,
    watch_count      = fields.watches.watchCount,
    vote_count       = fields.votes.votes,
    # list‐column summaries
    num_comments    = sapply(fields.comment.comments, function(x) {
                         if (is.data.frame(x)) nrow(x) else 0
                       }),
    num_attachments = sapply(fields.attachment, function(x) {
                         if (is.data.frame(x)) nrow(x) else 0
                       }),
    description_length = nchar(sapply(fields.description, `[`, 1))
  )

# Drop rows with NA in any atomic predictor
keep_cols <- c("priority","reporter","watch_count","vote_count",
               "num_comments","num_attachments","description_length")
dataset <- dataset[ complete.cases(dataset[, keep_cols]), ]

# Parse dates & compute resolution_time
dataset <- dataset %>%
  mutate(
    # get the very last resolution timestamp
    last_res = sapply(fields.resolutiondate, function(x) tail(x,1)),
    created_date    = ymd_hms(fields.created, tz = "UTC"),
    resolution_date = ymd_hms(last_res,       tz = "UTC"),
    resolution_time = as.numeric( difftime(resolution_date, created_date, units = "days") )
  ) %>%
  select(-last_res)

# Time‐based features & rolling counts
project_start <- min(dataset$created_date, na.rm = TRUE)

dataset <- dataset %>%
  mutate(
    created_wday             = wday(created_date, label = TRUE),
    created_month            = month(created_date, label = TRUE),
    days_since_project_start = as.integer(difftime(created_date, project_start, units = "days")),
    bugs_last_7d             = sapply(created_date, function(x)
                                   sum(created_date >= (x - days(7)) & created_date < x)),
    bugs_last_30d            = sapply(created_date, function(x)
                                   sum(created_date >= (x - days(30)) & created_date < x))
  )

# Code‐block & inline‐attachment flags
desc <- sapply(dataset$fields.description, `[`, 1)
pattern_code_block    <- "(?s)\\{code(:[^}]+)?\\}.*?\\{code\\}"
pattern_inline_attach <- "!\\S+?\\.(?:png|jpe?g|gif|bmp|pdf|zip|patch)\\b.*?!"

dataset <- dataset %>%
  mutate(
    has_code_block        = str_detect(desc, regex(pattern_code_block)),
    has_inline_attachment = str_detect(desc, regex(pattern_inline_attach, ignore_case = TRUE))
  )

# Reporter experience (historic bug count per reporter)
dataset <- dataset %>%
  arrange(created_date) %>%
  mutate(
    reporter_experience = as.integer(ave(
      as.numeric(created_date),
      reporter,
      FUN = function(dts) rank(dts, ties.method = "first") - 1
    ))
  )

# Select final model‐ready columns
cleaned <- dataset %>%
  transmute(
    resolution_time,
    priority,
    watch_count,
    vote_count,
    num_comments,
    num_attachments,
    description_length,
    has_code_block,
    has_inline_attachment,
    created_wday,
    created_month,
    days_since_project_start,
    bugs_last_7d,
    bugs_last_30d,
    reporter_experience
  )

# Save cleaned data
output_file <- paste0(projectKey, "_cleaned.rds")
saveRDS(
  cleaned,
  file = file.path(getwd(), output_file)
)

message(sprintf("✅ Saved cleaned data to '%s' in %s", output_file, getwd()))
