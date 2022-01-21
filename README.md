# Trait disinhibition and NoGo event-related potentials in violent mentally disordered offenders and healthy controls

---

## Overview

This repository contains all analysis code used for the manuscript subsequently published as [Trait disinhibition and NoGo event-related potentials in violent mentally disordered offenders and healthy controls](https://www.frontiersin.org/articles/10.3389/fpsyt.2020.577491/full). Feel free to use and/or modify any code in this repository for your own research.

---

## Software used

### Bash

[Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) is a Unix shell language used to interact with the computer. A Bash script (`preprocess.sh`) was used to run the EEG preprocessing scripts (themselves written in Python).

### Presentation

[Presentation](https://www.neurobs.com) (Neurobehavioral Systems Inc.) is a stimulus delivery and experiment control program. Presentation was used to create and run the Go/NoGo task, and to send triggers to the EEG acquisition hardware. The code for the Go/NoGo task is available in the `paradigm` folder.

### Python

[Python](https://www.python.org/) is a free, open source, general-purpose, high-level programming language. There are several so-called modules written for Python, which, for instance, contain various functions. Python and the [MNE-Python](https://mne.tools/stable/index.html) module was used for EEG data preprocessing.

### R

[R](https://www.r-project.org/) is a free, open source, programming language primarily used for statistical modeling and analysis. R was used for data preparation and statistical analysis.

### Stan and brms

[Stan](https://mc-stan.org/) is a free, open source, probabilistic programming language used for statistical inference and high-performance statistical computation. Stan was interfaced with R via the [brms](https://paul-buerkner.github.io/brms/) package, together used for Bayesian statistical analysis.

---

## Data availability

Due to lack of explicit consent on behalf of the participants, we are unfortunately not able to share the data publicly. Requests for data may be sent to *carl.delfin [at] gu.se*.

---

## EEG data preprocessing

All Python code used is found in the `preprocessing` folder. Preprocessing was carried out running 12 cores in parallel on a 12 core/24 thread AMD Ryzen 3900X workstation with 64 GB of 3600 MHz RAM. Most of the preprocessing time is dedicated to running [Autoreject](https://autoreject.github.io/).

The final run was carried out on 2020-05-13 using the following environment and system specifications:

```bash
-----
autoreject  0.2.1
matplotlib  3.2.1
mne         0.20.4
numpy       1.18.4
pandas      1.0.3
sinfo       0.3.1
-----
Python 3.8.2 (default, Apr 27 2020, 15:53:34) [GCC 9.3.0]
Linux-5.4.0-7625-generic-x86_64-with-glibc2.29
24 logical CPU cores, x86_64
-----
Session information updated at 2020-05-13 09:16
```

```bash
Linux kernel:
Linux version 5.4.0-7625-generic (buildd@lcy01-amd64-015) (gcc version 9.3.0 (Ubuntu 9.3.0-10ubuntu2)) #29~1587437458~20.04~2960161-Ubuntu SMP Tue Apr 21 05:16:44 UTC 

CPU:
Architecture:                    x86_64
CPU op-mode(s):                  32-bit, 64-bit
Byte Order:                      Little Endian
Address sizes:                   43 bits physical, 48 bits virtual
CPU(s):                          24
On-line CPU(s) list:             0-23
Thread(s) per core:              2
Core(s) per socket:              12
Socket(s):                       1
NUMA node(s):                    1
Vendor ID:                       AuthenticAMD
CPU family:                      23
Model:                           113
Model name:                      AMD Ryzen 9 3900X 12-Core Processor
Stepping:                        0
Frequency boost:                 enabled
CPU MHz:                         2116.134
CPU max MHz:                     3800.0000
CPU min MHz:                     2200.0000
BogoMIPS:                        7586.39
Virtualization:                  AMD-V
L1d cache:                       384 KiB
L1i cache:                       384 KiB
L2 cache:                        6 MiB
L3 cache:                        64 MiB
NUMA node0 CPU(s):               0-23
Vulnerability Itlb multihit:     Not affected
Vulnerability L1tf:              Not affected
Vulnerability Mds:               Not affected
Vulnerability Meltdown:          Not affected
Vulnerability Spec store bypass: Mitigation; Speculative Store Bypass disabled via prctl and seccomp
Vulnerability Spectre v1:        Mitigation; usercopy/swapgs barriers and __user pointer sanitization
Vulnerability Spectre v2:        Mitigation; Full AMD retpoline, IBPB conditional, STIBP conditional, RSB filling
Vulnerability Tsx async abort:   Not affected
Flags:                           fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate sme ssbd mba sev ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif umip rdpid overflow_recov succor smca
```

### Statistical analysis
---

The analysis is detailed in `analysis/analysis.Rmd`, which is knitted to a Word document containing all results. Quite a few helper functions and scripts are sourced in `analysis.Rmd`, please see `analysis/scripts`. The final run was carried out on 2020-05-13 using the following R environment:

```bash
 ─ Session info ───────────────────────────────────────────────────────────────
  setting  value                       
  version  R version 4.0.0 (2020-04-24)
  os       Pop!_OS 20.04 LTS           
  system   x86_64, linux-gnu           
  ui       X11                         
  language en_US:en                    
  collate  en_US.UTF-8                 
  ctype    en_US.UTF-8                 
  tz       Europe/Stockholm            
  date     2020-05-13                  
 
 ─ Packages ───────────────────────────────────────────────────────────────────
  package        * version   date       lib source        
  abind            1.4-5     2016-07-21 [1] CRAN (R 4.0.0)
  arrayhelpers     1.1-0     2020-02-04 [1] CRAN (R 4.0.0)
  assertthat       0.2.1     2019-03-21 [1] CRAN (R 4.0.0)
  backports        1.1.6     2020-04-05 [1] CRAN (R 4.0.0)
  base64enc        0.1-3     2015-07-28 [1] CRAN (R 4.0.0)
  bayesplot        1.7.1     2019-12-01 [1] CRAN (R 4.0.0)
  bridgesampling   1.0-0     2020-02-26 [1] CRAN (R 4.0.0)
  brms           * 2.12.0    2020-02-23 [1] CRAN (R 4.0.0)
  Brobdingnag      1.2-6     2018-08-13 [1] CRAN (R 4.0.0)
  broom          * 0.5.6     2020-04-20 [1] CRAN (R 4.0.0)
  callr            3.4.3     2020-03-28 [1] CRAN (R 4.0.0)
  cellranger       1.1.0     2016-07-27 [1] CRAN (R 4.0.0)
  cli              2.0.2     2020-02-28 [1] CRAN (R 4.0.0)
  coda             0.19-3    2019-07-05 [1] CRAN (R 4.0.0)
  codetools        0.2-16    2018-12-24 [4] CRAN (R 4.0.0)
  colorspace       1.4-1     2019-03-18 [1] CRAN (R 4.0.0)
  colourpicker     1.0       2017-09-27 [1] CRAN (R 4.0.0)
  crayon           1.3.4     2017-09-16 [1] CRAN (R 4.0.0)
  crosstalk        1.1.0.1   2020-03-13 [1] CRAN (R 4.0.0)
  data.table       1.12.8    2019-12-09 [1] CRAN (R 4.0.0)
  DBI              1.1.0     2019-12-15 [1] CRAN (R 4.0.0)
  dbplyr           1.4.3     2020-04-19 [1] CRAN (R 4.0.0)
  desc             1.2.0     2018-05-01 [1] CRAN (R 4.0.0)
  devtools       * 2.3.0     2020-04-10 [1] CRAN (R 4.0.0)
  digest           0.6.25    2020-02-23 [1] CRAN (R 4.0.0)
  dplyr          * 0.8.5     2020-03-07 [1] CRAN (R 4.0.0)
  DT               0.13      2020-03-23 [1] CRAN (R 4.0.0)
  dygraphs         1.1.1.6   2018-07-11 [1] CRAN (R 4.0.0)
  ellipsis         0.3.0     2019-09-20 [1] CRAN (R 4.0.0)
  evaluate         0.14      2019-05-28 [1] CRAN (R 4.0.0)
  fansi            0.4.1     2020-01-08 [1] CRAN (R 4.0.0)
  farver           2.0.3     2020-01-16 [1] CRAN (R 4.0.0)
  fastmap          1.0.1     2019-10-08 [1] CRAN (R 4.0.0)
  flextable      * 0.5.9     2020-03-06 [1] CRAN (R 4.0.0)
  forcats        * 0.5.0     2020-03-01 [1] CRAN (R 4.0.0)
  fs               1.4.1     2020-04-04 [1] CRAN (R 4.0.0)
  gdtools        * 0.2.2     2020-04-03 [1] CRAN (R 4.0.0)
  generics         0.0.2     2018-11-29 [1] CRAN (R 4.0.0)
  ggplot2        * 3.3.0     2020-03-05 [1] CRAN (R 4.0.0)
  ggridges       * 0.5.2     2020-01-12 [1] CRAN (R 4.0.0)
  glue             1.4.0     2020-04-03 [1] CRAN (R 4.0.0)
  GPArotation    * 2014.11-1 2014-11-25 [1] CRAN (R 4.0.0)
  gridExtra        2.3       2017-09-09 [1] CRAN (R 4.0.0)
  gtable           0.3.0     2019-03-25 [1] CRAN (R 4.0.0)
  gtools           3.8.2     2020-03-31 [1] CRAN (R 4.0.0)
  haven            2.2.0     2019-11-08 [1] CRAN (R 4.0.0)
  HDInterval       0.2.0     2018-06-09 [1] CRAN (R 4.0.0)
  here           * 0.1       2017-05-28 [1] CRAN (R 4.0.0)
  hms              0.5.3     2020-01-08 [1] CRAN (R 4.0.0)
  htmltools        0.4.0     2019-10-04 [1] CRAN (R 4.0.0)
  htmlwidgets      1.5.1     2019-10-08 [1] CRAN (R 4.0.0)
  httpuv           1.5.2     2019-09-11 [1] CRAN (R 4.0.0)
  httr             1.4.1     2019-08-05 [1] CRAN (R 4.0.0)
  igraph           1.2.5     2020-03-19 [1] CRAN (R 4.0.0)
  inline           0.3.15    2018-05-18 [1] CRAN (R 4.0.0)
  jsonlite         1.6.1     2020-02-02 [1] CRAN (R 4.0.0)
  knitr            1.28      2020-02-06 [1] CRAN (R 4.0.0)
  labeling         0.3       2014-08-23 [1] CRAN (R 4.0.0)
  later            1.0.0     2019-10-04 [1] CRAN (R 4.0.0)
  lattice          0.20-41   2020-04-02 [4] CRAN (R 4.0.0)
  lifecycle        0.2.0     2020-03-06 [1] CRAN (R 4.0.0)
  loo              2.2.0     2019-12-19 [1] CRAN (R 4.0.0)
  lubridate        1.7.8     2020-04-06 [1] CRAN (R 4.0.0)
  magrittr         1.5       2014-11-22 [1] CRAN (R 4.0.0)
  markdown         1.1       2019-08-07 [1] CRAN (R 4.0.0)
  Matrix           1.2-18    2019-11-27 [4] CRAN (R 4.0.0)
  matrixStats      0.56.0    2020-03-13 [1] CRAN (R 4.0.0)
  memoise          1.1.0     2017-04-21 [1] CRAN (R 4.0.0)
  mime             0.9       2020-02-04 [1] CRAN (R 4.0.0)
  miniUI           0.1.1.1   2018-05-18 [1] CRAN (R 4.0.0)
  mnormt           1.5-7     2020-04-30 [1] CRAN (R 4.0.0)
  modelr           0.1.7     2020-04-30 [1] CRAN (R 4.0.0)
  munsell          0.5.0     2018-06-12 [1] CRAN (R 4.0.0)
  mvtnorm          1.1-0     2020-02-24 [1] CRAN (R 4.0.0)
  nlme             3.1-147   2020-04-13 [4] CRAN (R 4.0.0)
  officer        * 0.3.9     2020-05-04 [1] CRAN (R 4.0.0)
  pander         * 0.6.3     2018-11-06 [1] CRAN (R 4.0.0)
  patchwork      * 1.0.0     2019-12-01 [1] CRAN (R 4.0.0)
  pillar           1.4.4     2020-05-05 [1] CRAN (R 4.0.0)
  pkgbuild         1.0.8     2020-05-07 [1] CRAN (R 4.0.0)
  pkgconfig        2.0.3     2019-09-22 [1] CRAN (R 4.0.0)
  pkgload          1.0.2     2018-10-29 [1] CRAN (R 4.0.0)
  plyr             1.8.6     2020-03-03 [1] CRAN (R 4.0.0)
  prettyunits      1.1.1     2020-01-24 [1] CRAN (R 4.0.0)
  processx         3.4.2     2020-02-09 [1] CRAN (R 4.0.0)
  promises         1.1.0     2019-10-04 [1] CRAN (R 4.0.0)
  ps               1.3.3     2020-05-08 [1] CRAN (R 4.0.0)
  psych          * 1.9.12.31 2020-01-08 [1] CRAN (R 4.0.0)
  purrr          * 0.3.4     2020-04-17 [1] CRAN (R 4.0.0)
  R6               2.4.1     2019-11-12 [1] CRAN (R 4.0.0)
  Rcpp           * 1.0.4.6   2020-04-09 [1] CRAN (R 4.0.0)
  readr          * 1.3.1     2018-12-21 [1] CRAN (R 4.0.0)
  readxl           1.3.1     2019-03-13 [1] CRAN (R 4.0.0)
  remotes          2.1.1     2020-02-15 [1] CRAN (R 4.0.0)
  reprex           0.3.0     2019-05-16 [1] CRAN (R 4.0.0)
  reshape2       * 1.4.4     2020-04-09 [1] CRAN (R 4.0.0)
  rlang            0.4.6     2020-05-02 [1] CRAN (R 4.0.0)
  rmarkdown        2.1       2020-01-20 [1] CRAN (R 4.0.0)
  rprojroot        1.3-2     2018-01-03 [1] CRAN (R 4.0.0)
  rsconnect        0.8.16    2019-12-13 [1] CRAN (R 4.0.0)
  rstan          * 2.19.3    2020-02-11 [1] CRAN (R 4.0.0)
  rstantools       2.0.0     2019-09-15 [1] CRAN (R 4.0.0)
  rstudioapi       0.11      2020-02-07 [1] CRAN (R 4.0.0)
  rvest            0.3.5     2019-11-08 [1] CRAN (R 4.0.0)
  scales         * 1.1.1     2020-05-11 [1] CRAN (R 4.0.0)
  sessioninfo      1.1.1     2018-11-05 [1] CRAN (R 4.0.0)
  shiny            1.4.0.2   2020-03-13 [1] CRAN (R 4.0.0)
  shinyjs          1.1       2020-01-13 [1] CRAN (R 4.0.0)
  shinystan        2.5.0     2018-05-01 [1] CRAN (R 4.0.0)
  shinythemes      1.1.2     2018-11-06 [1] CRAN (R 4.0.0)
  StanHeaders    * 2.19.2    2020-02-11 [1] CRAN (R 4.0.0)
  stringi          1.4.6     2020-02-17 [1] CRAN (R 4.0.0)
  stringr        * 1.4.0     2019-02-10 [1] CRAN (R 4.0.0)
  svglite          1.2.3     2020-02-07 [1] CRAN (R 4.0.0)
  svUnit           1.0.3     2020-04-20 [1] CRAN (R 4.0.0)
  systemfonts      0.2.1     2020-04-29 [1] CRAN (R 4.0.0)
  testthat       * 2.3.2     2020-03-02 [1] CRAN (R 4.0.0)
  threejs          0.3.3     2020-01-21 [1] CRAN (R 4.0.0)
  tibble         * 3.0.1     2020-04-20 [1] CRAN (R 4.0.0)
  tidybayes      * 2.0.3     2020-04-04 [1] CRAN (R 4.0.0)
  tidyr          * 1.0.3     2020-05-07 [1] CRAN (R 4.0.0)
  tidyselect       1.1.0     2020-05-11 [1] CRAN (R 4.0.0)
  tidyverse      * 1.3.0     2019-11-21 [1] CRAN (R 4.0.0)
  usethis        * 1.6.1     2020-04-29 [1] CRAN (R 4.0.0)
  uuid             0.1-4     2020-02-26 [1] CRAN (R 4.0.0)
  vctrs            0.3.0     2020-05-11 [1] CRAN (R 4.0.0)
  withr            2.2.0     2020-04-20 [1] CRAN (R 4.0.0)
  xfun             0.13      2020-04-13 [1] CRAN (R 4.0.0)
  xml2             1.3.2     2020-04-23 [1] CRAN (R 4.0.0)
  xtable           1.8-4     2019-04-21 [1] CRAN (R 4.0.0)
  xts              0.12-0    2020-01-19 [1] CRAN (R 4.0.0)
  yaml             2.2.1     2020-02-01 [1] CRAN (R 4.0.0)
  zip              2.0.4     2019-09-01 [1] CRAN (R 4.0.0)
  zoo              1.8-8     2020-05-02 [1] CRAN (R 4.0.0)
 
 [1] /home/cmd/R/x86_64-pc-linux-gnu-library/4.0
 [2] /usr/local/lib/R/site-library
 [3] /usr/lib/R/site-library
 [4] /usr/lib/R/library
 ```
