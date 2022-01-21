# ------------------------------------------------------------------------------
# Check if data exists
# ------------------------------------------------------------------------------

if (!file.exists(here("analysis/data/tmp/reliability_models.rds")) || overwrite == TRUE) {
  
  merged_data <- readRDS(here("analysis/data/tmp/merged_data.rds"))
  
  # ------------------------------------------------------------------------------
  # NoGo accuracy and RT
  # ------------------------------------------------------------------------------
  
  # which subjects are included in the analysis?
  subjects <- merged_data$ID
  
  # create two data frames divided by odd/even trial numbers
  file_list <- grep(list.files(path =  here("analysis/data/gonogo/"), pattern = "*.txt"), pattern = "Summary", inv = TRUE, value = TRUE)       
  gng_data <- data.frame()
  
  for(i in file_list) {
    path <- paste0(here("analysis/data/gonogo/"), i)
    
    results <- read_delim(path, "\t", escape_double = FALSE, trim_ws = TRUE) %>%
      filter(`Block Name` == "Main") %>%
      filter(Condition == "NoGo") %>%
      mutate(ID = gsub("-.*", "", i),
             trial = `Trial Number`,
             response = Accuracy,
             rt = RT) %>%
      select(ID, trial, response, rt)
    
    gng_data <- rbind(gng_data, results)
  }
  
  odd <- seq(1, range(gng_data$trial)[2], 2)
  gng_data_odd <- gng_data %>% filter(trial %in% odd)
  gng_data_even <- gng_data %>% filter(!trial %in% odd)
  
  # now loop through all participants and calculate NoGo accuracy and RT using each data frame
  file_list <- grep(list.files(path =  here("analysis/data/gonogo/"), pattern = "*.txt"), pattern = "Summary", inv = TRUE, value = TRUE)       
  go_nogo_reliability_data <- data.frame()
  
  for(i in file_list) {
    id = gsub("-.*", "", i)
    
    tmp_odd <- gng_data_odd %>%
      filter(ID == id)
    
    nogo_correct_odd <- nrow(tmp_odd[which(tmp_odd$response == 'rm_other'), ])
    nogo_incorrect_odd <- nrow(tmp_odd[which(tmp_odd$response == 'rm_false_alarm'), ])
    nogo_accuracy_odd <- nogo_correct_odd / (nogo_incorrect_odd + nogo_correct_odd)
    median_nogo_rt_odd <- median(tmp_odd[which(tmp_odd$response == 'rm_false_alarm'), ]$rt)
    
    tmp_even <- gng_data_even %>%
      filter(ID == id)
    
    nogo_correct_even <- nrow(tmp_even[which(tmp_even$response == 'rm_other'), ])
    nogo_incorrect_even <- nrow(tmp_even[which(tmp_even$response == 'rm_false_alarm'), ])
    nogo_accuracy_even <- nogo_correct_even / (nogo_incorrect_even + nogo_correct_even)
    median_nogo_rt_even <- median(tmp_even[which(tmp_even$response == 'rm_false_alarm'), ]$rt)
    
    df <- data.frame(ID = id,
                     nogo_accuracy_odd = nogo_accuracy_odd,
                     nogo_accuracy_even = nogo_accuracy_even,
                     median_nogo_rt_odd = median_nogo_rt_odd,
                     median_nogo_rt_even = median_nogo_rt_even)
    
    go_nogo_reliability_data <- rbind(go_nogo_reliability_data, df)
  }
  
  # remove subjects not included in the analysis
  go_nogo_reliability_data <-
    go_nogo_reliability_data %>%
    filter(ID %in% subjects)
  
  # ------------------------------------------------------------------------------
  # NoGo N2 and P3 ERPs
  # ------------------------------------------------------------------------------
  
  # create two data frames divided by odd/even epoch numbers
  paths <- list.files(path = here("preprocess/output/raw_data"),
                      pattern = "*nogocorr_raw.csv",
                      full.names = TRUE)
  
  files <- lapply(paths, read_csv_filename)
  
  raw_eeg_data <- bind_rows(files) %>%
    mutate(ID = gsub("(.*/\\s*(.*$))", "\\2", ID),
           ID = gsub("\\_.*","", ID),
           group = as.factor(ifelse(grepl("KON", ID), "control", "patient")),
           amplitude = rowMeans(select(.,
                                       E20, E12, E5, E118,
                                       E13, E6, E112,
                                       E7, E106))) %>%
    select(epoch, time, ID, group, amplitude)
  
  odd <- seq(1, range(raw_eeg_data$epoch)[2], 2)
  
  raw_eeg_data_odd <-
    raw_eeg_data %>%
    filter(epoch %in% odd) %>%
    filter(ID %in% subjects) %>%
    aggregate(amplitude ~ time + ID + group,
              data = .,
              FUN = "mean")
  
  raw_eeg_data_even <-
    raw_eeg_data %>%
    filter(!epoch %in% odd) %>%
    filter(ID %in% subjects) %>%
    aggregate(amplitude ~ time + ID + group,
              data = .,
              FUN = "mean")
  
  erp_reliability_data <-
    data.frame(
      # ID
      ID = get_erp_measures(raw_eeg_data_odd, n2_lower_bound, n2_upper_bound, "n2")[, "ID"],
      
      # N2
      n2_windowed_amplitude_odd = get_erp_measures(raw_eeg_data_odd, n2_lower_bound, n2_upper_bound, "n2")[, "n2_windowed_amplitude"],
      n2_windowed_amplitude_even = get_erp_measures(raw_eeg_data_even, n2_lower_bound, n2_upper_bound, "n2")[, "n2_windowed_amplitude"],
     
      n2_moving_amplitude_odd = get_erp_measures(raw_eeg_data_odd, n2_lower_bound, n2_upper_bound, "n2")[, "n2_moving_amplitude"],
      n2_moving_amplitude_even = get_erp_measures(raw_eeg_data_even, n2_lower_bound, n2_upper_bound, "n2")[, "n2_moving_amplitude"],
      
      n2_latency_odd = get_erp_measures(raw_eeg_data_odd, n2_lower_bound, n2_upper_bound, "n2")[, "n2_latency"],
      n2_latency_even = get_erp_measures(raw_eeg_data_even, n2_lower_bound, n2_upper_bound, "n2")[, "n2_latency"],
      
      # P3
      p3_windowed_amplitude_odd = get_erp_measures(raw_eeg_data_odd, p3_lower_bound, p3_upper_bound, "p3")[, "p3_windowed_amplitude"],
      p3_windowed_amplitude_even = get_erp_measures(raw_eeg_data_even, p3_lower_bound, p3_upper_bound, "p3")[, "p3_windowed_amplitude"],
      
      p3_moving_amplitude_odd = get_erp_measures(raw_eeg_data_odd, p3_lower_bound, p3_upper_bound, "p3")[, "p3_moving_amplitude"],
      p3_moving_amplitude_even = get_erp_measures(raw_eeg_data_even, p3_lower_bound, p3_upper_bound, "p3")[, "p3_moving_amplitude"],
      
      p3_latency_odd = get_erp_measures(raw_eeg_data_odd, p3_lower_bound, p3_upper_bound, "p3")[, "p3_latency"],
      p3_latency_even = get_erp_measures(raw_eeg_data_even, p3_lower_bound, p3_upper_bound, "p3")[, "p3_latency"])
  
  reliability_data <- merge(go_nogo_reliability_data, erp_reliability_data, by = "ID")
  
  # ------------------------------------------------------------------------------
  # Model and save correlations
  # ------------------------------------------------------------------------------
  
  brms_robust_correlation <- readRDS(here("analysis/scripts/brms/brms_robust_correlation.rds"))
  
    reliability_models <-
      rbind(get_reliability(reliability_data, "nogo_accuracy"),
            get_reliability(reliability_data, "median_nogo_rt"),
            get_reliability(reliability_data, "n2_windowed_amplitude"),
            get_reliability(reliability_data, "n2_moving_amplitude"),
            get_reliability(reliability_data, "n2_latency"),
            get_reliability(reliability_data, "p3_windowed_amplitude"),
            get_reliability(reliability_data, "p3_moving_amplitude"),
            get_reliability(reliability_data, "p3_latency"))
    
    saveRDS(reliability_models, here("analysis/data/tmp/reliability_models.rds"))
}
    
