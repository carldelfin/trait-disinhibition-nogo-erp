# ==============================================================================
# Helper functions
# Carl Delfin, January, 2020
#
# This script contains various helper functions. Feel free to use and modify
# as you wish. 
# ==============================================================================

# ------------------------------------------------------------------------------
# Read csv files while keeping filenames
# ------------------------------------------------------------------------------

read_csv_filename <- function(filename){
  ret <- read.csv(filename)
  ret$ID <- filename
  ret
}

# ------------------------------------------------------------------------------
# Log file reader
# ------------------------------------------------------------------------------

log_reader <- function(pattern) {
  sub_string <<- paste0(".*logs/(\\w+)_", substr(pattern, 2, 2), ".*")
  log <- list.files(
    path = here("preprocess", "output", "logs"),
    pattern = pattern,
    full.names = TRUE) %>%
    lapply(read_csv_filename) %>%
    lapply(transform, ID = gsub(sub_string, "\\1", ID)) %>%
    bind_rows() %>%
    select(-X)
  return(log)
}

log_reader("*filter_log.csv")

# ------------------------------------------------------------------------------
# 50% positive fractional area latency function, adapted to R from: 
# https://lindeloev.net/hej-verden/
# ------------------------------------------------------------------------------

frac_fun <- function(x, component) {
  if (component == "p3") {
    fractional_area <- which.min(abs(cumsum(x - min(x)) - (sum(x - min(x)) / 2)))
  } else if (component == "n2") {
    fractional_area <- which.min(abs(cumsum(x - max(x)) - (sum(x - max(x)) / 2)))
  }
  return(fractional_area)
}

# ------------------------------------------------------------------------------
# Spearman-Brown correction
# ------------------------------------------------------------------------------

sb_correction <- function(cor) {
  cor_sb = (2 * cor) / (1 + (2 - 1) * cor)
  return(cor_sb)
}

# ------------------------------------------------------------------------------
# Summarize posterior using specified method
# ------------------------------------------------------------------------------

summarize_posterior <- function(data) {
  df <- median_hdi(data, .width = c(0.90, 0.66))
  return(df)
}

# ------------------------------------------------------------------------------
# Apply Hedges's bias correction
# ------------------------------------------------------------------------------

hedges_bias_correction <- function(d, n1, n2) {
  d * (1 - (3 / ((4 * (n1 + n2)) - 1)))
}

# ------------------------------------------------------------------------------
# Calculate the reliability between odd and even trials
# ------------------------------------------------------------------------------

get_reliability <- function(data, variable) {
  
  variable_q <- enquo(variable)
  odd_variable = paste0(variable, "_odd")
  even_variable = paste0(variable, "_even")
  
  df = data.frame(x = scale(data[, odd_variable]),
                  y = scale(data[, even_variable])) %>%
    na.omit()
  
  mod = update(brms_robust_correlation,
               newdata = df,
               iter = iter,
               cores = cores,
               chains = chains,
               warmup = warmup,
               seed = seed,
               refresh = refresh)
  
  # process data
  tmp = 
    posterior_samples(mod) %>%
    mutate(rho = rescor__x__y) %>%
    select(rho)
  
  # probability of direction (in percent)
  if (sign(median(tmp[, "rho"])) == -1) {
    p_direction = round(mean(tmp[, "rho"] < 0) * 100, 0)
  } else if (sign(median(tmp[, "rho"])) == 1) {
    p_direction = round(mean(tmp[, "rho"] > 0) * 100, 0)
  }
  
  # summarize results
  results = 
    tmp %>%
    summarize_posterior() %>%
    slice(1) %>%
    mutate(variable := !!variable_q,
           rho_sb = sb_correction(rho),
           rho_sb_lower_90 = sb_correction(.lower),
           rho_sb_upper_90 = sb_correction(.upper),
           p_direction = p_direction) %>%
    select(variable, rho_sb, rho_sb_lower_90, rho_sb_upper_90, p_direction)
  
  return(results)
}

