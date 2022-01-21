# ------------------------------------------------------------------------------
# Group differences
# ------------------------------------------------------------------------------

axis_text_size <- 10
title_text_size <- 11
axis_title_size <- 12
subtitle_text_size <- 10
legend_text_size <- 10

target_order <- c("general_disinhibition",
                  "nogo_accuracy",
                  "n2_windowed_amplitude",
                  "n2_moving_amplitude",
                  "n2_latency",
                  "p3_windowed_amplitude",
                  "p3_moving_amplitude",
                  "p3_latency")

df <- readRDS(here("analysis/data/tmp/group_differences_main_full.rds")) %>%
  arrange(factor(variable, levels = target_order))

df$variable <-
  factor(df$variable, levels = rev(target_order))

group_diff_plot <-
  df %>%
  ggplot(aes(x = variable, y = delta_est)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  geom_hline(yintercept = -0.2, linetype = "dashed", color = "black") +
  geom_hline(yintercept = 0.2, linetype = "dashed", color = "black") +
  geom_linerange(aes(ymin = delta_est_lower_66, ymax = delta_est_upper_66), size = 1.8) + 
  geom_linerange(aes(ymin = delta_est_lower_90, ymax = delta_est_upper_90), size = 0.8) + 
  geom_point(size = 2.5) +
  coord_flip() +
  scale_x_discrete(
    labels = rev(c(expression(paste("ESI-BF"[DIS])),
                   "NoGo accuracy",
                   expression(paste("NoGo N2"[WIN])),
                   expression(paste("NoGo N2"[MOV])),
                   "NoGo N2 latency",
                   expression(paste("NoGo P3"[WIN])),
                   expression(paste("NoGo P3"[MOV])),
                   "NoGo P3 latency"))) +
  scale_y_continuous(limits = c(-1.5, 2.5),
                     breaks = seq(-1.5, 2.5, 0.5),
                     labels = scales::label_number(accuracy = 0.1)) +
  labs(title = "Group differences",
       x = NULL) +
  ylab(expression(hat(delta))) +
  theme_classic() +
  theme(legend.text = element_blank(),
        legend.title = element_blank(),
        legend.position = "none",
        axis.text.x = element_text(size = axis_text_size,
                                   color = "black"),
        axis.text.y = element_text(size = axis_text_size,
                                   color = "black",
                                   vjust = 0.5),
        plot.title = element_text(size = title_text_size, hjust = 0.5, color = "black"),
        plot.subtitle = element_text(size = subtitle_text_size, color = "black"),
        axis.title.x = element_text(size = axis_title_size, color = "black",
                                    hjust = 0.5),
        axis.title.y = element_text(size = axis_title_size, color = "black",
                                    hjust = 0.5),
        axis.ticks.y = element_blank())

# ------------------------------------------------------------------------------
# Correlations
# ------------------------------------------------------------------------------

cor_plotter <- function(data, title) {
  
  df <- 
    data %>%
    select(variable_2,
           rho,
           rho_lower_90, rho_upper_90,
           rho_lower_66, rho_upper_66)
  
  labels <- unique(rev((df[, "variable_2"]))) %>%
    str_replace(., "n2_windowed_amplitude", "NoGo~N2[WIN]") %>%
    str_replace(., "n2_moving_amplitude", "NoGo~N2[MOV]") %>%
    str_replace(., "n2_latency", "NoGo~N2~latency") %>%
    str_replace(., "p3_windowed_amplitude", "NoGo~P3[WIN]") %>%
    str_replace(., "p3_moving_amplitude", "NoGo~P3[MOV]") %>%
    str_replace(., "p3_latency", "NoGo~P3~latency")
  
  plot <- df %>%
    ggplot(aes(y = variable_2, x = rho)) +
    geom_vline(xintercept = 0, linetype = "solid", color = "black") +
    geom_vline(xintercept = -0.1, linetype = "dashed", color = "black") +
    geom_vline(xintercept = 0.1, linetype = "dashed", color = "black") +
    geom_linerange(aes(xmin = rho_lower_66, xmax = rho_upper_66), size = 1.8) +
    geom_linerange(aes(xmin = rho_lower_90, xmax = rho_upper_90), size = 0.8) +
    geom_point(size = 2.5) +
    scale_x_continuous(expand = c(0, 0.06),
                       limits = c(-0.4, 0.6),
                       breaks = seq(-0.4, 0.6, 0.2),
                       labels = scales::label_number(accuracy = 0.1)) +
    scale_y_discrete(limits = unique(rev((df[, "variable_2"]))),
                     labels = parse(text = unique(labels))) +
    xlab(expression(rho)) +
    labs(title = title) +
    theme_classic() +
    theme_classic() +
    theme(legend.text = element_blank(),
          legend.title = element_blank(),
          legend.position = "none",
          axis.text.x = element_text(size = axis_text_size,
                                     color = "black"),
          axis.text.y = element_text(size = axis_text_size,
                                     color = "black",
                                     vjust = 0.5),
          plot.title = element_text(size = title_text_size, hjust = 0.5, color = "black"),
          plot.subtitle = element_text(size = subtitle_text_size, color = "black"),
          axis.title.x = element_text(size = axis_title_size, color = "black",
                                      hjust = 0.5),
          axis.title.y = element_blank(),
          axis.ticks.y = element_blank())
  
  return(plot)
}

correlation_general_disinhibition <- readRDS(here("analysis/data/tmp/correlation_general_disinhibition.rds"))
correlation_nogo_accuracy <- readRDS(here("analysis/data/tmp/correlation_nogo_accuracy.rds"))

cor_plot_dis <- cor_plotter(correlation_general_disinhibition, expression(paste("Correlations with ESI-BF"[DIS])))
cor_plot_nogo_acc <- cor_plotter(correlation_nogo_accuracy, "Correlations with NoGo accuracy")
cor_plot <- cor_plot_dis / cor_plot_nogo_acc

figure_3 <- group_diff_plot + cor_plot + plot_layout(widths = c(1, 1)) + plot_annotation(tag_levels = "A")
ggsave(here("analysis/output//figures/figure_3.svg"),
       plot = figure_3, width = 180, height = 120, units = "mm", dpi = 600)