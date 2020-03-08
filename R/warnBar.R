#' Generate bar plots from warnExtract data frame
#' 
#' @description generates bar plots from data frames that were produced by \link[jobsec]{warnExtract}. 
#' @param data a data frame of WARn data from \link[jobsec]{warnExtract}.
#' @param by a string specifying bar fill categories.
#' @importFrom ggplot2 ggplot geom_bar xlab ylab theme labs aes element_text
#' @importFrom stringr str_to_title
#' @importFrom magrittr %>%
#' @examples
#' #extract warn data
#' df<- warnExtractstart_date = "2018-01-01", end_date = "2019-01-01")
#' #bar plots
#' warnBar(df, by = "reason")
#' @export warnBar
warnBar <- function(data,
                    by = c("rollup", "locality", "reason")){
  
  #check user imputs
  by <- base::match.arg(by)
  
  #get first column date name
  date <- names(data[1])
  
  #plot by rollup
  if(by == "rollup")
    #plot
    bar_plot <- ggplot2::ggplot(data, ggplot2::aes(x=get(date), y=n_employees)) + 
    ggplot2::geom_bar(stat = "identity", fill = "steelblue")+
    ggplot2::xlab("")+
    ggplot2::ylab("Employees")
  
  #plot by layoff reason.
  if(by == "reason"){
    #check for layoff reason in data
    if("layoff_reason" %in% colnames(data)){
      #plot
      bar_plot <- ggplot2::ggplot(data, ggplot2::aes(x=get(date), y=n_employees, fill = layoff_reason)) + 
      ggplot2::geom_bar(stat = "identity", position="stack")+
      ggplot2::ylab("Employees")
    }
    else{
      stop("'layoff_reason' not found in data set. Use another warnBar method.")
    }
  }

  #plot by locality
  if(by == "locality"){
    #check for number of counties and warn if to many.
    if(length(unique(data$county)) > 5){
      warning("Recommended selecting  <= 5 counties for graph legibility.")
    }
    #plot
    bar_plot <- ggplot2::ggplot(data, ggplot2::aes(x=get(date), y=n_employees ,fill = county )) + 
    ggplot2::geom_bar(stat = "identity" , position="dodge") +
    ggplot2::ylab("Layoffs")
  }

    #Add additional details and titles to plots
  bar_plot <- bar_plot+
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))+
    ggplot2::labs(x = "", fill = "Region",
                  caption = base::paste("Source: CA WARN Data"),
                  title = base::paste ("CA WARN Events by County", min(data[[1]]), "-", max(data[[1]]) ))
  
  return(bar_plot)
}
