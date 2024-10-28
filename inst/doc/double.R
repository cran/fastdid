## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(fastdid)
library(ggplot2)
library(data.table)
simdt <- sim_did(1e+04, 5, cov = "cont", hetero = "all", balanced = TRUE, seed = 1, 
                 second_cohort = TRUE, second_het = "no") #comfounding event
dt <- simdt$dt #dataset

#ground truth att
att <- simdt$att |> merge(dt[,.(w = .N),by = "G"], by = "G")
att[, event_time := time-G]
att <- att[event == 1,.(att = weighted.mean(attgt, w)), by = "event_time"]

## ----naive--------------------------------------------------------------------
naive_result <-fastdid(data = dt, 
                 timevar = "time", cohortvar = "G", unitvar = "unit", 
                 outcomevar = "y", result_type = "dynamic")
plot_did_dynamics(naive_result) + 
  geom_line(aes(y = att, x = event_time), 
            data = att, color = "red") + theme_bw()

## ----diag---------------------------------------------------------------------
dt[, D2 := time >= G2]
diag <- fastdid(data = dt, 
                 timevar = "time", cohortvar = "G", unitvar = "unit",
                 outcomevar = "D2", result_type = "dynamic")
plot_did_dynamics(diag) + theme_bw()

## ----double-------------------------------------------------------------------
double_result <-fastdid(data = dt, 
                 timevar = "time", cohortvar = "G", unitvar = "unit",
                 outcomevar = "y", result_type = "dynamic",
                 cohortvar2 = "G2", event_specific = TRUE)
plot_did_dynamics(double_result) + 
  geom_line(aes(y = att, x = event_time), 
            data = att, color = "red") + theme_bw()

## ----agg----------------------------------------------------------------------
double_result_ds <-fastdid(data = dt, 
                 timevar = "time", cohortvar = "G", unitvar = "unit",
                 outcomevar = "y", result_type = "dynamic_stagger",
                 cohortvar2 = "G2", event_specific = TRUE)

double_result_ggt <-fastdid(data = dt, 
                 timevar = "time", cohortvar = "G", unitvar = "unit",
                 outcomevar = "y", result_type = "group_group_time",
                 cohortvar2 = "G2", event_specific = TRUE)


