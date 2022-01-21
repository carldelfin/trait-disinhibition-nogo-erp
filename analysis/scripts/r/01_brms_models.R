if (!file.exists(here("analysis/scripts/brms/brms_robust_correlation.rds")) || overwrite_brms == TRUE) {
  
  # ------------------------------------------------------------------------------
  # Create dummy data frames
  # ------------------------------------------------------------------------------
  
  # for correlation models
  set.seed(seed)
  data_cor = 
    data.frame(x = rnorm(100),
               y = rnorm(100),
               covariate = rnorm(100))
  
  # for group difference models
  set.seed(seed)
  data_diff = 
    data.frame(variable_z = rnorm(100),
               covariate_z = rnorm(100),
               group = rep(c("control", "patient"), each = 50))
  
  # ------------------------------------------------------------------------------
  # Robust partial correlation
  # ------------------------------------------------------------------------------
  
  # brms_robust_partial_correlation <-
  #   brm(mvbind(x, y) ~ 0 + covariate,
  #       family = student,
  #       prior = c(
  #         set_prior("normal(0,10)", class = "b", coef = "covariate", resp = "x"),
  #         set_prior("normal(0,10)", class = "b", coef = "covariate", resp = "y"),
  #         set_prior("lkj_corr_cholesky(2)", class = "Lrescor"),
  #         set_prior("gamma(2,0.1)", class = "nu"),
  #         set_prior("cauchy(0,1)", class = "sigma", resp = "x"),
  #         set_prior("cauchy(0,1)", class = "sigma", resp = "y")),
  #       data = data_cor,
  #       iter = iter,
  #       cores = cores,
  #       chains = chains,
  #       warmup = warmup,
  #       seed = seed,
  #       refresh = refresh)
  
  # ------------------------------------------------------------------------------
  # Robust correlation
  # ------------------------------------------------------------------------------
  
  brms_robust_correlation <-
    brm(mvbind(x, y) ~ 0,
        family = student,
        prior = c(
          set_prior("lkj_corr_cholesky(2)", class = "Lrescor"),
          set_prior("gamma(2,0.1)", class = "nu"),
          set_prior("cauchy(0,1)", class = "sigma", resp = "x"),
          set_prior("cauchy(0,1)", class = "sigma", resp = "y")),
        data = data_cor,
        iter = iter,
        cores = cores,
        chains = chains,
        warmup = warmup,
        seed = seed,
        refresh = refresh)
  
  # ------------------------------------------------------------------------------
  # Robust group difference, with covariate
  # ------------------------------------------------------------------------------
  
  # brms_robust_group_diff <-
  #   brm(
  #     bf(variable_z ~ 0 + group + covariate_z,
  #        sigma ~ 0 + group),
  #     family = student,
  #     prior = c(
  #       set_prior("normal(0,10)", class = "b", coef = "covariate_z"),
  #       set_prior("normal(0,10)", class = "b", coef = "groupcontrol"),
  #       set_prior("normal(0,10)", class = "b", coef = "grouppatient"),
  #       set_prior("cauchy(0,1)", class = "b", dpar = "sigma"),
  #       set_prior("gamma(2, 0.1)", class = "nu")),
  #     data = data_diff,
  #     iter = iter,
  #     cores = cores,
  #     chains = chains,
  #     warmup = warmup,
  #     seed = seed,
  #     refresh = refresh)
  
  # ------------------------------------------------------------------------------
  # Robust group difference, without covariate
  # ------------------------------------------------------------------------------
  
  brms_robust_group_diff <-
    brm(
      bf(variable_z ~ 0 + group,
         sigma ~ 0 + group),
      family = student,
      prior = c(
        set_prior("normal(0,10)", class = "b", coef = "groupcontrol"),
        set_prior("normal(0,10)", class = "b", coef = "grouppatient"),
        set_prior("cauchy(0,1)", class = "b", dpar = "sigma"),
        set_prior("gamma(2, 0.1)", class = "nu")),
      data = data_diff,
      iter = iter,
      cores = cores,
      chains = chains,
      warmup = warmup,
      seed = seed,
      refresh = refresh)
  
  # ------------------------------------------------------------------------------
  # Save models
  # ------------------------------------------------------------------------------
  
  #saveRDS(brms_robust_partial_correlation, here("analysis/scripts/brms/brms_robust_partial_correlation.rds"))
  saveRDS(brms_robust_correlation, here("analysis/scripts/brms/brms_robust_correlation.rds"))
  saveRDS(brms_robust_group_diff, here("analysis/scripts/brms/brms_robust_group_diff.rds"))
  #saveRDS(brms_robust_group_diff_no_cov, here("analysis/scripts/brms/brms_robust_group_diff_no_cov.rds"))
}