# ------------------------------------------------------------------------------
# Process results
# ------------------------------------------------------------------------------

reliability_models <- readRDS(here("analysis/data/tmp/reliability_models.rds"))

reliability_models <-
  reliability_models %>%
  mutate_if(is.numeric, round, 2) %>%
  mutate(rho_sb = paste0(rho_sb, " [", rho_sb_lower_90, ", ", rho_sb_upper_90, "]"),
         p_direction = paste0(p_direction, "%"),
         Measure = variable) %>%
  select(Measure, rho_sb, p_direction)

# ------------------------------------------------------------------------------
# Keep environment clean
# ------------------------------------------------------------------------------

rm(file_list, i, id, median_nogo_rt_even, median_nogo_rt_odd, nogo_accuracy_even,
   nogo_accuracy_odd, nogo_correct_even, nogo_correct_odd, nogo_incorrect_even,
   nogo_incorrect_odd, odd, path, paths, subjects)

rm(brms_robust_correlation,
   df,
   erp_reliability_data,
   files,
   gng_data,
   gng_data_even,
   gng_data_odd,
   go_nogo_reliability_data,
   raw_eeg_data,
   raw_eeg_data_even,
   raw_eeg_data_odd,
   reliability_data,
   results,
   tmp_even,
   tmp_odd)
