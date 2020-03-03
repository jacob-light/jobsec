#' Estimation using macro data and WARN notices
#'
#' @description Merges WARN data to lagged macro variables,
#' then estimates county level layoffs using lagged macro characteristics.
#' Returns output from OLS regression and regression tree
#'
#' @param 
#'
#' @export [[NTD]]
#'
#' @importFrom string str_replace_all   [[NTD]]
#' @importFrom dplyr filter mutate
#' @importFrom magrittr %>%
#' @importFrom lubridate mdy
#' @importFrom tabulizer extract_tables
#' 
#' @examples 
#'    [[NTD]]
#'
#' @keywords [[NTD]]
modeler <- function(seed = sample(1:1000, 1)) {
  # Load from data files: 1) Archived warn data, FY2014-18
  #                       2) Annual population at the county level
  #                       3) Macro fundamentals from the ACS, covering 2014-18
  macro_out <- readRDS("./data/acs_data.RDS")
  pop <- readRDS("./data/pop.RDS")
  warn <- readRDS("./data/warns_archive.RDS")
  
  # Merge ACS and population data. Intermediate data frame will be unique at the
  # county-year level
  fin_out <- right_join(macro_out,
                        pop %>% 
                          select(-c(SUMLEV, STATE, COUNTY, STNAME, AGEGRP)) %>% 
                          rename(COUNTY = CTYNAME),
                        by = c("YEAR", "COUNTY")) %>% 
    select(COUNTY, YEAR, everything()) %>%
    rename(county = COUNTY, year = YEAR)
  
  ###########################
  # 1 - Linear Regression
  ###########################  
  # Standardize year in WARN data - merge to macro fundamentals using the year
  # in which the fiscal year begins (i.e. use 2014 population data for fiscal
  # year July 1, 2014 - June 30, 2015) - effectively regressing on lagged 
  # characteristics
  warn_ols <- warn %>%
    # Fiscal year: July - June
    mutate(year = year(received_date) - if_else(month(received_date) < 7, 1, 0)) %>%
    # Collapse WARN records to unique county-year level
    group_by(year, county) %>%
    summarize(n_layoffs = sum(n_employees)) %>%
    # Merge on lagged characteristics
    right_join(fin_out, by = c("year", "county")) %>%
    # Data processing - create variables for linear regression
    mutate(n_layoffs = if_else(is.na(n_layoffs), 0, n_layoffs),
           ln_layoff = log(n_layoffs + 1), # Do a log x + 1 transformation, will undo when projecting
           ln_pop = log(TOT_POP),
           male_share =  TOT_MALE / TOT_POP) %>%
    ungroup()
  
  # NTD: Fill in missing values for ACS data
  
  
  # 1 - linear regression
  # fatal_fe_mod <- plm(ln_layoff ~ 1 + ln_pop + male_share + colshare + hsshare + empshare + 
  #                       agriculture + construction + manufacturing + wholesaletrade + transportation + 
  #                       utilities + information + finance + sciencemgmt + education + arts + otherservice + publicadmin + 
  #                       military,
  #                     data = warn_ols,
  #                     index = c("county", "year"), 
  #                     model = "within")
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
      mutate(!!str_replace_all(string = i, pattern = " ", replacement = "") := as.numeric(county == i))
  }
  warn_rf <- warn_rf %>% filter(is.na(colshare) == FALSE)
  
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
    slice(n_train) %>%
    select(-c(ln_layoff, ln_pop, county))
    # mutate(county = factor(county))
  test_df <- warn_rf %>%
    slice(-n_train) %>%
    select(-c(ln_layoff, ln_pop, county))
    # mutate(county = factor(county))
  rfor <- randomForest::randomForest(n_layoffs ~ ., 
                                     data = train_df,
                                     importance = TRUE)
  
  # Prepare output
  out <- list(OLS = warn_reg,
              `Random Forest` = rfor)
  to_predict_ols <- warn_ols %>% 
    filter(year == 2018) %>%
    mutate(year = year + 1) # %>% ANY SENSITIVITIES
  to_predict_rf <- warn_rf %>% 
    filter(year == 2018) %>%
    mutate(year = year + 1) 
  predicted_data <- bind_rows(warn_ols %>% 
                                select(year, county, n_layoffs) %>%
                                mutate(type = "Actual"),
                              to_predict_ols %>% 
                                select(year, county) %>%
                                mutate(n_layoffs = predict(out[["OLS"]], to_predict_ols)) %>%
                                mutate(type = "OLS"),
                              to_predict_rf %>% 
                                select(year, county) %>%
                                mutate(n_layoffs = predict(out[["Random Forest"]], to_predict_rf)) %>%
                                mutate(type = "Random Forest"))
                              
  
  # NTD - DELETE
  saveRDS(predicted_data, "./data/predicted_data.RDS")
  saveRDS(out, "./data/estimation.RDS")
}