# ------------------------------------------------------------------------------
# Quantify ERP meaures
# ------------------------------------------------------------------------------

get_erp_measures <- function(data, lower_bound, upper_bound, component) {
  
  # crop data
  tmp <- data[data[, "time"] >= lower_bound & data[, "time"] <= upper_bound, ]
  
  # enqoute variable names for use with dplyr
  component_raw <- component
  component <- enquo(component)
  windowed_amplitude_name <- paste0(quo_name(component), "_windowed_amplitude")
  moving_amplitude_name <- paste0(quo_name(component), "_moving_amplitude")
  latency_name <- paste0(quo_name(component), "_latency")
  
  # get windowed amplitude
  df_win_amp <- aggregate(amplitude ~ ID + group,
                          data = tmp,
                          FUN = "mean") %>%
    mutate(!!windowed_amplitude_name := amplitude) %>%
    select(!!windowed_amplitude_name, ID)
  
  # get windowed latency
  latency <- vector()
  ID <- character()
  
  for (i in unique(tmp[, "ID"])) {
    df <- tmp[tmp[, "ID"] == i, ]
    ID[i] <- i
    latency[i] = frac_fun(df$amplitude, component_raw) + lower_bound
  }
  
  df_lat <- data.frame(latency, ID) %>%
    mutate(!!latency_name := latency) %>%
    select(!!latency_name, ID)
  
  # get moving window average
  ID <- character()
  mov_amp <- vector()
  
  for (i in unique(tmp[, "ID"])) {
    df <- data[data[, "ID"] == i, ]
    ID[i] <- i
    latency_data <- df_lat %>% filter(ID == i)
    latency = latency_data[[1]]
    latency_low = latency - 50
    latency_high = latency + 50
    
    cropped <- df[df[, "time"] >= latency_low & df[, "time"] <= latency_high, ]
    mov_amp[i] = mean(cropped[, "amplitude"])
  }
  
  df_mov_amp <- data.frame(mov_amp, ID) %>%
    mutate(!!moving_amplitude_name := mov_amp) %>%
    select(!!moving_amplitude_name, ID)
  
  results <- Reduce(function(x, y) merge(x, y, by = "ID", all = TRUE),
                    list(df_win_amp,
                         df_mov_amp,
                         df_lat))
  
  return(results)
}

# ------------------------------------------------------------------------------
# Calculate group difference, with covariate
# ------------------------------------------------------------------------------

