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
warn <- function() {
  pop <- readr::read_csv("https://www2.census.gov/programs-surveys/popest/datasets/2010-2018/counties/asrh/cc-est2018-alldata-06.csv") %>%
    dplyr::mutate(YEAR = 2007 + YEAR) %>%
    dplyr::filter(AGEGRP == 0) %>% 
    dplyr::filter(YEAR >= 2014)
}