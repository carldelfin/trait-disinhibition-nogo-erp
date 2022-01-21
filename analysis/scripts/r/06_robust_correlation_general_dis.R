if (!file.exists(here("analysis/data/tmp/correlation_general_disinhibition_formatted.rds")) || overwrite == TRUE) {
  brms_robust_correlation <- readRDS(here("analysis/scripts/brms/brms_robust_correlation.rds"))
  correlation_general_disinhibition <-
    rbind(
      get_correlation(merged_data, "general_disinhibition", "n2_windowed_amplitude"),
      get_correlation(merged_data, "general_disinhibition", "n2_moving_amplitude"),
      get_correlation(merged_data, "general_disinhibition", "n2_latency"),
      
      get_correlation(merged_data, "general_disinhibition", "p3_windowed_amplitude"),
      get_correlation(merged_data, "general_disinhibition", "p3_moving_amplitude"),
      get_correlation(merged_data, "general_disinhibition", "p3_latency"))
  
  correlation_general_disinhibition_formatted <- correlation_general_disinhibition %>%
    mutate_if(is.numeric, round, 2) %>%
    mutate(rho = paste0(rho, " [", rho_lower_90, ", ", rho_upper_90, "]"),
           p_direction = paste0(p_direction, "%")) %>%
    select(variable_2, rho, p_direction)
  
  saveRDS(correlation_general_disinhibition, here("analysis/data/tmp/correlation_general_disinhibition.rds"))
  saveRDS(correlation_general_disinhibition_formatted, here("analysis/data/tmp/correlation_general_disinhibition_formatted.rds"))
}