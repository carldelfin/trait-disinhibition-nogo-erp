axis_text_size <- 10
title_text_size <- 11
axis_title_size <- 12
subtitle_text_size <- 10
legend_text_size <- 10

# ------------------------------------------------------------------------------
# NoGo P3 waveform
# ------------------------------------------------------------------------------

eeg_data_aggregated <- readRDS(here("analysis/data/tmp/eeg_data_aggregated.rds"))

erp_plot <- ggplot(eeg_data_aggregated, aes(x = time, y = amplitude, color = group)) +
  geom_vline(xintercept = 0.29,
             color = "black",
             linetype = 2) +
  geom_vline(xintercept = 0.450,
             color = "black",
             linetype = 2) +
  geom_vline(xintercept = 0,
             color = "black",
             linetype = 2) +
  geom_line(alpha = 1,
            linetype = 1,
            size = 1) +
  annotate("segment",
           x = 0.37, xend = 0.32,
           y = -1.4, yend = -1.4,
           colour = "black",
           size = 0.8,
           lineend = "round",
           linejoin = "round",
           arrow = arrow(length = unit(1.5, "mm"))) +
  annotate("text", x = 0.46, y = -1.4, label = "NoGo N2", size = 3) +
  annotate("segment",
           x = 0.56, xend = 0.51,
           y = 7.1, yend = 7.1,
           colour = "black",
           size = 0.8,
           lineend = "round",
           linejoin = "round",
           arrow = arrow(length = unit(1.5, "mm"))) +
  annotate("text", x = 0.65, y = 7.1, label = "NoGo P3", size = 3) +
  scale_x_continuous(expand = c(0, 0),
                     breaks = seq(0, 0.8, 0.1)) +
  scale_y_continuous(breaks = seq(-2, 8, 1),
                     limits = c(-3, 8),
                     expand = c(0,0)) +
  theme_ridges(grid = FALSE) +
  labs(title = "The NoGo waveform",
       x = "Time (s)",
       y = expression("Amplitude ("*mu*"V)")) +
  erp_colors + 
  theme_classic() +
  theme(legend.position = c(0.35, 0.85),
        legend.background = element_rect(fill = "white",
                                         size = 0.5,
                                         linetype = "solid",
                                         colour = "white"),
        legend.key = element_rect(fill = NA, colour = NA),
        legend.key.size = unit(0.7, 'lines'),
        legend.title = element_blank(),
        legend.text = element_text(size = legend_text_size, color = "black", margin = margin(l = -5, unit = "pt")),
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
                                    hjust = 0.5))

ggsave(here("analysis/output/figures/erp_plot.svg"),
       plot = erp_plot, width = 140, height = 80, units = "mm", dpi = 600)