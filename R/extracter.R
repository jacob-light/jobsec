#' Scrape WARN notice data
#'
#' @description Extracter converts a WARN table in PDF format to a data frame.
#' Accepts as argument url = the url location of the target WARN table.
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
#'
extracter <- function(url) {
  # print(url)
  out <- extract_tables(url)
  
  # List --> data frame
  out <- lapply(out, namer) %>% bind_rows()
  
  # Basic cleaning
  out <- out %>% filter(notice_date != "Notice Date")
  out <- out %>% mutate(effective_date = str_replace_all(effective_date, " ", ""),
                        received_date = str_replace_all(received_date, " ", ""))
  
  # Convert to date
  out <- out %>% mutate(notice_date = mdy(notice_date),
                        effective_date = mdy(effective_date),
                        received_date = mdy(received_date),
                        n_employees = as.numeric(n_employees))
  return(out)
}