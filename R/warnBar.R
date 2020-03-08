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
#' df<- warnExtract(start_date = "2018-01-01", end_date = "2018-08-01")
#' #bar plots
#' warnBar(df, by = "reason")
#' @export warnBar
warnBar <- function(data,
                    by = c("rollup", "locality", "reason")){
  
  #check user imputs
  by <- base::match.arg(by)
  

  
  if(by == "rollup")
    bar_plot <- ggplot2::ggplot(data, ggplot2::aes(x=effective_date, y=n_employees)) + 
    ggplot2::geom_bar(stat = "identity", fill = "steelblue")+
    ggplot2::xlab("")+
    ggplot2::ylab("Employees")+
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))+
    ggplot2::labs(fill = NULL,
         caption = base::paste("Source: CA WARN Data"),
         title = base::paste ("CA WARN Events by County", min(data[[1]]), "-", max(data[[1]]) ))
  
  if(by == "reason")
    bar_plot <- ggplot2::ggplot(data, ggplot2::aes(x=effective_date, y=n_employees, fill = layoff_reason)) + 
    ggplot2::geom_bar(stat = "identity", position="stack")+
    ggplot2::ylab("Employees")+
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))+
    ggplot2::labs(x = "", fill = "Layoff Reason",
         caption = base::paste("Source: CA WARN Data"),
         title = base::paste ("CA WARN Events by County", min(data[[1]]), "-", max(data[[1]]) ))
  
  if(by == "locality")
    bar_plot <- ggplot2::ggplot(data, ggplot2::aes(x=effective_date, y=n_employees ,fill = county )) + 
    ggplot2::geom_bar(stat = "identity" , position="dodge") +
    ggplot2::ylab("Layoffs")+
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))+
    ggplot2::labs(x = "", fill = "Region",
         caption = base::paste("Source: CA WARN Data"),
         title = base::paste ("CA WARN Events by County", min(data[[1]]), "-", max(data[[1]]) ))

  return(bar_plot)
}
