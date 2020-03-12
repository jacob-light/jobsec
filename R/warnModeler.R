#' Estimation using macro data and WARN notices
#'
#' @description Merges WARN data to lagged macro variables,
#' then estimates county level layoffs using lagged macro characteristics.
#' Returns output from OLS regression and regression tree
#'
#' @param df is a WARN extract data frame. df must be in the same format
#' as data downloaded using the warnDownload function and must contain at
#' least 100 unique county-year observations for reasonable inference
#'
#' @export warnModeler
#'
#' @importFrom stringr str_replace_all
#' @importFrom dplyr right_join select rename mutate group_by summarize ungroup slice bind_rows if_else mutate_if
#' @importFrom magrittr %>%
#' @importFrom lubridate year month
#' @importFrom stats lm predict
#' @importFrom utils data
#' 
#' @examples 
#'    # Replicate warnPrediction dataset provided in package
#'    data(warnSample)
#'    warnPrediction <- warnModeler(warnSample)
#'
warnModeler <- function(df = warnSample) {
  # Load from data files: 1) Archived warn data, FY2014-18
  #                       2) Annual population at the county level
  #                       3) Macro fundamentals from the ACS, covering 2014-18
  temp_envir <- new.env()
  utils::data(acs_data, envir = temp_envir)
  utils::data(pop, envir = temp_envir)
  utils::data(warnSample, envir = temp_envir)
  warn <- temp_envir$warnSample
  
  # Confirm that df supplied by user is of correct format and sensible length - require
  # 100 or more county-year observations to run regression
  if(all(colnames(warn) == colnames(df)) == FALSE) {
    stop("df incorrect format")
  }
  if(dim(df %>% 
         dplyr::mutate(year = lubridate::year(received_date)) %>%
         dplyr::select(year, county) %>%
         unique())[1] < 100) {
    stop("df contains insufficient county-year variation to run regressions")
  }
  warn <- df
  
  # Merge ACS and population data. Intermediate data frame will be unique at the
  # county-year level
  fin_out <- dplyr::right_join(temp_envir$acs_data,
                               temp_envir$pop %>% 
                                 dplyr::select(-c(SUMLEV, STATE, COUNTY, STNAME, AGEGRP)) %>% 
                                 dplyr::rename(county = CTYNAME, year = YEAR),
                               by = c("year", "county")) %>% 
    dplyr::select(county, year, everything())
  
  # NOTE: ACS data are not available for all counties (only available for counties w/
  # population > 100,000). When characteristics data are unavailable, impute
  # characteristics from nearest county with population above 100,000.
  rm(temp_envir)
  
  ###########################
  # 1 - Linear Regression
  ###########################  
  # Regularize data
  regularizer <- function(vec) {
    (vec - min(vec)) / (max(vec) - min(vec))
  }
  unregularizer <- function(vec, orig) {
    vec * (max(orig) - min(orig)) + min(orig)
  }
  
  # Standardize year in WARN data - merge to macro fundamentals using the year
  # in which the fiscal year begins (i.e. use 2014 population data for fiscal
  # year July 1, 2014 - June 30, 2015) - effectively regressing on lagged 
  # characteristics
  warn_ols <- warn %>%
    # Fiscal year: July - June
    dplyr::mutate(year = lubridate::year(received_date) - 
                    dplyr::if_else(lubridate::month(received_date) < 7, 1, 0)) %>%
    # Collapse WARN records to unique county-year level
    dplyr::group_by(year, county) %>%
    dplyr::summarize(n_layoffs = sum(n_employees)) %>%
    dplyr::ungroup() %>%
    # Merge on lagged characteristics
    dplyr::right_join(fin_out, by = c("year", "county")) %>%
    # Data processing - create variables for linear regression
    dplyr::mutate(n_layoffs = dplyr::if_else(is.na(n_layoffs), 0, n_layoffs),
                  ln_layoff = log(n_layoffs + 1), # Do a log x + 1 transformation, will undo when projecting
                  ln_pop = log(TOT_POP),
                  male_share =  TOT_MALE / TOT_POP)
  # Normalize all numerical variables
  warn_ols_regular <- warn_ols %>%
    dplyr::mutate_if(is.numeric, regularizer)
  # Store year step size as separate value for prediction
  year_proj <- list(year_max = max(warn_ols$year),
                    year_step = max(warn_ols$year) - min(warn_ols$year),
                    year_max_covar = max(fin_out$year))
  
  
  warn_reg <- stats::lm(ln_layoff ~ 1 + ln_pop + male_share + colshare + hsshare + empshare + 
                   agriculture + construction + manufacturing + wholesaletrade + transportation + 
                   utilities + information + finance + sciencemgmt + education + arts + otherservice + publicadmin + 
                   military + year,
                 data = warn_ols_regular)
  
  # Create data to project using OLS model
  to_predict_ols <- fin_out %>%
    dplyr::mutate(ln_pop = log(TOT_POP),
                  male_share =  TOT_MALE / TOT_POP) %>%
    dplyr::mutate_if(is.numeric, regularizer) %>%
    # Select most current year's data
    dplyr::filter(year == 1) %>%
    # Escalate up to projection year
    dplyr::mutate(year = year + 
                    (year_proj[['year_max_covar']] - year_proj[['year_max']] + 1) / 
                    (year_proj[['year_step']])) 
  
  warnPrediction <- dplyr::bind_rows(warn_ols %>% 
                                       dplyr::select(year, county, n_layoffs) %>%
                                       dplyr::mutate(type = "Actual"),
                                     to_predict_ols %>% 
                                       dplyr::select(year, county) %>%
                                       dplyr::mutate(n_layoffs = stats::predict(warn_reg, to_predict_ols)) %>%
                                       dplyr::mutate(n_layoffs = unregularizer(n_layoffs, warn_ols$ln_layoff)) %>%
                                       dplyr::mutate(n_layoffs = exp(n_layoffs) - 1) %>%
                                       dplyr::mutate(type = "OLS") %>%
                                       dplyr::mutate(year = year_proj[['year_max_covar']] + 1))
  
}


