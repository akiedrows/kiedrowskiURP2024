library(ggplot2)

output_dir <- "0802_01"
dapi <- read.csv("0802_01/DAPI_cd4_cd8_cd45-crop-1_segmentation_cellpose/DAPI_cd4_cd8_cd45-crop-1_propertiestable.csv")
cd4 <- read.csv("0802_01/CD4_cd4_cd8_cd45-crop-1_segmentation_cellpose/CD4_cd4_cd8_cd45-crop-1_propertiestable.csv")
cd8 <- read.csv("0802_01/CD8_cd4_cd8_cd45-crop-1_segmentation_cellpose/CD8_cd4_cd8_cd45-crop-1_propertiestable.csv")


rename_columns <- function(df, prefix) {
  cols <- colnames(df)
  new_cols <- ifelse(cols %in% c("label", "centroid.0", "centroid.1","area","axis_major_length","axis_minor_length", "eccentricity"), 
                     cols, 
                     paste0(prefix, "_", cols))
  colnames(df) <- new_cols
  return(df)
}

dapi <- rename_columns(dapi, "DAPI")
cd4 <- rename_columns(cd4, "CD4")
cd8 <- rename_columns(cd8, "CD8")

common_columns <- c("label", "centroid.0", "centroid.1","area","axis_major_length","axis_minor_length", "eccentricity")
combined_data <- Reduce(function(x, y) merge(x, y, by=common_columns, all=TRUE), list(dapi, cd4, cd8))

#dot plot for mean intensities
#plot <- ggplot(combined_data, aes(x = label)) +
#  geom_point(aes(y = DAPI_mean_intensity, color = "DAPI")) +
#  geom_point(aes(y = CD4_mean_intensity, color = "CD4")) +
#  geom_point(aes(y = CD8_mean_intensity, color = "CD8")) +
#  scale_color_manual(values = c("DAPI" = "blue", "CD4" = "green", "CD8" = "red")) +
#  labs(x = "Label",
#       y = "Mean Intensity") +
#  theme_classic()

#cd4 on x cd8 on y, points are mean_intensity
#plot <- ggplot(combined_data, aes(x = CD4_mean_intensity, y = CD8_mean_intensity)) +
#  geom_point() +
#  labs(x = "CD4 Mean Intensity", y = "CD8 Mean Intensity") +
#  theme_classic()



#ggsave(file.path(output_dir,"mean_intensity_dotplot.png"), plot)
write.csv(combined_data, file.path(output_dir,"combined_propertiestable.csv"), row.names = FALSE)

#get rid of all asm and intensity_std


