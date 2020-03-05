#' Estimation using macro data and WARN notices
#'
#' @description Merges WARN data to lagged macro variables,
#' then estimates county level layoffs using lagged macro characteristics.
#' Returns output from OLS regression and regression tree
#'
#' @param seed is a seed value to ensure replicability
#'
#' @export warnModeler
#'
#' @importFrom stringr str_replace_all
#' @importFrom dplyr right_join select rename mutate group_by summarize ungroup slice bind_rows if_else
#' @importFrom magrittr %>%
#' @importFrom randomForest randomForest
#' @importFrom stats lm
#' @importFrom lubridate year month
#' 
#' @examples 
#'    # Replicate warnPrediction dataset provided in package
#'    warnPrediction <- warnModeler(25)
#'
warnModeler <- function(seed = sample(1:1000, 1)) {
  # Load from data files: 1) Archived warn data, FY2014-18
  #                       2) Annual population at the county level
  #                       3) Macro fundamentals from the ACS, covering 2014-18
  macro_out <- readRDS("./data/acs_data.RDS")
  pop <- readRDS("./data/pop.RDS")
  warn <- readRDS("./data/warnSample.RDS")
  
  # Merge ACS and population data. Intermediate data frame will be unique at the
  # county-year level
  fin_out <- dplyr::right_join(macro_out,
                        pop %>% 
                          dplyr::select(-c(SUMLEV, STATE, COUNTY, STNAME, AGEGRP)) %>% 
                          dplyr::rename(county = CTYNAME, year = YEAR),
                        by = c("year", "county")) %>% 
    dplyr::select(county, year, everything())
  
  # NOTE: ACS data are not available for all counties (only available for counties w/
  # population > 100,000). When characteristics data are unavailable, impute
  # characteristics from nearest county with population above 100,000.
  
  ###########################
  # 1 - Linear Regression
  ###########################  
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
    # Merge on lagged characteristics
    dplyr::right_join(fin_out, by = c("year", "county")) %>%
    # Data processing - create variables for linear regression
    dplyr::mutate(n_layoffs = dplyr::if_else(is.na(n_layoffs), 0, n_layoffs),
           ln_layoff = log(n_layoffs + 1), # Do a log x + 1 transformation, will undo when projecting
           ln_pop = log(TOT_POP),
           male_share =  TOT_MALE / TOT_POP) %>%
    dplyr::ungroup()
  

  warn_reg <- lm(ln_layoff ~ 1 + ln_pop + male_share + colshare + hsshare + empshare + 
                   agriculture + construction + manufacturing + wholesaletrade + transportation + 
                   utilities + information + finance + sciencemgmt + education + arts + otherservice + publicadmin + 
                   military + year,
                 data = warn_ols)
  
  ###########################
  # 2 - Random Forest
  ###########################
  warn_rf <- warn_ols
  
  # Create dummy for each county
  for(i in unique(warn_rf$county)) {
    warn_rf <- warn_rf %>%
      dplyr::mutate(!!stringr::str_replace_all(string = i, pattern = " ", replacement = "") 
                    := as.numeric(county == i))
  }
  warn_rf <- warn_rf %>% 
    dplyr::filter(is.na(colshare) == FALSE)
  
  # For replication, set seed
  if(is.numeric(seed) == FALSE) {
    warning("Non-numeric seed")
    seed <- sample(1:1000, 1)
  }
  set.seed(seed)  
  
  # Build test, train datasets
  n_train <- sample(x = 1:dim(warn_rf)[1],
                    size = floor(0.6 * dim(warn_rf)[1]),
                    replace = FALSE)
  train_df <- warn_rf %>%
    dplyr::slice(n_train) %>%
    dplyr::select(-c(ln_layoff, ln_pop, county))
    # mutate(county = factor(county))
  test_df <- warn_rf %>%
    dplyr::slice(-n_train) %>%
    dplyr::select(-c(ln_layoff, ln_pop, county))
    # mutate(county = factor(county))
  rfor <- randomForest::randomForest(n_layoffs ~ ., 
                                     data = train_df,
                                     importance = TRUE)
  
  # Prepare output
  out <- list(OLS = warn_reg,
              `Random Forest` = rfor)
  to_predict_ols <- warn_ols %>% 
    dplyr::filter(year == 2018) %>%
    dplyr::mutate(year = year + 1)
  to_predict_rf <- warn_rf %>% 
    dplyr::filter(year == 2018) %>%
    dplyr::mutate(year = year + 1) 
  predicted_data <- dplyr::bind_rows(warn_ols %>% 
                                       dplyr::select(year, county, n_layoffs) %>%
                                       dplyr::mutate(type = "Actual"),
                              to_predict_ols %>% 
                                dplyr::select(year, county) %>%
                                dplyr::mutate(n_layoffs = predict(out[["OLS"]], to_predict_ols)) %>%
                                dplyr::mutate(type = "OLS"),
                              to_predict_rf %>% 
                                dplyr::select(year, county) %>%
                                dplyr::mutate(n_layoffs = predict(out[["Random Forest"]], to_predict_rf)) %>%
                                dplyr::mutate(type = "Random Forest"))
                              
  
  # NTD - DELETE
  return(predicted_data)
}
