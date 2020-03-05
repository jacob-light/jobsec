#' Scrape CA City-to-County Mapping
#'
#' @description Downloads city-to-county mapping from counties.org
#'
#' @param 
#'
#' @export
#'
#' @importFrom xml2 read_html
#' @importFrom rvest html_nodes html_text
#' @importFrom stringr str_replace_all str_split
#' @importFrom magrittr %>%
#' 
#' @examples 
#'    [[NTD]]
#'
#' @keywords [[NTD]]
#'
CA_city_to_county <- function() {
  # 1 - Scrape counties
  counties <- xml2::read_html("https://www.counties.org/cities-within-each-county") %>%
    rvest::html_nodes("body") %>%
    rvest::html_nodes("h3") %>%
    rvest::html_text() %>%
    stringr::str_replace_all("\n", "") %>%
    trimws()
  
  # 2 - Scrape cities
  cities <- xml2::read_html("https://www.counties.org/cities-within-each-county") %>%
    rvest::html_nodes("body") %>%
    rvest::html_nodes("ul")
  cities <- cities[substr(cities, 1, 9) == "<ul>\n<li>"]  %>%
    html_text() %>%
    str_replace_all("\n  \n", "") %>%
    str_split("  ")
  
  # Return city-to-county mapping
  city_to_county <- tibble(county = rep(x = counties, times = sapply(cities, length)),
                           city = cities %>% unlist() %>% trimws())
  
  # NTD - Edit
  saveRDS(city_to_county, file = "C:/Users/jligh/Documents/git/warn/jobsec/data/city_to_county.RDS")
}