#' Clean WARN data
#'
#' @description CA WARN data tables are published in inconsistent format. The
#' warnNamer function identifies the format of the WARN table and
#' names the columns appropriately.
#'
#' @param d is a list object containing scraped WARN pdf
#'
#' @export warnNamer
#'
warnNamer <- function(d) {
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  
  # Check table width
  if (dim(d)[2] == 7) {
    # Early files do not include county name
    headers <- c("notice_date", "effective_date", "received_date", "company",
                 "city", "n_employees", "layoff_reason")
    colnames(d) <- headers
    return(d)
  } else if (dim(d)[2] == 8) {
    # Early files do not include county name
    headers <- c("notice_date", "effective_date", "received_date", "company",
                 "city", "county", "n_employees", "layoff_reason") 
    colnames(d) <- headers
    return(d)
  } else {
    return(NULL)
  }
}