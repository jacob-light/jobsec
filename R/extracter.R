#' Scrape WARN notice data
#'
#' @description Extracter converts a WARN table in PDF format to a data frame.
#' Accepts as argument url = the url location of the target WARN table.
#'
#' @param url is the location of a WARN PDF table
#'
#' @export
#'
#' @importFrom stringr str_replace_all
#' @importFrom dplyr filter mutate bind_rows
#' @importFrom magrittr %>%
#' @importFrom lubridate mdy
#' @importFrom tabulizer extract_tables
#' 
#' @examples 
#'    [[NTD]]
#'
#' @keywords [[NTD]]
#'
extracter <- function(url) {
  # Extract table from web URL
  out <- tabulizer::extract_tables(url)
  
  # Take list output from extract_tables, reformat as single tibble
  out <- lapply(out, namer) %>% 
    dplyr::bind_rows()
  
  # Data cleaning - filter errant rows
  out <- out %>% 
    dplyr::filter(notice_date != "Notice Date")
  out <- out %>% 
    dplyr::mutate(effective_date = stringr::str_replace_all(effective_date, " ", ""),
                  received_date = stringr::str_replace_all(received_date, " ", ""))
  
  # Convert data types to date, numeric where appropriate
  out <- out %>% 
    dplyr::mutate(
      notice_date = lubridate::mdy(notice_date),
      effective_date = lubridate::mdy(effective_date),
      received_date = lubridate::mdy(received_date),
      n_employees = as.numeric(n_employees))
  return(out)
}