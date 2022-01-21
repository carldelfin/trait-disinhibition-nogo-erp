if (!file.exists(here("analysis/data/tmp/correlation_nogo_accuracy_formatted.rds")) || overwrite == TRUE) {
  brms_robust_correlation <- readRDS(here("analysis/scripts/brms/brms_robust_correlation.rds"))
  correlation_nogo_accuracy <-
    rbind(
      get_correlation(merged_data, "nogo_accuracy", "n2_windowed_amplitude"),
      get_correlation(merged_data, "nogo_accuracy", "n2_moving_amplitude"),
      get_correlation(merged_data, "nogo_accuracy", "n2_latency"),
      
      get_correlation(merged_data, "nogo_accuracy", "p3_windowed_amplitude"),
      get_correlation(merged_data, "nogo_accuracy", "p3_moving_amplitude"),
      get_correlation(merged_data, "nogo_accuracy", "p3_latency"))

  correlation_nogo_accuracy_formatted <- correlation_nogo_accuracy %>%
    mutate_if(is.numeric, round, 2) %>%
    mutate(rho = paste0(rho, " [", rho_lower_90, ", ", rho_upper_90, "]"),
           p_direction = paste0(p_direction, "%")) %>%
    select(variable_2, rho, p_direction)
  
  saveRDS(correlation_nogo_accuracy, here("analysis/data/tmp/correlation_nogo_accuracy.rds"))
  saveRDS(correlation_nogo_accuracy_formatted, here("analysis/data/tmp/correlation_nogo_accuracy_formatted.rds"))
}