# get_group_difference <- function(data, variable) {
#   
#   # descriptives
#   variable_q <- enquo(variable)
#   group_list <- c("whole", "controls", "patients")
#   descriptive_data_list <- list()
#   
#   for (i in group_list) {
#     if (i == "whole") {
#       tmp <- data %>%
#         select(!!variable_q) %>%
#         na.omit() %>%
#         summarise_each(list(mean = mean,
#                             sd = sd,
#                             min = min,
#                             max = max))
#     } else if (i == "controls") {
#       tmp <- data %>%
#         select(c("group", !!variable_q)) %>%
#         na.omit() %>%
#         filter(group == "control") %>%
#         select(-group) %>%
#         summarise_each(list(mean = mean,
#                             sd = sd,
#                             min = min,
#                             max = max))
#     } else if (i == "patients") {
#       tmp <- data %>%
#         select(c("group", !!variable_q)) %>%
#         na.omit() %>%
#         filter(group == "patient") %>%
#         select(-group) %>%
#         summarise_each(list(mean = mean,
#                             sd = sd,
#                             min = min,
#                             max = max))
#     }
#     
#     tmp <- 
#       tmp %>%
#       data.frame() %>%
#       mutate_if(is.numeric, round, 2) %>%
#       mutate(variable = variable,
#              mean = paste0(mean, " \u00B1 ", sd),
#              range = paste0(min, " - ", max)) %>%
#       select(variable, mean, range)
#     
#     descriptive_data_list[[i]] <- tmp
#   }
#   
#   # prepare data
#   data = 
#     data.frame(group = data[, "group"],
#                variable_z = scale(data[, variable]),
#                variable = data[, variable],
#                covariate_z = scale(data[, "age"])) %>%
#     na.omit()
#   
#   # run model
#   mod = 
#     update(brms_robust_group_diff,
#            newdata = data,
#            iter = iter,
#            cores = cores,
#            chains = chains,
#            warmup = warmup,
#            seed = seed,
#            refresh = refresh)
# 
#   # process data
#   tmp = 
#     posterior_samples(mod) %>%
#     
#     # exponentiate sigmas since they're on log scale by default
#     mutate_at(vars(contains("sigma")), funs(exp)) %>% 
#     mutate(
#       # un-scale group means
#       b_groupcontrol_norm = (b_groupcontrol * sd(data[, "variable"])) + mean(data[, "variable"]),
#       b_grouppatient_norm = (b_grouppatient * sd(data[, "variable"])) + mean(data[, "variable"]),
#       
#       # un-scale group sigmas
#       b_sigma_groupcontrol_norm = sd(data[, "variable"]) * b_sigma_groupcontrol,
#       b_sigma_grouppatient_norm = sd(data[, "variable"]) * b_sigma_grouppatient,
#       
#       # calculate differences
#       std_diff = b_grouppatient - b_groupcontrol,
#       diff = b_grouppatient_norm - b_groupcontrol_norm) %>%
#     
#     # bias-corrected standardized mean difference
#     mutate(
#       pooled_sd_n = ((length(which(data[, "group"] == "patient")) - 1) * (b_sigma_grouppatient_norm ** 2)) + ((length(which(data[, "group"] == "control")) - 1) * (b_sigma_groupcontrol_norm ** 2)),
#       pooled_sd_d = ((length(which(data[, "group"] == "patient")) + length(which(data[, "group"] == "control"))) - 2),
#       pooled_sd = sqrt(pooled_sd_n / pooled_sd_d),
#       cohens_ds = diff / pooled_sd,
#       delta_est = hedges_bias_correction(cohens_ds, length(which(data[, "group"] == "patient")), length(which(data[, "group"] == "control"))))
#   
#   # probability of direction (in percent)
#   if (sign(median(tmp[, "diff"])) == -1) {
#     p_direction = round(mean(tmp[, "diff"] < 0) * 100, 0)
#   } else if (sign(median(tmp[, "diff"])) == 1) {
#     p_direction = round(mean(tmp[, "diff"] > 0) * 100, 0)
#   }
#   
#   # summarize results
#   results = 
#     tmp %>%
#     summarize_posterior() 
#   
#   results = results %>%
#     reshape(idvar = names(results[1]), timevar = c(".width"), direction = "wide") %>%
#     mutate(
#       # standardized estimates
#       std_diff = std_diff.0.9,
#       std_diff_lower_90 = std_diff.lower.0.9,
#       std_diff_upper_90 = std_diff.upper.0.9,
#       std_diff_lower_66 = std_diff.lower.0.66,
#       std_diff_upper_66 = std_diff.upper.0.66,
#       
#       # estimates transformed back to original scale
#       diff = diff.0.9,
#       diff_lower_90 = diff.lower.0.9,
#       diff_upper_90 = diff.upper.0.9,
#       diff_lower_66 = diff.lower.0.66,
#       diff_upper_66 = diff.upper.0.66,
#       
#       # estimated unbiased standardized mean difference
#       delta_est = delta_est.0.9,
#       delta_est_lower_90 = delta_est.lower.0.9,
#       delta_est_upper_90 = delta_est.upper.0.9,
#       delta_est_lower_66 = delta_est.lower.0.66,
#       delta_est_upper_66 = delta_est.upper.0.66,
#       
#       # what are we modelling?
#       variable = variable,
#       
#       # probability of direction
#       p_direction = p_direction)  %>%
#     
#     select(variable,
#            std_diff, std_diff_lower_90, std_diff_upper_90, std_diff_lower_66, std_diff_upper_66,
#            diff, diff_lower_90, diff_upper_90, diff_lower_66, diff_upper_66,
#            delta_est, delta_est_lower_90, delta_est_upper_90, delta_est_lower_66, delta_est_upper_66,
#            p_direction)
#   
#   results <- 
#     cbind(descriptive_data_list[[1]],
#           descriptive_data_list[[2]],
#           descriptive_data_list[[3]],
#           results) %>%
#     setNames(make.names(names(.), unique = TRUE)) %>%
#     select(-c(4, 7, 10))
#   
#   return(results)
# }

