# ------------------------------------------------------------------------------
# Do we need to model?
# ------------------------------------------------------------------------------

if (!file.exists(here("analysis/data/tmp/group_differences_main_full.rds")) || overwrite == TRUE) {
  brms_robust_group_diff <- readRDS(here("analysis/scripts/brms/brms_robust_group_diff.rds"))
  group_differences_main <-
  rbind(
    get_group_difference(merged_data, "general_disinhibition"),
    get_group_difference(merged_data, "nogo_accuracy"),
   
    get_group_difference(merged_data, "n2_windowed_amplitude"),
    get_group_difference(merged_data, "n2_moving_amplitude"),
    get_group_difference(merged_data, "n2_latency"),
    
    get_group_difference(merged_data, "p3_windowed_amplitude"),
    get_group_difference(merged_data, "p3_moving_amplitude"),
    get_group_difference(merged_data, "p3_latency"))

  group_differences_main_full <- 
    group_differences_main %>%
  mutate(
    mean_whole_group = mean,
    range_whole_group = range,
    mean_controls = mean.1,
    range_controls = range.1,
    mean_patients = mean.2,
    range_patients = range.2) %>%
  select(-c(mean, range, mean.1, range.1, mean.2, range.2))

  group_differences_main_formatted <- group_differences_main_full %>%
    mutate_if(is.numeric, round, 2) %>%
    mutate(diff = paste0(diff, " [", diff_lower_90, ", ", diff_upper_90, "]"),
           delta_est = paste0(delta_est, " [", delta_est_lower_90, ", ", delta_est_upper_90, "]"),
           p_direction = paste0(p_direction, "%")) %>%
    select(variable,
           mean_whole_group, range_whole_group,
           mean_controls, range_controls,
           mean_patients, range_patients,
           diff, delta_est, p_direction)

  saveRDS(group_differences_main_full, here("analysis/data/tmp/group_differences_main_full.rds"))
  saveRDS(group_differences_main_formatted, here("analysis/data/tmp/group_differences_main_formatted.rds"))
}

# ------------------------------------------------------------------------------
# Read and process data
# ------------------------------------------------------------------------------

group_differences_main_formatted <- readRDS(here("analysis/data/tmp/group_differences_main_formatted.rds")) %>%
  mutate(Measure = variable) %>%
  select(-variable)

group_differences_main_formatted$labels <- 
  c(as_paragraph("ESI-BF", as_sub("DIS")),
    as_paragraph("NoGo accuracy"),
    as_paragraph("NoGo N2", as_sub("WIN")),
    as_paragraph("NoGo N2", as_sub("MOV")),
    as_paragraph("NoGo N2 latency"),
    as_paragraph("NoGo P3", as_sub("WIN")),
    as_paragraph("NoGo P3", as_sub("MOV")),
    as_paragraph("NoGo P3 latency"))

# ------------------------------------------------------------------------------
# Create flextable
# ------------------------------------------------------------------------------

ft <- flextable(group_differences_main_formatted,
                col_keys = c("Measure", "mean_whole_group", "range_whole_group",
                             "mean_controls", "range_controls",
                             "mean_patients", "range_patients",
                             "diff", "delta_est", "p_direction")) %>%
  
  compose(part = "body", j = "Measure", value = labels) %>%
  
  compose(i = 1, j = "mean_whole_group", part = "header", value = as_paragraph("Mean ± SD")) %>%
  compose(i = 1, j = "mean_controls", part = "header", value = as_paragraph("Mean ± SD")) %>%
  compose(i = 1, j = "mean_patients", part = "header", value = as_paragraph("Mean ± SD")) %>%
  
  compose(i = 1, j = "range_whole_group", part = "header", value = as_paragraph("Range")) %>%
  compose(i = 1, j = "range_controls", part = "header", value = as_paragraph("Range")) %>%
  compose(i = 1, j = "range_patients", part = "header", value = as_paragraph("Range")) %>%
  
  compose(i = 1, j = "diff", part = "header", value = as_paragraph("Diff. [90% HDI]")) %>%
  compose(i = 1, j = "delta_est", part = "header", value = as_paragraph("δ", as_sub("est"), " [90% HDI]")) %>%
  compose(i = 1, j = "p_direction", part = "header", value = as_paragraph("P", as_sub("D"))) %>%

  add_header_row(top = TRUE, values = c("", "Whole sample", "Controls", "Patients", "Posterior estimates"), colwidths = c(1, 2, 2, 2, 3)) %>%
  
  align(align = "center", part = "all") %>%
  align(j = "Measure", align = "left", part = "all") %>%
  align(i = 1, align = "center", part = "header") %>%
  
  fontsize(size = 9, part = "header") %>%
  fontsize(size = 8, part = "body") %>%
  
  autofit()

# ------------------------------------------------------------------------------
# Save flextable
# ------------------------------------------------------------------------------

if (!file.exists(here("analysis/output/tables/table_2_group_differences_main.docx")) || overwrite == TRUE) {
  read_docx() %>%
    body_add_flextable(value = ft, split = FALSE) %>%
    body_end_section_landscape() %>% # a landscape section is ending here
    print(target = here("analysis/output/tables/table_2_group_differences_main.docx"))
}
