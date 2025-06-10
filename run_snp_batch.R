


#!/usr/bin/env Rscript

# Load packages
if (!requireNamespace("SNPediaR", quietly = TRUE)) {
  stop("⚠️ Please install SNPediaR first.")
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Install jsonlite first.")
}
if (!requireNamespace("parallel", quietly = TRUE)) {
  stop("Install parallel first.")
}
library(SNPediaR)
library(jsonlite)
library(parallel)

# Settings
num_cores <- max(1, floor(detectCores() * 0.8))  # Use 80% of cores
cat("🔧 Using", num_cores, "cores\n")
api_limit <- 50
api_delay <- 1
batch_size <- 500
output_dir <- "/data/batch_results"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Read input file
input_path <- "/data/input.txt"
if (!file.exists(input_path)) {
  stop("❌ input.txt not found.")
}
lines <- tryCatch({
  readLines(input_path, warn = TRUE, encoding = "UTF-8")
}, error = function(e) {
  cat("❌ Error reading input:", conditionMessage(e), "\n")
  stop("Cannot read input file.")
})
lines <- trimws(lines)
lines <- lines[lines != "" & !is.na(lines)]
if (length(lines) == 0) {
  stop("Input.txt is empty.")
}

# Count total rsIDs
total_rsids <- length(lines)
cat("📊 Total rsIDs:", total_rsids, "\n")

# Split into batches of 500
batches <- split(lines, ceiling(seq_along(lines) / batch_size))
cat("📦 Created", length(batches), "batches\n")

# Function to extract conditions
extract_conditions <- function(page_content) {
  tryCatch({
    if (is.null(page_content) || length(page_content) == 0) {
      return(character(0))
    }
    raw_text <- paste(unlist(page_content), collapse = " ")
    valid_conditions <- tryCatch({
      Sys.sleep(api_delay)
      getCategoryElements(category = "Is_a_medical_condition")
    }, error = function(e) {
      cat("⚠ Error fetching conditions:", conditionMessage(e), "\n")
      return(character(0))
    })
    conditions <- c()
    for (condition in valid_conditions) {
      pattern <- paste0("(\\b|\\[\\[)", condition, "(\\b|\\]\\])")
      if (grepl(pattern, raw_text, ignore.case = TRUE)) {
        conditions <- c(conditions, condition)
      }
    }
    return(unique(conditions))
  }, error = function(e) {
    cat("⚠ Error extracting conditions:", conditionMessage(e), "\n")
    return(character(0))
  })
}

# Function to process a single rsID
process_entry <- function(entry) {
  tryCatch({
    rsid <- sub(",\\(", "", entry)
    genotype <- if (grepl("\\(", entry)) sub(".*?,", "", entry) else NULL
    rsid_data <- list()
    Sys.sleep(api_delay)
    res <- tryCatch({
      getPages(titles = rsid, limit = api_limit)
    }, error = function(e) {
      cat("⚠ Error fetching", rsid, ":", conditionMessage(e), "\n")
      return(NULL)
    })
    if (is.null(res) || length(res) == 0) {
      return(list(rsid = rsid, data = list(error = paste("Not found:", rsid))))
    }
    rsid_data$snp_info <- tryCatch({
      t(sapply(res, extractSnpTags))
    }, error = function(e) {
      cat("⚠ Error extracting SNP tags for", rsid, ":", conditionMessage(e), "\n")
      return(NULL)
    })
    if (is.null(rsid_data$snp_info)) {
      return(list(rsid = rsid, data = list(error = "Failed to extract SNP tags")))
    }
    cat("📄 SNP Info for", rsid, ":\n")
    print(rsid_data$snp_info)
    page_content <- tryCatch({
      getPages(titles = rsid, wikiParseFunction = identity)
    }, error = function(e) {
      cat("⚠ Error fetching page for", rsid, ":", conditionMessage(e), "\n")
      return("")
    })
    rsid_data$conditions <- extract_conditions(page_content[[1]])
    cat("📋 Conditions for", rsid, ":\n")
    print(rsid_data$conditions)
    if (is.null(genotype)) {
      genos <- tryCatch({
        unlist(lapply(res, function(x) {
          geno <- extractTags(x, c("geno1", "geno2", "geno3"))
          paste0(rsid, geno[!is.na(geno)])
        }))
      }, error = function(e) {
        cat("⚠ Error extracting genotypes for", rsid, ":", conditionMessage(e), "\n")
        return(character(0))
      })
      if (length(genos) == 0) {
        rsid_data$genotype_error <- "No genotype tags found"
        return(list(rsid = rsid, data = rsid_data))
      }
      rsid_data$genotypes <- genos
    } else {
      genos <- paste0(rsid, genotype)
      rsid_data$genotypes <- genos
    }
    res2 <- tryCatch({
      Sys.sleep(api_delay)
      getPages(titles = genos, limit = api_limit, wikiParseFunction = extractGenotypeTags)
    }, error = function(e) {
      cat("⚠ Error fetching genotypes for", genos, ":", conditionMessage(e), "\n")
      return(list())
    })
    valid <- Filter(function(x) !is.null(x) && is.character(x), res2)
    if (length(valid) == 0) {
      rsid_data$genotype_error <- paste("No genotype info found for", genos)
    } else {
      rsid_data$genotype_info <- tryCatch({
        t(sapply(valid, identity))
      }, error = function(e) {
        cat("⚠ Error processing genotype info:", conditionMessage(e), "\n")
        return(NULL)
      })
    }
    return(list(rsid = rsid, data = rsid_data))
  }, error = function(e) {
    return(list(rsid = rsid, data = list(error = paste("Error processing", entry, ":", conditionMessage(e)))))
  })
}

# Process batches and save individual results
output <- list()
for (i in seq_along(batches)) {
  batch <- batches[[i]]
  cat("\n🟢 Processing batch", i, "of", length(batches), "with", length(batch), "entries\n")
  results <- tryCatch({
    mclapply(batch, process_entry, mc.cores = num_cores)
  }, warning = function(w) {
    cat("⚠ Warning in batch", i, ":", conditionMessage(w), "\n")
    lapply(batch, function(entry) {
      rsid <- sub(",\\(.*", "", entry)
      list(rsid = rsid, data = list(error = paste("Parallel warning:", conditionMessage(w))))
    })
  }, error = function(e) {
    cat("❌ Error in batch", i, ":", conditionMessage(e), "\n")
    lapply(batch, function(entry) {
      rsid <- sub(",\\(.*", "", entry)
      list(rsid = rsid, data = list(error = paste("Parallel error:", conditionMessage(e))))
    })
  })
  
  # Save batch results
  batch_output <- list()
  for (res in results) {
    if (!is.null(res$rsid) && !is.null(res$data)) {
      batch_output[[res$rsid]] <- res$data
    }
  }
  batch_file <- file.path(output_dir, paste0("batch_", sprintf("%04d", i), ".json"))
  write_json(batch_output, batch_file, pretty = TRUE, auto_unbox = TRUE)
  cat("💾 Saved batch", i, "to", batch_file, "\n")
  
  # Add to combined output
  output <- c(output, batch_output)
}

# Save combined output
output_file <- "/data/output.json"
write_json(output, output_file, pretty = TRUE, auto_unbox = TRUE)
cat("\n✅ Saved combined output to", output_file, "\n")