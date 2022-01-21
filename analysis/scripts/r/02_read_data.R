# ------------------------------------------------------------------------------
# Does data exist, and shall we overwrite if so?
# ------------------------------------------------------------------------------

if (!file.exists(here("analysis/data/tmp/merged_data.rds")) || overwrite == TRUE) {
  
  # ------------------------------------------------------------------------------
  # Read and prepare logfiles
  # ------------------------------------------------------------------------------
  
  patterns <- c("*filter_log.csv",
                "*ica_log.csv",
                "*epoch_log.csv",
                "*autoreject_log.csv",
                "*timer_log.csv")
  
  log_data <- lapply(patterns, log_reader) %>%
    reduce(full_join, by = "ID") %>%
    mutate(group = as.factor(ifelse(grepl("KON", ID), "control", "patient"))) %>%
    select(ID,
           preprocessing_time_in_minutes,
           group,
           num_bad_channels_interpolated,
           num_icas_zeroed_out,
           num_correct_nogo_trials,
           num_correct_nogo_trials_after_ar,
           perc_correct_nogo_trials_after_ar,
           perc_bad_and_rejected_channels,
           perc_bad_and_interpolated_channels)
  
  # ------------------------------------------------------------------------------
  # Remove participants
  # ------------------------------------------------------------------------------
  
  # The preprocessing pipeline removes participants with less than four correct
  # nogo trials left after Autoreject epoch cleaning.
  # The number of participants removed is saved in a text file.
  
  remove <- log_data$ID[which(log_data$num_correct_nogo_trials_after_ar < 4)]
  log_data <- log_data[!(log_data$ID %in% remove), ]
    
  # ------------------------------------------------------------------------------
  # Read EEG data
  # ------------------------------------------------------------------------------
  
  # All preprocessed EEG data is stored as `.csv` files. 
  # A small custom function reads the CSVs, gets the filename,
  # and transforms that into the correct participant ID. 
  
  # Instead of relying on just the midline electrodes we take advantage of the 
  # high-density, 128 channel sensor net. Nine frontal electrodes, distributed 
  # evenly from the midline, are used to create a frontocentral
  # region-of-interest.
  
  paths <- list.files(path = here("preprocess/output/data"),
                      pattern = "*nogocorr.csv",
                      full.names = TRUE)
  
  files <- lapply(paths, read_csv_filename)
  
  eeg_data <- bind_rows(files) %>%
    mutate(ID = gsub(".*[corr/]([^.]+)[_].*", "\\1", ID),
           group = as.factor(ifelse(grepl("KON", ID), "control", "patient")),
           amplitude = rowMeans(select(.,
                                       E20, E12, E5, E118,
                                       E13, E6, E112,
                                       E7, E106))) %>%
    select(time, ID, group, amplitude)
  
  # ------------------------------------------------------------------------------
  # Aggregate data
  # ------------------------------------------------------------------------------
  
  # An aggregated (over time/group) EEG dataframe is created for ERP plotting. 
  # A cropped *and* aggregated EEG dataframe is created for subsequent analysis, 
  # containing the average amplitude over the specific time window 
  # post-stimulus.
  
  # aggregated eeg data, time transformed into seconds
  eeg_data_aggregated <- aggregate(amplitude ~ time + group,
                                   data = eeg_data,
                                   FUN = "mean") %>%
    mutate(time = time * 0.001)
  
  saveRDS(eeg_data_aggregated, here("analysis/data/tmp/eeg_data_aggregated.rds"))
  
  # ------------------------------------------------------------------------------
  # Calculate ERP measures
  # ------------------------------------------------------------------------------
  
  n2_component_data <- get_erp_measures(eeg_data, n2_lower_bound, n2_upper_bound, "n2")
  p3_component_data <- get_erp_measures(eeg_data, p3_lower_bound, p3_upper_bound, "p3")
  
  # ------------------------------------------------------------------------------
  # Read survey data
  # ------------------------------------------------------------------------------
  
  # All survey data is stored in a `.csv` file.
  # The file contains demographic information, self-report instruments,
  # and clinical data.
  
  survey_data <- read_csv(here("analysis/data/survey/survey.csv"))
  
  # reverse items needed for general disinhibtion factor
  rev_items <- c("esi90", "esi125")
  
  survey_data[, rev_items] <- 3 - survey_data[, rev_items]
  
  survey_data$general_disinhibition <- rowSums(survey_data[c(
    "esi1", "esi9", "esi10", "esi19", "esi28",
    "esi36", "esi41", "esi44", "esi49", "esi65",
    "esi73", "esi84", "esi90", "esi92", "esi95",
    "esi112", "esi125", "esi143", "esi144", "esi152")])
  
  # remove based on self-report
  survey_data <- survey_data %>%
    filter(!ID %in% c("KON004", "KON116", "KON119", "KON120", "KON205"))
  
  # ------------------------------------------------------------------------------
  # Read Go/NoGo data
  # ------------------------------------------------------------------------------
  
  folder <- here("analysis", "data", "gonogo/")
  
  file_list <- grep(list.files(path = folder, pattern = "*.txt"), pattern = "Summary", inv = TRUE, value = TRUE)       
  gng_data <- data.frame()
  for(i in file_list) {
    path <- paste0(folder, i)
    data <- read_delim(path, "\t", escape_double = FALSE, trim_ws = TRUE)
    
    go_correct <- nrow(data[which(data$`Block Name` == 'Main' 
                                  & data$Condition == 'Go'
                                  & data$Accuracy == 'rm_hit'), ])
    
    go_incorrect <- nrow(data[which(data$`Block Name` == 'Main' 
                                    & data$Condition == 'Go'
                                    & data$Accuracy == 'rm_miss'), ])
    
    nogo_correct <- nrow(data[which(data$`Block Name` == 'Main' 
                                    & data$Condition == 'NoGo'
                                    & data$Accuracy == 'rm_other'), ])
    
    nogo_incorrect <- nrow(data[which(data$`Block Name` == 'Main' 
                                      & data$Condition == 'NoGo'
                                      & data$Accuracy == 'rm_false_alarm'), ])
    
    go_accuracy <- go_correct / (go_incorrect + go_correct)
    nogo_accuracy <- nogo_correct / (nogo_incorrect + nogo_correct)
    num_go_trials <- go_incorrect + go_correct
    num_nogo_trials <- nogo_incorrect + nogo_correct
    
    mean_go_rt <- round(mean(data[which(data$`Block Name` == 'Main' 
                                        & data$Condition == 'Go'
                                        & data$Accuracy == 'rm_hit'), ]$RT), 0)
    
    median_go_rt <- round(median(data[which(data$`Block Name` == 'Main' 
                                            & data$Condition == 'Go'
                                            & data$Accuracy == 'rm_hit'), ]$RT), 0)
    
    
    mean_nogo_rt <- round(mean(data[which(data$`Block Name` == 'Main' 
                                          & data$Condition == 'NoGo'
                                          & data$Accuracy == 'rm_false_alarm'), ]$RT), 0)
    
    median_nogo_rt <- round(median(data[which(data$`Block Name` == 'Main' 
                                              & data$Condition == 'NoGo'
                                              & data$Accuracy == 'rm_false_alarm'), ]$RT), 0)
    
    results <- data.frame(ID = gsub("-.*", "", i),
                          go_correct = go_correct,
                          go_incorrect = go_incorrect,
                          nogo_correct = nogo_correct,
                          nogo_incorrect = nogo_incorrect,
                          go_accuracy = go_accuracy,
                          nogo_accuracy = nogo_accuracy,
                          mean_go_rt = mean_go_rt,
                          median_go_rt = median_go_rt,
                          mean_nogo_rt = mean_nogo_rt,
                          median_nogo_rt = median_nogo_rt,
                          num_go_trials = num_go_trials,
                          num_nogo_trials = num_nogo_trials)
    
    gng_data <- rbind(gng_data, results)
  }
  
  gng_data <- gng_data %>% select(ID, nogo_accuracy, median_nogo_rt, nogo_correct, nogo_incorrect)

  # ------------------------------------------------------------------------------
  # Create merged dataframe
  # ------------------------------------------------------------------------------
  
  merged_data <- Reduce(function(x, y) merge(x, y, by = "ID", all = TRUE),
                        list(log_data,
                             n2_component_data,
                             p3_component_data,
                             survey_data,
                             gng_data)) %>%
    drop_na(p3_windowed_amplitude, general_disinhibition) %>%
    mutate(group = as.factor(group.x)) %>%
    select(-c(group.y, group.x))
  
  # ------------------------------------------------------------------------------
  # Save data
  # ------------------------------------------------------------------------------
  
  saveRDS(merged_data, here("analysis/data/tmp/merged_data.rds"))
}

# clear environment of unecessary variables
rm(file_list, folder, go_accuracy, go_correct, go_incorrect, i, mean_go_rt,
   mean_nogo_rt, median_go_rt, median_nogo_rt, nogo_accuracy, nogo_correct,
   nogo_incorrect, num_go_trials, num_nogo_trials, path, paths, patterns,
   rev_items, sub_string)

# clear environment of temporary data frames
rm(eeg_data, eeg_data_aggregated, results, data, files, log_data, n2_component_data, p3_component_data, survey_data, gng_data)
