# Bar charts for data from warnExtract.
# 
# Need to add chart titles and data source refs
#
warnBar <- function(extract,
                    by = c("rollup", "locality", "reason")){
  
  #check user imputs
  by <- match.arg(by)
  
  #get local name: city or county for plotting
  local <- names(extract[2])
  
  if(by == "rollup")
    bar_plot <- ggplot(extract, aes(x=effective_date, y=n_employees)) + 
    geom_bar(stat = "identity", fill = "steelblue")+
    xlab(NA)+
    ylab("Employees")+
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  if(by == "reason")
    bar_plot <- ggplot(extract, aes(x=effective_date, y=n_employees, fill = layoff_reason)) + 
    geom_bar(stat = "identity", position="dodge")+
    ylab("Employees")+
    theme(axis.text.x = element_text(angle = 45, hjust = 1))+
    labs(x = "", fill = "Layoff Reason")
  
  if(by == "locality")
    bar_plot <- ggplot(extract, aes(x=effective_date, y=n_employees ,fill = get(local))) + 
    geom_bar(stat = "identity" , position="dodge") +
    ylab("Layoffs")+
    theme(axis.text.x = element_text(angle = 45, hjust = 1))+
    labs(x = "", fill = "Region")
  
  return(bar_plot)
}
