#' Process macro data from ACS
#'
#' @description Creates ACS data extract for regression controls
#'
#' @param url is the location of a WARN PDF table
#'
#' @export
#'
#' @importFrom string str_replace_all
#' @importFrom dplyr filter mutate
#' @importFrom magrittr %>%
#' @importFrom lubridate mdy
#' @importFrom tabulizer extract_tables
#' 
#' @examples 
#'    [[NTD]]
#'
#' @keywords [[NTD]]
macro_data_DONOTEXPORT <- function() {
  macro <- read_csv("C:/Users/jligh/Box/Second Year/Winter 2019/Stats 290/Final Project/usa_00020.csv")
  cns <- colnames(macro)[(colnames(macro) %in% c("YEAR", "COUNTYICP")) == FALSE]
  macro <- macro %>% 
    # filter(AGE %in% 18:64) %>%
    mutate(
      # Share of population with college, hs degree
      ed_denom = PERWT * as.numeric(EDUC > 0),
      col_grad = PERWT * as.numeric(EDUC >= 10),
      hs_grad = PERWT * as.numeric(EDUC >= 6 & EDUC < 10),
      # Employment rate (will want lagged employment rate as well)
      employed = PERWT * as.numeric(EMPSTAT == 1),
      in_lf = PERWT * as.numeric(EMPSTAT %in% c(1, 2)),
      # INDUSTRY
      agriculture = PERWT * as.numeric(IND %in% c(170:490)),
      construction = PERWT * as.numeric(IND %in% c(770)),
      manufacturing = PERWT * as.numeric(IND %in% c(1070:3990)),
      wholesale_trade = PERWT * as.numeric(IND %in% c(4070:4590)),
      transportation = PERWT * as.numeric(IND %in% c(6070:6390)),
      utilities = PERWT * as.numeric(IND %in% c(570:690)),
      information = PERWT * as.numeric(IND %in% c(6470:6780)),
      finance = PERWT * as.numeric(IND %in% c(6870:7190)),
      science_mgmt = PERWT * as.numeric(IND %in% c(7270:7790)),
      education = PERWT * as.numeric(IND %in% c(7860:8470)),
      arts = PERWT * as.numeric(IND %in% c(8560:8690)),
      other_service = PERWT * as.numeric(IND %in% c(8770:9290)),
      public_admin = PERWT * as.numeric(IND %in% c(9370:9590)),
      military = PERWT * as.numeric(IND %in% c(9670:9870)),
      unemployed = PERWT * as.numeric(IND %in% c(9920)),
      any_code = PERWT * as.numeric(IND >= 170 & IND <= 9920))
  
  # Aggregate stats
  cns2 <- colnames(macro)[grep("agriculture", colnames(macro)):
                            (length(colnames(macro)) - 1)]
  macro2 <- macro %>%
    select(-!!cns) %>%
    group_by(YEAR, COUNTYICP) %>%
    summarize_all(funs(sum)) %>%
    mutate(col_share__ = col_grad / ed_denom,
           hs_share__ = hs_grad / ed_denom,
           emp_share__ = employed / in_lf) %>%
    ungroup()
  out <- function(col, df) {
    new_name = paste0(col, "__")
    df <- df %>% mutate(!!new_name := evalq(as.numeric(!!sym(col))) / any_code) %>%
      select(!!new_name)
  }
  macro2 <- cbind(macro2,
                  lapply(cns2, out, df = macro2) %>% bind_cols()) %>%
    select(YEAR, COUNTYICP, contains("__"))
  colnames(macro2) <- gsub("_", "", colnames(macro2))
  
  # Map in county names
  macro_out <- macro2 %>% 
    rename("County cod" = COUNTYICP) %>%
    inner_join(read_delim("https://usa.ipums.org/usa/volii/icpsrcnt.txt", delim = "\t") %>%
                 filter(State == "California")) %>%
    mutate(COUNTY = paste(County, "County")) %>% 
    select(-c("County cod", State, STATEICP, STATEFIPS, County))
  
  # Save data
  saveRDS(macro_out, file = "C:/Users/jligh/Documents/git/warn/jobsec/data/acs_data.RDS")
}