# ------------------------------------------------------------------------------
#  Calculate group difference
# ------------------------------------------------------------------------------

get_group_difference <- function(data, variable) {
  
  # descriptives
  variable_q <- enquo(variable)
  group_list <- c("whole", "controls", "patients")
  descriptive_data_list <- list()
  
  for (i in group_list) {
    if (i == "whole") {
      tmp <- data %>%
        select(!!variable_q) %>%
        summarise_each(list(mean = mean,
                            sd = sd,
                            min = min,
                            max = max))
    } else if (i == "controls") {
      tmp <- data %>%
        select(c("group", !!variable_q)) %>%
        filter(group == "control") %>%
        select(-group) %>%
        summarise_each(list(mean = mean,
                            sd = sd,
                            min = min,
                            max = max))
    } else if (i == "patients") {
      tmp <- data %>%
        select(c("group", !!variable_q)) %>%
        filter(group == "patient") %>%
        select(-group) %>%
        summarise_each(list(mean = mean,
                            sd = sd,
                            min = min,
                            max = max))
    }
    
    tmp <- 
      tmp %>%
      data.frame() %>%
      mutate_if(is.numeric, round, 2) %>%
      mutate(variable = variable,
             mean = paste0(mean, " \u00B1 ", sd),
             range = paste0(min, " - ", max)) %>%
      select(variable, mean, range)
    
    descriptive_data_list[[i]] <- tmp
  }
  
  # prepare data
  data <- 
    data.frame(group = data[, "group"],
               variable = data[, variable],
               variable_z = scale(data[, variable])) %>%
    na.omit()
  
  
  # run model
  mod = 
    update(brms_robust_group_diff,
           newdata = data,
           iter = iter,
           cores = cores,
           chains = chains,
           warmup = warmup,
           seed = seed,
           refresh = refresh)

  # process data
  tmp = 
    posterior_samples(mod) %>%
    
    # exponentiate sigmas since they're on log scale by default
    mutate_at(vars(contains("sigma")), funs(exp)) %>% 
    mutate(
      # un-scale group means
      b_groupcontrol_norm = (b_groupcontrol * sd(data[, "variable"])) + mean(data[, "variable"]),
      b_grouppatient_norm = (b_grouppatient * sd(data[, "variable"])) + mean(data[, "variable"]),
      
      # un-scale group sigmas
      b_sigma_groupcontrol_norm = sd(data[, "variable"]) * b_sigma_groupcontrol,
      b_sigma_grouppatient_norm = sd(data[, "variable"]) * b_sigma_grouppatient,
      
      # calculate differences
      std_diff = b_grouppatient - b_groupcontrol,
      diff = b_grouppatient_norm - b_groupcontrol_norm) %>%
    
    # bias-corrected standardized mean difference
    mutate(
      pooled_sd_n = ((length(which(data[, "group"] == "patient")) - 1) * (b_sigma_grouppatient_norm ** 2)) + ((length(which(data[, "group"] == "control")) - 1) * (b_sigma_groupcontrol_norm ** 2)),
      pooled_sd_d = ((length(which(data[, "group"] == "patient")) + length(which(data[, "group"] == "control"))) - 2),
      pooled_sd = sqrt(pooled_sd_n / pooled_sd_d),
      cohens_ds = diff / pooled_sd,
      delta_est = hedges_bias_correction(cohens_ds, length(which(data[, "group"] == "patient")), length(which(data[, "group"] == "control"))))
  
  # probability of direction (in percent)
  if (sign(median(tmp[, "diff"])) == -1) {
    p_direction = round(mean(tmp[, "diff"] < 0) * 100, 0)
  } else if (sign(median(tmp[, "diff"])) == 1) {
    p_direction = round(mean(tmp[, "diff"] > 0) * 100, 0)
  }
  
  # summarize results
  results = 
    tmp %>%
    summarize_posterior() 
  
  results = results %>%
    reshape(idvar = names(results[1]), timevar = c(".width"), direction = "wide") %>%
    mutate(
      # standardized estimates
      std_diff = std_diff.0.9,
      std_diff_lower_90 = std_diff.lower.0.9,
      std_diff_upper_90 = std_diff.upper.0.9,
      std_diff_lower_66 = std_diff.lower.0.66,
      std_diff_upper_66 = std_diff.upper.0.66,
      
      # estimates transformed back to original scale
      diff = diff.0.9,
      diff_lower_90 = diff.lower.0.9,
      diff_upper_90 = diff.upper.0.9,
      diff_lower_66 = diff.lower.0.66,
      diff_upper_66 = diff.upper.0.66,
      
      # estimated unbiased standardized mean difference
      delta_est = delta_est.0.9,
      delta_est_lower_90 = delta_est.lower.0.9,
      delta_est_upper_90 = delta_est.upper.0.9,
      delta_est_lower_66 = delta_est.lower.0.66,
      delta_est_upper_66 = delta_est.upper.0.66,

      # what are we modelling?
      variable = variable,
      
      # probability of direction
      p_direction = p_direction) %>%
    
    select(variable,
           std_diff, std_diff_lower_90, std_diff_upper_90, std_diff_lower_66, std_diff_upper_66,
           diff, diff_lower_90, diff_upper_90, diff_lower_66, diff_upper_66,
           delta_est, delta_est_lower_90, delta_est_upper_90, delta_est_lower_66, delta_est_upper_66,
           p_direction)
  
  results <- 
    cbind(descriptive_data_list[[1]],
          descriptive_data_list[[2]],
          descriptive_data_list[[3]],
          results) %>%
    setNames(make.names(names(.), unique = TRUE)) %>%
    select(-c(4, 7, 10))
  
  return(results)
}

