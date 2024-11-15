#was meanintensity.r renamed to mergeproptables.r

library(ggplot2)

output_dir <- "/grid/meyer/home/akiedrow/results/cd4_cd8_63x_1_s8"
dapi <- read.csv("/grid/meyer/home/akiedrow/results/cd4_cd8_63x_1_s8/cd4_cd8_63x_1_s8_dapi/cd4_cd8_63x_1_s8_dapi_propertiestable.csv")
cd4 <- read.csv("/grid/meyer/home/akiedrow/results/cd4_cd8_63x_1_s8/cd4_cd8_63x_1_s8_cd4/cd4_cd8_63x_1_s8_cd4_propertiestable.csv")
cd8 <- read.csv("/grid/meyer/home/akiedrow/results/cd4_cd8_63x_1_s8/cd4_cd8_63x_1_s8_cd8/cd4_cd8_63x_1_s8_cd8_propertiestable.csv")

#dapi <- read.csv("/grid/meyer/home/akiedrow/results/hu_cd45_20x_1_s4/hu_cd45_20x_1_s4_dapi/hu_cd45_20x_1_s4_dapi_propertiestable.csv")
#cd45 <- read.csv("/grid/meyer/home/akiedrow/results/hu_cd45_20x_1_s4/hu_cd45_20x_1_s4_cd45/hu_cd45_20x_1_s4_cd45_propertiestable.csv")


rename_columns <- function(df, prefix) {
  cols <- colnames(df)
  new_cols <- ifelse(cols %in% c("label", "centroid.0", "centroid.1","area","axis_major_length","axis_minor_length", "eccentricity"), 
                     cols, 
                     paste0(prefix, "_", cols))
  colnames(df) <- new_cols
  df[c("centroid.0", "centroid.1", "area","axis_major_length","axis_minor_length", "eccentricity")] <- round(df[c("centroid.0", 
                     "centroid.1", "area","axis_major_length","axis_minor_length", "eccentricity")], digits = 9)
  return(df)
}

dapi <- rename_columns(dapi, "DAPI")
cd4 <- rename_columns(cd4, "CD4")
cd8 <- rename_columns(cd8, "CD8")
#cd45 <- rename_columns(cd45, "CD45")

common_columns <- c("label", "centroid.0", "centroid.1","area","axis_major_length","axis_minor_length", "eccentricity")
combined_data <- Reduce(function(x, y) merge(x, y, by=common_columns, all=TRUE), list(dapi, cd4, cd8))
#combined_data <- Reduce(function(x, y) merge(x, y, by=common_columns, all=TRUE), list(dapi, cd45))

write.csv(combined_data, file.path(output_dir,"combined_propertiestable.csv"), row.names = FALSE)


