#' Data extractor for summarizing WARN data.
#' 
#' @description Creates a filtered data set from WARN data to use in plotting functions or as a data table.
#' @param start_date a start date.
#' @param end_date an end date.
#' @param type_date a string specifying layoff reason.
#' @param rollup a string specifying what time frame to roll up totals: "month" or "year".
#' @param layoff_type a string specifying what layoff types to filter for.
#' @param counties a character vector of counties to filter for.
#' @importFrom stringr str_replace
#' @importFrom dplyr filter
#' @importFrom tidyr pivot_longer
#' @importFrom magrittr %>%
#' @return a data frame of summarized WARN data based on user filtered inputs.
#' @examples
#' df <- warnExtract(counties = c("Santa Clara", 
#'   "Los Angeles"), rollup = "year")
#' df <- warnExtract(start_date = "2018-01-01", end_date = "2018-08-01")
#' @export warnExtract
warnExtract <- function(start_date = -Inf , 
                        end_date = Inf, 
                        type_date = c("effective_date", "notice_date" ,"received_date"), 
                        rollup = c("month", "year"),
                        layoff_type = c("Closure Permanent","Closure Temporary", "Closure Unknown", "Layoff Permanent", 
                                        "Layoff Temporary","Layoff Unknown"), 
                        counties = NA){
  
  #create main date set
  df_ca_warn_mod <- warnSample
  
  #Check user inputs for errors
  type_date <- base::match.arg(type_date)
  rollup <- base::match.arg(rollup)
  
  if(!base::all(base::is.element(layoff_type, c("Closure Permanent","Closure Temporary", "Closure Unknown", "Layoff Permanent", 
                                    "Layoff Temporary","Layoff Unknown")))){
    stop("'layoff_type' should be one of 'Closure Permanent', 'Closure Temporary', 'Closure Uknown', 'Layoff Permanent',
         'Layoff Temproary', 'Layoff Unknown'")
  }
  
  #check for county errors
  if(!base::is.na(counties[1])){
    if(!base::all(base::is.element(counties, base::unique(df_ca_warn_mod$county)))){
      stop("County not found.")
    }
  }

  #shorten length of layoff_type
  df_ca_warn_mod$layoff_reason <- stringr::str_replace(df_ca_warn_mod$layoff_reason," at this time", "")
  
  #tidy date field
  df_ca_warn_mod <- df_ca_warn_mod %>%
    tidyr::pivot_longer(cols = c("notice_date","effective_date", "received_date"), names_to = "date_type", values_to = "date")
  
  #filter for type of layoff
  df_ca_warn_mod <- df_ca_warn_mod %>% 
    dplyr::filter(layoff_reason %in% layoff_type)
  
  #filter for date_type
  df_ca_warn_mod <- df_ca_warn_mod %>%
    dplyr::filter(date_type == type_date)
  
  #filter dates if user submits data range
  if(start_date != -Inf | end_date != Inf ){
    df_ca_warn_mod <-
      df_ca_warn_mod %>%
      dplyr::filter(date > start_date) %>%
      dplyr::filter(date < end_date)
  }
  
  #rollup to month or year
  if(rollup == "month"){
    df_ca_warn_mod$date <-
      df_ca_warn_mod$date %>%
      as.Date() %>%
      format("%m/%Y")
  } else if(rollup == "year") {
    df_ca_warn_mod$date <-
      df_ca_warn_mod$date %>%
      as.Date() %>%
      format("%Y")
  }
  
  #filter for counties
  if(!base::is.na(counties[1])){
    df_ca_warn_mod <-
      df_ca_warn_mod %>%
      dplyr::filter(county %in% counties)
  }
  
  #arrange dataframe for table
  df_ca_warn_mod <-
    df_ca_warn_mod %>%
    dplyr::mutate(!!type_date := date) %>%
    dplyr::select(type_date, county, layoff_reason, n_employees) %>%
    dplyr::group_by(!!as.name(type_date), county, layoff_reason) %>%
    dplyr::summarize(n_employees = sum(n_employees), events = dplyr::n())
  
  #return data
  return(df_ca_warn_mod)
}