# ------------------------------------------------------------------------------
# Calcualte correlation
# ------------------------------------------------------------------------------

get_correlation <- function(data, variable_1, variable_2) {
  
  variable_1_q <- enquo(variable_1)
  variable_2_q <- enquo(variable_2)
  
  df = 
    data.frame(x = scale(data[, variable_1]),
               y = scale(data[, variable_2])) %>%
    na.omit()
  
  mod = update(brms_robust_correlation,
               newdata = df,
               iter = iter,
               cores = cores,
               chains = chains,
               warmup = warmup,
               seed = seed,
               refresh = refresh)
  
  # process data
  tmp = 
    posterior_samples(mod) %>%
    mutate(rho = rescor__x__y) %>%
    select(rho)
  
  # probability of direction (in percent)
  if (sign(median(tmp[, "rho"])) == -1) {
    p_direction = round(mean(tmp[, "rho"] < 0) * 100, 0)
  } else if (sign(median(tmp[, "rho"])) == 1) {
    p_direction = round(mean(tmp[, "rho"] > 0) * 100, 0)
  }

  # summarize results
  results = 
    tmp %>%
    summarize_posterior() 
  
  results = results %>%
    reshape(idvar = names(results[1]), timevar = c(".width"), direction = "wide") %>%
    mutate(
      rho_lower_90 = .lower.0.9,
      rho_upper_90 = .upper.0.9,
      rho_lower_66 = .lower.0.66,
      rho_upper_66 = .upper.0.66,
      
      # what are we modelling?
      variable_1 = variable_1,
      variable_2 = variable_2,
      
      # probability of direction
      p_direction = p_direction) %>%
    
    select(variable_1, variable_2,
           rho, rho_lower_90, rho_upper_90, rho_lower_66, rho_upper_66,
           p_direction)
  
  return(results)
}
