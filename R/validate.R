validate_argument <- function(dt, p) {
  if (!p$validate) {
    return(NULL)
  }

  dt_names <- names(dt)

  # release p
  for (name in names(p)) {
    assign(name, p[[name]])
  }

  name_message <- "__ARG__ must be a character scalar and a name of a column from the dataset."
  check_set_arg(timevar, unitvar, cohortvar, "match", .choices = dt_names, .message = name_message, .up = 1)

  covariate_message <- "__ARG__ must be NA or a character vector which are all names of columns from the dataset."
  check_set_arg(varycovariatesvar, covariatesvar, outcomevar,
    "NA | multi match",
    .choices = dt_names, .message = covariate_message, .up = 1
  )

  checkvar_message <- "__ARG__ must be NA or a character scalar if a name of columns from the dataset."
  check_set_arg(weightvar, clustervar, "NA | match", .choices = dt_names, .message = checkvar_message, .up = 1)

  check_set_arg(control_option, double_control_option, "match", .choices = c("both", "never", "notyet"), .up = 1) # kinda bad names since did's notyet include both notyet and never
  check_set_arg(control_type, "match", .choices = c("ipw", "reg", "dr"), .up = 1)
  check_set_arg(base_period, "match", .choices = c("varying", "universal"), .up = 1)
  check_arg(copy, validate, boot, allow_unbalance_panel, cband, parallel, "scalar logical", .up = 1)
  check_arg(anticipation, anticipation2, alpha, "scalar numeric", .up = 1)

  if (!is.na(balanced_event_time)) {
    if (result_type != "dynamic") {
      stop("balanced_event_time is only meaningful with result_type == 'dynamic'")
    }
    check_arg(balanced_event_time, "numeric scalar", .up = 1)
  }
  if (allow_unbalance_panel == TRUE & control_type == "dr") {
    stop("fastdid does not support DR when allowing for unbalanced panels.")
  }
  # if(allow_unbalance_panel == TRUE & !allNA(varycovariatesvar)){
  #   stop("fastdid currently only supprts time varying covariates when not allowing for unbalanced panels.")
  # }
  if (any(covariatesvar %in% varycovariatesvar) & !allNA(varycovariatesvar) & !allNA(covariatesvar)) {
    stop("time-varying var and invariant var have overlaps.")
  }
  if (!boot & (!allNA(clustervar) | cband == TRUE)) {
    stop("clustering and uniform confidence interval only available with bootstrap")
  }

  if (parallel) {
    if (.Platform$OS.type != "unix") {
      stop("parallel option only available on unix sysytems")
    }
    if (!requireNamespace("parallel")) {
      stop("parallel requires the parallel package")
    }
  }

  # varname collision
  varnames <- unlist(p[str_subset(names(p), "var")])
  varnames <- varnames[!is.na(varnames)]
  if (any(duplicated(varnames))) {
    stop("-var arguments can not have duplicated names. (no need to specicify cluster on unit-level, it is automatically done.)")
  }
}

validate_dt <- function(dt, p) {
  varnames <- unlist(p[str_ends(names(p), "var")], recursive = TRUE) # get all the argument that ends with "var"
  varnames <- varnames[!varnames %in% c(p$timevar, p$unitvar, p$cohortvar) & !is.na(varnames) & !is.null(varnames)]

  # change to int
  uniquecols <- c("G", "time", "unit")
  for (col in uniquecols) {
    if (!dt[, is.numeric(get(col))]) {
      stop(col, " needs to be numeric.")
    }
    dt[!is.infinite(get(col)), c(col) := as.integer(get(col))] # yeah sometimes floating point can be annoying
  }

  raw_unit_size <- dt[, uniqueN(unit)]
  raw_time_size <- dt[, uniqueN(time)]

  if (!is.na(p$balanced_event_time)) {
    if (p$balanced_event_time > dt[, max(time - G)]) {
      stop("balanced_event_time is larger than the max event time in the data")
    }
  }

  # doesn't allow missing value
  if (is.na(p$exper$only_balance_2by2) | !p$exper$only_balance_2by2) {
    for (col in varnames) {
      na_obs <- whichNA(dt[, get(col)])
      if (length(na_obs) != 0) {
        warning("missing values detected in ", col, ", removing ", length(na_obs), " observation.")
        dt <- dt[!na_obs]
      }
    }
  }

  if (!allNA(p$covariatesvar) && uniqueN(dt, by = c("unit", p$covariatesvar)) > raw_unit_size) {
    warning("some covariates is time-varying, fastdid only use the first observation for covariates.")
  }


  if (!allNA(p$covariatesvar) | !allNA(p$varycovariatesvar)) {
    for (cov in c(p$covariatesvar, p$varycovariatesvar)) {
      if (is.na(cov)) {
        next
      }
      # check covaraites is not constant
      if (fnunique(dt[, get(cov)[1], by = "unit"][, V1]) == 1) stop(cov, " have no variation")
      if (!(is.numeric(dt[, get(cov)]) | is.integer(dt[, get(cov)]))) {
        stop(cov, " is not numeric or integer, do not support fixed effects.")
      }
    }
  }

  # check balanced panel
  # check if any is dup
  if (anyDuplicated(dt[, .(unit, time)])) {
    dup_id <- dt[duplicated(dt[, .(unit, time)]), unique(unit)]
    stop(length(dup_id), " units is observed more than once in a period.")
  }

  # check if any is missing
  if (!p$allow_unbalance_panel) {
    unit_count <- dt[, .(count = .N), by = unit]
    if (any(unit_count[, count < raw_time_size])) {
      mis_unit <- unit_count[count < raw_time_size]
      warning(nrow(mis_unit), " units is missing in some periods, enforcing balanced panel by dropping them")
      dt <- dt[!unit %in% mis_unit[, unit]]
    }
  }

  # drop always_treated units
  always_treated <- dt[G <= min(time), unique(unit)]
  if (length(always_treated) > 0) {
    warning(length(always_treated), " units is treated in the first period, dropping them")
    dt <- dt[!unit %in% always_treated]
  }

  # for double did part
  if (!is.na(p$cohortvar2)) {
    always_treated <- dt[G2 <= min(time), unique(unit)]
    if (length(always_treated) > 0) {
      warning(length(always_treated), " units is treated in the first period, dropping them")
      dt <- dt[!unit %in% always_treated]
    }
  }



  return(dt)
}
