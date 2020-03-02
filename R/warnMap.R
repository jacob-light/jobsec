# Map county data from warnExtract.
# 
# only maps counties, did we want to add cities?
#
warnMap <- function(extract){
  #get locatity: coty or county
  local <- names(extract[2])
  
  #check for counties only.
  if(local == "city"){
    stop("Mapping only works with counties, not cities.")
  }
  
  #summarize extract data
  plot_data <- extract %>%
    group_by(!!as.name(local)) %>%
    summarize(layoffs = sum(n_employees)) %>%
    mutate(!!local := tolower(!!as.name(local)))
  
  #clean county list
  plot_data$county <- str_replace(plot_data$county ,pattern = " county", replace= "")
  
  #get county map list
  county_map <- map_data("county", "california") %>%
    rename(county = subregion)
  
  #mer data with 
  merge_data <- left_join(county_map, plot_data , by = "county")
  
  #calculate locations for map names
  counties_map_names <- merge_data %>%
    group_by(county, layoffs) %>%
    summarise(long = (max(long) + min(long))/2, lat = (max(lat) + min(lat))/2)
  
  #plot map with names and layoffs
  plt <- ggplot(data = merge_data ,mapping = aes(x = long, y = lat, group = county, fill = layoffs)) +
    geom_polygon(color = "gray90", size = 0.1) +
    coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
    labs(fill = NULL,
         caption = "Source: CA WARN Data, 2018 - 2019",
         title = "CA WARN Events by County, 2018-19") +
    geom_text(aes(label = county), data = counties_map_names,  size = 3, hjust = 0.5, color = "white", fontface = "bold")+
    theme(panel.background = element_rect(fill = "darkgray"))
  
  return(plt)
}