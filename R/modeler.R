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
modeler <- function() {
  # Load macro data, population data, WARN notice data
  macro_out <- readRDS("./data/acs_data.RDS")
  pop <- readRDS("./data/pop.RDS")
  city_to_county <- readRDS("./data/city_to_county.RDS")
  warn <- readRDS("./data/warn_sample.RDS")
  
  # Prepare RHS variables
  fin_out <- right_join(macro_out,
                        pop %>% select(-c(SUMLEV, STATE, COUNTY, STNAME, AGEGRP)) %>% 
                          rename(COUNTY = CTYNAME)) %>% 
    select(COUNTY, YEAR, everything()) %>%
    rename(county = COUNTY, year = YEAR)
  
  # Prephare LHS, merge to form regression dataset
  warn2 <- left_join(warn %>% select(-county),
                              city_to_county,
                              by = "city") %>%
    # Fiscal year: July - June
    mutate(year = year(received_date) - 
             if_else(month(received_date) < 7, 1, 0))
  
  warn_data_reg <- warn2 %>%
    group_by(year, county) %>%
    summarize(n_layoffs = sum(n_employees)) %>%
    # Merge on lagged characteristics
    right_join(fin_out) %>%
    mutate(n_layoffs = if_else(is.na(n_layoffs), 0, n_layoffs),
           ln_layoff = log(n_layoffs + 1), # Do a log x + 1 transformation, will undo when projecting
           ln_pop = log(TOT_POP),
           male_share =  TOT_MALE / TOT_POP) %>%
    ungroup()
  
  # 1 - linear regression
  warn_reg <- lm(ln_layoff ~ 1 + ln_pop + male_share + colshare + hsshare + empshare + 
                   agriculture + construction + manufacturing + wholesaletrade + transportation + 
                   utilities + information + finance + sciencemgmt + education + arts + otherservice + publicadmin + 
                   military + year,
                 data = warn_data_reg)
  # pred <- exp(warn_reg[["fitted.values"]]) - 1
  
  # 2 - random forest
  # library(randomForest)
  
  # Recast all counties as dummy variables
  for(i in unique(warn_data_reg$county)) {
    warn_data_reg <- warn_data_reg %>% mutate(!!str_replace_all(string = i, pattern = " ", replacement = "") := as.numeric(county == i))
  }
  warn_data_reg <- warn_data_reg %>% filter(is.na(colshare) == FALSE)
  
  # Build test, train datasets
  n_train <- sample(x = 1:dim(warn_data_reg)[1],
                    size = floor(0.6 * dim(warn_data_reg)[1]),
                    replace = FALSE)
  train_df <- warn_data_reg %>%
    slice(n_train) %>%
    select(-c(ln_layoff, ln_pop, county))
  train_df_x <- as.matrix(train_df %>% select(-n_layoffs))
  train_df_y <- as.matrix(train_df %>% select(n_layoffs))
  # 
  # test_df <- warn_data_reg %>%
  #   slice(-n_train) %>%
  #   select(-c(ln_layoff, ln_pop, county))
  rfor <- randomForest(n_layoffs ~ ., data = train_df)
  # x = train_df %>% select(-n_layoffs),
  #                      y = train_df %>% select(n_layoffs))
  
  out <- list(OLS = warn_reg,
              `Random Forest` = rfor)
  
  
  # NTD - DELETE
  saveRDS(out, "./data/estimation.RDS")
}