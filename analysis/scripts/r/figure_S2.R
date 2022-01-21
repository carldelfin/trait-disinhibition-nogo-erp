axis_text_size <- 9
title_text_size <- 10
axis_title_size <- 11
subtitle_text_size <- 9
legend_text_size <- 9

# ------------------------------------------------------------------------------
# Scatterplots
# ------------------------------------------------------------------------------

grouped_scatterplot <- function(data, xaxis, yaxis, title, xaxistitle, yaxistitle) {
  plot <-
    ggplot(data, aes_string(x = xaxis, y = yaxis, color = data[, "group"], fill = data[, "group"])) +
    geom_point() +
    scale_x_continuous(name = xaxistitle) +
    scale_y_continuous(name = yaxistitle) +
    labs(title = title) +
    theme_classic() +
    control_vs_patient +
    erp_colors +
    theme(legend.text = element_blank(),
          legend.title = element_blank(),
          legend.position = "none",
          plot.title = element_text(size = title_text_size, hjust = 0.5, color = "black"),
          axis.text.x = element_text(size = axis_text_size, color = "black"),
          axis.text.y = element_text(size = axis_text_size, color = "black", vjust = 0.5),
          axis.title.x = element_text(size = axis_title_size, color = "black", hjust = 0.5),
          axis.title.y = element_text(size = axis_title_size, color = "black", hjust = 0.5))
  return(plot)
}

# ------------------------------------------------------------------------------
set.seed(999)
gen_dis_n2_win_amp <- 
  grouped_scatterplot(merged_data,
                      "general_disinhibition",
                      "n2_windowed_amplitude",
                      "",
                      expression(paste("ESI-BF"[DIS], " score")),
                      expression(paste("NoGo N2"[WIN])))

gen_dis_n2_mov_amp <- 
  grouped_scatterplot(merged_data,
                      "general_disinhibition",
                      "n2_moving_amplitude",
                      "",
                      expression(paste("ESI-BF"[DIS], " score")),
                      expression(paste("NoGo N2"[MOV])))

gen_dis_n2_lat <- 
  grouped_scatterplot(merged_data,
                      "general_disinhibition",
                      "n2_latency",
                      "",
                      expression(paste("ESI-BF"[DIS], " score")),
                      expression(paste("NoGo N2 latency")))

gen_dis_p3_win_amp <- 
  grouped_scatterplot(merged_data,
                      "general_disinhibition",
                      "p3_windowed_amplitude",
                      "",
                      expression(paste("ESI-BF"[DIS], " score")),
                      expression(paste("NoGo P3"[WIN])))

gen_dis_p3_mov_amp <- 
  grouped_scatterplot(merged_data,
                      "general_disinhibition",
                      "p3_moving_amplitude",
                      "",
                      expression(paste("ESI-BF"[DIS], " score")),
                      expression(paste("NoGo P3"[MOV])))

gen_dis_p3_lat <- 
  grouped_scatterplot(merged_data,
                      "general_disinhibition",
                      "p3_latency",
                      "",
                      expression(paste("ESI-BF"[DIS], " score")),
                      expression(paste("NoGo P3 latency")))
# ------------------------------------------------------------------------------

set.seed(999)
nogo_acc_n2_win_amp <- 
  grouped_scatterplot(merged_data,
                      "nogo_accuracy",
                      "n2_windowed_amplitude",
                      "",
                      expression(paste("NoGo accuracy")),
                      expression(paste("NoGo N2"[WIN])))

nogo_acc_n2_mov_amp <- 
  grouped_scatterplot(merged_data,
                      "nogo_accuracy",
                      "n2_moving_amplitude",
                      "",
                      expression(paste("NoGo accuracy")),
                      expression(paste("NoGo N2"[MOV])))

nogo_acc_n2_lat <- 
  grouped_scatterplot(merged_data,
                      "nogo_accuracy",
                      "n2_latency",
                      "",
                      expression(paste("NoGo accuracy")),
                      expression(paste("NoGo N2 latency")))

nogo_acc_p3_win_amp <- 
  grouped_scatterplot(merged_data,
                      "nogo_accuracy",
                      "p3_windowed_amplitude",
                      "",
                      expression(paste("NoGo accuracy")),
                      expression(paste("NoGo P3"[WIN])))

nogo_acc_p3_mov_amp <- 
  grouped_scatterplot(merged_data,
                      "nogo_accuracy",
                      "p3_moving_amplitude",
                      "",
                      expression(paste("NoGo accuracy")),
                      expression(paste("NoGo P3"[MOV])))

nogo_acc_p3_lat <- 
  grouped_scatterplot(merged_data,
                      "nogo_accuracy",
                      "p3_latency",
                      "",
                      expression(paste("NoGo accuracy")),
                      expression(paste("NoGo P3 latency")))
# ------------------------------------------------------------------------------

dis_scatter_plots <-
  gen_dis_n2_win_amp + gen_dis_n2_mov_amp + gen_dis_n2_lat +
  gen_dis_p3_win_amp + gen_dis_p3_mov_amp + gen_dis_p3_lat + plot_layout(ncol = 3, nrow = 2)

nogo_acc_scatter_plots <-
  nogo_acc_n2_win_amp + nogo_acc_n2_mov_amp + nogo_acc_n2_lat +
  nogo_acc_p3_win_amp + nogo_acc_p3_mov_amp + nogo_acc_p3_lat + plot_layout(ncol = 3, nrow = 2)

figure_S2 <- dis_scatter_plots / nogo_acc_scatter_plots + plot_layout(widths = c(1, 1)) + plot_annotation(tag_levels = "A")
ggsave(here("analysis/output/figures/figure_S2.svg"),
       plot = figure_S2, width = 180, height = 200, units = "mm", dpi = 600)