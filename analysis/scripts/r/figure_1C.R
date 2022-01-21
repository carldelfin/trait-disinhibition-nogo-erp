# ------------------------------------------------------------------------------
# Figure 1C
# Diagnostic overview
# ------------------------------------------------------------------------------

categorical <- c("gray", "black")

axis_text_size <- 9
title_text_size <- 11
axis_title_size <- 12
subtitle_text_size <- 10
legend_text_size <- 10

# subset and process diagnostic data
primary_dx_count <- merged_data %>%
  filter(group == "patient") %>%
  select(primary_diagnosis)

primary_dx_count <- as.data.frame(table(unlist(primary_dx_count))) %>%
  mutate(dx = Var1,
         primary_count = Freq) %>%
  select(dx, primary_count)

additional_dx_count <- merged_data %>%
  filter(group == "patient") %>%
  select(additional_diagnosis_1,
         additional_diagnosis_2,
         additional_diagnosis_3,
         additional_diagnosis_4)

additional_dx_count <- as.data.frame(table(unlist(additional_dx_count))) %>%
  mutate(dx = Var1,
         additional_count = Freq) %>%
  select(dx, additional_count)

# creating merged data for plotting
dx_data <- merge(primary_dx_count, additional_dx_count, all = TRUE)
total <- rowSums(dx_data[, 2:3], na.rm = TRUE)
tmp <- data.frame(dx = dx_data$dx, total = total)

dx_data <- dx_data %>%
  melt() %>%
  #na.omit() %>%
  mutate(variable = as.factor(variable))

dx_data <- merge(dx_data, tmp, by = "dx")

diagnostic_plot <-
  ggplot(dx_data,
         aes(x = reorder(dx, total),
             y = value,
             fill = factor(variable,
                           levels = c("additional_count", "primary_count")))) +
  geom_bar(stat = "identity") +
  coord_flip() + 
  scale_y_continuous(name = "Number of MDOs",
                     expand = c(0.01, 0),
                     limits = c(0, 17),
                     breaks = seq(0, 17, 1)) +
  scale_fill_manual(name = "Diagnosis",
                    labels = c("Additional", "Primary"),
                    values = categorical) +
  labs(title = "Diagnostic overview") +
  theme_minimal() +
  theme(legend.position = c(0.8, 0.7),
        legend.background = element_rect(fill = "white",
                                         size = 0.5,
                                         linetype = "solid",
                                         colour = "black"),
        legend.margin = margin(-1.5, 0.5, 0.5, 0.5, unit = "mm"),
        legend.text = element_text(size = legend_text_size, color = "black"),
        legend.key.size = unit(0.8, "lines"),
        plot.title = element_text(hjust = 0.5, size = title_text_size, color = "black"),
        legend.title = element_blank(),
        axis.ticks = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank(),
        axis.text.x = element_text(size = axis_text_size, color = "black"),
        axis.text.y = element_text(size = axis_text_size, color = "black", hjust = 1, vjust = 0.5),
        axis.title.x = element_text(size = axis_text_size, color = "black", hjust = 0.5, vjust = 0.5),
        axis.title.y = element_blank(),
        axis.ticks.y = element_blank()) +
  guides(fill = guide_legend(reverse = TRUE))

figure_1C <- diagnostic_plot
ggsave(here("analysis/output/figures/figure_1C.svg"),
       plot = figure_1C, width = 180, height = 80, units = "mm", dpi = 600)
