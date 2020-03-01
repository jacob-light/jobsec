#' Scrape population data
#'
#' @description Scrapes California county-level population estimates from Census
#'
#' @param 
#'
#' @export
#'
#' @importFrom readr read_csv
#' @importFrom dplyr filter mutate
#' @importFrom magrittr %>%
#' 
#' @examples 
#'    [[NTD]]
#'
#' @keywords [[NTD]]
#'
dl_pop <- function() {
  pop <- read_csv("https://www2.census.gov/programs-surveys/popest/datasets/2010-2018/counties/asrh/cc-est2018-alldata-06.csv") %>%
    mutate(YEAR = 2007 + YEAR) %>%
    filter(AGEGRP == 0) %>% 
    filter(YEAR >= 2014)
  
  # NTD - Edit
  saveRDS(pop, file = "C:/Users/jligh/Documents/git/warn/jobsec/data/pop.RDS")
}