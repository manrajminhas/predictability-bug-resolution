#!/usr/bin/env Rscript
# extract_asf_jira_json.R
# -------------------------------------
# Fetches all Bug issues for a given ASF JIRA project
# and writes them (the full JSON objects) to a .json file.

# --- Install / load needed packages ---
if (!requireNamespace("httr",     quietly = TRUE)) install.packages("httr",     repos = "https://cloud.r-project.org")
if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite", repos = "https://cloud.r-project.org")

library(httr)
library(jsonlite)

# --- Set the working directory to the data folder ---
script_dir <- dirname(rstudioapi::getActiveDocumentContext()$path)
output_dir <- file.path(script_dir, "..", "data")
setwd(output_dir)

# --- USER CONFIGURATION ---
projectKey <- "CASSANDRA"   # e.g. "HADOOP", "CASSANDRA", etc.
issueType  <- "Bug"
batch_size <- 100       # JIRA maxResults per page

# --- Constants ---
base_url        <- "https://issues.apache.org/jira"
search_endpoint <- paste0(base_url, "/rest/api/2/search")
jql <- sprintf(
  'project="%s" 
   AND issuetype="%s" 
   AND status in (Resolved, Closed) 
   ORDER BY created ASC',
  projectKey, issueType
)

# --- Fetch in pages, preserving full JSON structure ---
start_at    <- 0
total       <- Inf
all_issues  <- list()

while (start_at < total) {
  resp <- GET(search_endpoint, query = list(
    jql        = jql,
    startAt    = start_at,
    maxResults = batch_size,
    fields     = "*all"
  ))
  stop_for_status(resp)

  # parse WITHOUT flattening
  dat <- fromJSON(content(resp, "text", encoding = "UTF-8"), simplifyVector = FALSE, flatten = FALSE)

  if (is.infinite(total)) {
    total <- dat$total
    message(sprintf("Total issues to fetch: %d", total))
  }

  # append this page's list of issue‐objects
  all_issues <- c(all_issues, dat$issues)
  start_at   <- start_at + batch_size
}

# --- Write out as pretty JSON ---
outfile <- sprintf("%s_raw.json", projectKey)
write_json(
  all_issues, 
  path       = outfile, 
  pretty     = TRUE, 
  auto_unbox = TRUE
)

message(sprintf("✅ Saved %d issues to '%s' in %s",
                length(all_issues), outfile, getwd()))
