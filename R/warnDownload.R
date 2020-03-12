#' Calls warnReader function, scrapes WARN notice data
#'
#' @description warnDownload converts a WARN table in PDF format to a data frame.
#'
#' @param year is an integer vector containing the fiscal years for which the function
#' will pull WARN reports. The default is to pull the current year report. The
#' fiscal year begins on July 1 of the specified year and ends on June 30 of the 
#' following year. Fiscal years are integers ranging from 2014 to 2019.
#'
#' @export warnDownload
#'
#' @importFrom xml2 xml_find_all xml_attrs
#' @importFrom stringr str_subset str_detect
#' @importFrom purrr map reduce
#' @importFrom dplyr filter mutate select left_join bind_rows if_else contains everything
#' @importFrom magrittr %>%
#' 
#' @examples 
#'    # Download WARN files for current year
#'    warn_current <- warnDownload(2019)
#'    
#'    # Replicate the warnSample dataset provided in the package
#'    warnSample <- warnDownload(2014:2018)
#'    
#' @keywords [[NTD]]
warnDownload <- function(year = NULL) {
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
  
  # Apply warnReader function to the links constructed above, subset to
  # date range specified in function arguments
  dates <- paste0("7-1-", year)
  to_scrape <- warns[purrr::map(dates, .f = stringr::str_detect, string = warns) %>% purrr::reduce(`|`)]
  
  # Scrape using warnReader function
  out <- lapply(to_scrape, warnReader) %>% 
    dplyr::bind_rows()
  
  # Load city-to-county data in temporary environment for merge
  temp_envir <- new.env()
  data(city_to_county, envir = temp_envir)
  
  # Standardize county names
  out2 <- out %>%
    dplyr::left_join(temp_envir$city_to_county, by = "city") %>%
    dplyr::mutate(county = dplyr::if_else(is.na(county), "missing", county)) %>%
    dplyr::select(dplyr::contains("date"), company, city, county, dplyr::everything()) %>%
    # Manually adjust names for compatability with warnMap function
    dplyr::mutate(county = trimws(county)) %>%
    dplyr::mutate(county = dplyr::if_else(stringr::str_detect(county, "Francisco"), "San Francisco County", county)) %>%
    # Manually adjust cities with more than 10 WARN notices that fail to match city-county map
    dplyr::mutate(county = dplyr::if_else(city == "Chatsworth", "Los Angeles County", county)) %>%
    dplyr::mutate(county = dplyr::if_else(city == "City of Industry", "Los Angeles County", county)) %>%
    dplyr::mutate(county = dplyr::if_else(city == "Fort Irwin", "San Bernadino County", county)) %>%
    dplyr::mutate(county = dplyr::if_else(city == "Huntington", "Orange County", county)) %>%
    dplyr::mutate(county = dplyr::if_else(city == "Mira Loma", "Riverside County", county)) %>%
    dplyr::mutate(county = dplyr::if_else(city == "Rancho", "San Bernardino County", county)) %>%
    dplyr::mutate(county = dplyr::if_else(city == "South San", "San Mateo County", county)) %>%
    dplyr::mutate(county = dplyr::if_else(city == "Valencia", "Los Angeles County", county)) %>%
    dplyr::mutate(county = dplyr::if_else(city == "Wilmington", "Los Angeles County", county)) %>%
    dplyr::mutate(county = dplyr::if_else(city == "Woodland Hills", "Los Angeles County", county)) %>%
    dplyr::filter(county != "missing")
  
  rm(temp_envir)
  return(out)
}
