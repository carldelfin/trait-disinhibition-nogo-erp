axis_text_size <- 9
title_text_size <- 10
axis_title_size <- 11
subtitle_text_size <- 9
legend_text_size <- 9

# ------------------------------------------------------------------------------
# Boxplots
# ------------------------------------------------------------------------------

grouped_boxplot <- function(data, xaxis, yaxis, title, yaxistitle, ymin, ymax, minlim, scale) {
  plot <-
    ggplot(data, aes_string(x = xaxis, y = yaxis, color = xaxis, fill = xaxis)) +
    geom_boxplot(alpha = 0.5,
                 coef = 1.5,
                 outlier.shape = NA) +
    geom_jitter(position = position_jitter(0.2),
                
                
                alpha = 0.8) +
    labs(title = title) +
    scale_y_continuous(name = yaxistitle,
                       expand = c(0.02, 0),
                       limits = c(minlim, ymax),
                       breaks = seq(ymin, ymax, scale)) +
    scale_x_discrete(labels = c("Controls", "MDOs")) +
    theme_classic() +
    control_vs_patient +
    erp_colors +
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
          axis.title.x = element_blank(),
          axis.title.y = element_text(size = axis_title_size, color = "black",
                                      hjust = 0.5),
          axis.ticks.y = element_blank())
  return(plot)
}

set.seed(seed)
dis_box <- grouped_boxplot(merged_data, "group", "general_disinhibition", expression(paste("ESI-BF"[DIS])), expression(paste("ESI-BF"[DIS], " score")), 1, 55, -1, 10)
acc_box <- grouped_boxplot(merged_data, "group", "nogo_accuracy", "NoGo accuracy", "Proportion correct", 0, 1.02, 0, 0.2)

n2_win_amp <- grouped_boxplot(merged_data, "group", "n2_windowed_amplitude", expression(paste("NoGo N2"[WIN])), expression("Amplitude ("*mu*"V)"), -12, 8, -12, 4)
n2_mov_amp <- grouped_boxplot(merged_data, "group", "n2_moving_amplitude", expression(paste("NoGo N2"[MOV])), expression("Amplitude ("*mu*"V)"), -12, 8, -12, 4)
n2_lat <- grouped_boxplot(merged_data, "group", "n2_latency", "NoGo N2 latency", "Latency (ms)", 230, 270, 230, 5)

p3_win_amp <- grouped_boxplot(merged_data, "group", "p3_windowed_amplitude", expression(paste("NoGo P3"[WIN])), expression("Amplitude ("*mu*"V)"), -4, 12, -4, 4)
p3_mov_amp <- grouped_boxplot(merged_data, "group", "p3_moving_amplitude", expression(paste("NoGo P3"[MOV])), expression("Amplitude ("*mu*"V)"), -4, 12, -4, 4)
p3_lat <- grouped_boxplot(merged_data, "group", "p3_latency", "NoGo P3 latency", "Latency (ms)", 360, 430, 360, 10)

box_plots <- dis_box + n2_win_amp + n2_mov_amp + n2_lat + acc_box + p3_win_amp + p3_mov_amp + p3_lat + plot_layout(ncol = 4, nrow = 2)

figure_S1 <- box_plots + plot_annotation(tag_levels = "A")
ggsave(here("analysis/output/figures/figure_S1.svg"),
       plot = figure_S1, width = 180, height = 120, units = "mm", dpi = 600)
