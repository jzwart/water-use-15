process.merge_centroids_wu <- function(viz) {
  deps <- readDepends(viz)
  wu_data_15_simple <- deps[["wu_data_15_simple"]]
  
  topo <- rgdal::readOGR(as.viz(viz$depends$topo)$location, layer=viz$process_args$layer, drop_unsupported_fields=TRUE, stringsAsFactors=FALSE) # bypass readDepends for topojson
  
  # extract the centroid coordinates into a table with GEOID
  centroid_coords <- bind_cols(select(topo@data, GEOID), rename(as_data_frame(topo@coords), lon=coords.x1, lat=coords.x2))

  # merge datasets and keep a minimal set of columns
  county_data <- topo@data %>%
    left_join(wu_data_15_simple, by=c('GEOID'='FIPS')) %>%
    select(GEOID, STATE_ABBV, COUNTY, countypop:industrial) %>% 
    rowwise() %>% 
    mutate(other = total - sum(thermoelectric, publicsupply, irrigation, industrial)) %>%
    mutate(total = signif(total, digits = 6),
           thermoelectric = signif(thermoelectric, digits = 6),
           irrigation = signif(irrigation, digits = 6),
           publicsupply =  signif(publicsupply, digits = 6),
           industrial = signif(industrial, digits = 6)) 
  
  # add centroid coordinates to the WU data
  county_data <- county_data %>%
    left_join(centroid_coords, by='GEOID')
  
  # write to file - save centroids as tsv instead of topojson for efficiency
  # (307 Kb instead of 412 for simplified json with 1 character per column name,
  # or 664 Kb for json with complete column names)
  readr::write_tsv(county_data, path=viz[['location']])
}
