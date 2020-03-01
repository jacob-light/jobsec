# Data extractor for summarizing WARN data.
# 
#
# Need to modeify with name of data set that will be 
# provided win the data set: ie replace "df_ca_warn"

warnExtract <- function(start_date = -Inf , 
                        end_date = Inf, 
                        type_date = c("effective_date", "notice_date" ,"received_date"), 
                        rollup = c("month", "year"), 
                        by = c("city", "county"), 
                        layoff_type = c("Closure Permanent","Closure Temporary", "Closure Unknown", "Layoff Permanent", 
                                        "Layoff Temporary","Layoff Unknown"), 
                        counties = NA, 
                        cities = NA){
  
  #create main date set
  df_ca_warn_mod <- df_ca_warn
  
  #Check user inputs for errors
  type_date <- match.arg(type_date)
  rollup <- match.arg(rollup)
  by <- match.arg(by)
  if(!all(is.element(layoff_type, c("Closure Permanent","Closure Temporary", "Closure Unknown", "Layoff Permanent", 
                                    "Layoff Temporary","Layoff Unknown")))){
    stop("'layoff_type' should be one of 'Closure Permanent', 'Closure Temporary', 'Closure Uknown', 'Layoff Permanent',
         'Layoff Temproary', 'Layoff Unknown'")
  }
  
  #check for county errors
  if(!is.na(counties[1])){
    if(!all(is.element(counties, unique(df_ca_warn_mod$county)))){
      stop("County not found.")
    }
  }
  
  #check for city errors
  if(!is.na(cities[1])){
    if(!all(is.element(cities, unique(df_ca_warn_mod$city)))){
      stop("City not found")
    }
  }
  
  #shorten length of layoff_type
  df_ca_warn_mod$layoff_reason <- str_replace(df_ca_warn_mod$layoff_reason," at this time", "")
  
  #tidy date field
  df_ca_warn_mod <- df_ca_warn_mod %>%
    pivot_longer(cols = c("notice_date","effective_date", "received_date"), names_to = "date_type", values_to = "date")
  
  #filter for type of layoff
  df_ca_warn_mod <- df_ca_warn_mod %>% 
    filter(layoff_reason %in% layoff_type)
  
  #filter for date_type
  df_ca_warn_mod <- df_ca_warn_mod %>%
    filter(date_type == type_date)
  
  #filter dates if user submits data range
  if(start_date != -Inf | end_date != Inf ){
    df_ca_warn_mod <-
      df_ca_warn_mod %>%
      filter(date > start_date) %>%
      filter(date < end_date)
  }
  
  #rollup to month or year
  if(rollup == "month"){
    df_ca_warn_mod$date <-
      df_ca_warn_mod$date %>%
      format("%m/%Y")
  } else if(rollup == "year") {
    df_ca_warn_mod$date <-
      df_ca_warn_mod$date %>%
      format("%Y")
  }
  
  #filter for cities
  if(!is.na(cities[1])){
    df_ca_warn_mod <-
      df_ca_warn_mod %>%
      filter(city %in% cities)
  }
  
  #filter for counties
  if(!is.na(counties[1])){
    df_ca_warn_mod <-
      df_ca_warn_mod %>%
      filter(county %in% counties)
  }
  
  #arrange dataframe for table
  df_ca_warn_mod <-
    df_ca_warn_mod %>%
    mutate(!!type_date := date) %>%
    select(type_date, by, layoff_reason, n_employees) %>%
    group_by(!!as.name(type_date), !!as.name(by), layoff_reason) %>%
    summarize(n_employees = sum(n_employees), n = n())
  
  #return data
  return(df_ca_warn_mod)
}