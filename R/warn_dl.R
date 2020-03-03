#' Calls extracter function, scrapes WARN notice data
#'
#' @description Extracter converts a WARN table in PDF format to a data frame.
#' Accepts as argument url = the url location of the target WARN table.
#'
#' @param year is an integer vector containing the fiscal years for which the function
#' will pull WARN reports. The default is to pull the current year report. The
#' fiscal year begins on July 1 of the specified year and ends on June 30 of the 
#' following year. Fiscal years are integers ranging from 2014 to 2019.
#'
#' @export
#'
#' @importFrom xml2 xml_find_all xml_attrs
#' @importFrom stringr str_subset
#' @importFrom purrr map reduce
#' @importFrom dplyr filter mutate select left_join
#' @importFrom magrittr %>%
#' 
#' @examples 
#'    [[NTD]]
#'
#' @keywords [[NTD]]
warn_dl <- function(year = NULL) {
  # Location of California EDD database:
  loc <- "https://www.edd.ca.gov/Jobs_and_Training/Layoff_Services_WARN.htm"
  
  # HTML refers only to file name - reconstruct filepath of
  # all WARN notice tables
  m <- strsplit(loc, "/")[[1]]
  m <- paste(m[1:length(m) - 1], collapse = '/')
  
  # Scrape data from CA EDD website, rebuild location path 
  wp <- xml2::read_html(loc)
  links <- c(wp %>%
    xml2::xml_find_all("//p/a") %>%
    xml2::xml_attrs() %>%
    unlist() %>%
    stringr::str_subset(pattern = "warn/"), 
    wp %>%
      xml2::xml_find_all("//li/a") %>%
      xml2::xml_attrs() %>%
      unlist() %>%
      stringr::str_subset(pattern = "warn/"))
  warns <- paste(m, links, sep = "/")
  
  # Select years in appropriate range:
  if(any(year %in% c(2014, 2015, 2016, 2017, 2018, 2019)) == FALSE) {
    warning("Year(s) out of range. Data are available for 2014-2019. Downloading only most recent year.")
    year <- 2019
  }
  if(is.null(year)) {
    warning("Year not initialized, downloading only most recent year")
    year <- 2019
  }
  
  # Apply extracter function to the links constructed above, subset to
  # date range specified in function arguments
  dates <- paste0("7-1-", year)
  to_scrape <- warns[purrr::map(dates, .f = str_detect, string = warns) %>% purrr::reduce(`|`)]
  
  # Scrape using extracter function
  out <- lapply(to_scrape, extracter) %>% 
    bind_rows()
  
  # Standardize county names
  out <- out %>% 
    dplyr::select(-county) %>%
    dplyr::left_join(readRDS("./data/city_to_county.RDS"), by = "city") %>%
    dplyr::mutate(county = if_else(is.na(county), "missing", county)) %>%
    dplyr::select(contains("date"), company, city, county, everything())
  return(out)
}
