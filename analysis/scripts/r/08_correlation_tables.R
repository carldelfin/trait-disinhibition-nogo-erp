# ------------------------------------------------------------------------------
# Read and process data
# ------------------------------------------------------------------------------

df <-
  cbind(readRDS(here("analysis/data/tmp/correlation_general_disinhibition_formatted.rds")),
        readRDS(here("analysis/data/tmp/correlation_nogo_accuracy_formatted.rds"))) %>%
  setNames(make.names(names(.), unique = TRUE)) %>% 
  mutate(Measure = variable_2) %>%
  select(-c(variable_2, variable_2.1))

df$labels <- 
  c(as_paragraph("NoGo N2", as_sub("WIN")),
    as_paragraph("NoGo N2", as_sub("MOV")),
    as_paragraph("NoGo N2 latency"),
    as_paragraph("NoGo P3", as_sub("WIN")),
    as_paragraph("NoGo P3", as_sub("MOV")),
    as_paragraph("NoGo P3 latency"))
# ------------------------------------------------------------------------------
# Create flextables
# ------------------------------------------------------------------------------

ft_main <- flextable(df,
                col_keys = c("Measure", "rho", "p_direction", "rho.1", "p_direction.1")) %>%
  compose(part = "body", j = "Measure", value = labels) %>%
  compose(i = 1, j = "rho", part = "header", value = as_paragraph("ρ [90% HDI]")) %>%
  compose(i = 1, j = "rho.1", part = "header", value = as_paragraph("ρ [90% HDI]")) %>%
  compose(i = 1, j = "p_direction", part = "header", value = as_paragraph("P", as_sub("D"))) %>%
  compose(i = 1, j = "p_direction.1", part = "header", value = as_paragraph("P", as_sub("D"))) %>%
  align(align = "center", part = "all") %>%
  align(j = "Measure", align = "left", part = "all") %>%
  align(i = 1, align = "center", part = "header") %>%
  
  add_header_row(top = TRUE, values = c("", "ESI-BF_DIS", "NoGo accuracy"), colwidths = c(1, 2, 2)) %>%
  
  align(align = "center", part = "all") %>%
  align(j = "Measure", align = "left", part = "all") %>%
  align(i = 1, align = "center", part = "header") %>%
  
  fontsize(size = 9, part = "header") %>%
  fontsize(size = 8, part = "body") %>%
  
  autofit()

# ------------------------------------------------------------------------------
# Save flextables
# ------------------------------------------------------------------------------

if (!file.exists(here("analysis/output/tables/table_3_correlations_main.docx")) || overwrite == TRUE) {
  read_docx() %>%
    body_add_flextable(value = ft_main, split = FALSE) %>%
    body_end_section_landscape() %>% # a landscape section is ending here
    print(target = here("analysis/output/tables/table_3_correlations_main.docx"))
}