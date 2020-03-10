#' Generate map plots rom warnExtract data frame
#' 
#' @description generates map plots from data frames that were produced by \link[jobsec]{warnExtract}.
#' @param data a data frame of WARn data from \link[jobsec]{warnExtract}.
#' @importFrom dplyr group_by summarize mutate rename left_join summarise
#' @importFrom stringr str_replace str_to_title
#' @importFrom ggplot2 map_data ggplot geom_polygon coord_map labs geom_text theme aes
#' @importFrom magrittr %>%
#' @examples
#' #extract warn data
#' df<- warnExtract(start_date = "2018-01-01", end_date = "2019-01-01")
#' #plot maps
#' warnMap(df)
#' @export warnMap
warnMap <- function(data){

  #summarize data data
  plot_data <- data %>%
    dplyr::group_by(county) %>%
    dplyr::summarize(layoffs = base::sum(n_employees)) %>%
    dplyr::mutate(county = base::tolower(county))
  
  #clean county list
  plot_data$county <- stringr::str_replace(plot_data$county ,pattern = " county", replace= "")
  
  #get county map list
  county_map <- ggplot2::map_data("county", "california") %>%
    dplyr::rename(county = subregion)
  
  #merge data with plot data
  merge_data <- dplyr::left_join(county_map, plot_data , by = "county")
  
  #calculate locations for map names
  counties_map_names <- merge_data %>%
    dplyr::group_by(county, layoffs) %>%
    dplyr::summarise(long = (base::max(long) + base::min(long))/2, lat = (base::max(lat) + base::min(lat))/2)
  
  #plot map with names and layoffs
  plt <- ggplot2::ggplot(data = merge_data ,mapping = ggplot2::aes(x = long, y = lat, group = county, fill = layoffs)) +
    ggplot2::geom_polygon(color = "gray90", size = 0.1) +
    ggplot2::coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
    ggplot2::labs(fill = NULL,
         caption = base::paste("Source: CA WARN Data"),
         title = base::paste ("CA WARN Events by County", min(data[[1]]), "-", max(data[[1]]) )) +
    ggplot2::geom_text(ggplot2::aes(label = county), data = counties_map_names,  size = 3, hjust = 0.5, color = "white", fontface = "bold")+
    ggplot2::theme(panel.background = ggplot2::element_rect(fill = "darkgray"))
  
  return(plt)
}