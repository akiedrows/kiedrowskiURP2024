library(pheatmap)
library(RColorBrewer)
library(ggplot2)
library(gridExtra)

output_dir <- "directories/0802_01"
csv_file <- file.path(output_dir, "combined_propertiestable.csv")
props_df <- read.csv(csv_file)

# 100-400 pixels
props_df <- props_df[props_df$area > 300 & props_df$area < 1300, ]
object_labels <- props_df$label

# Remove unnecessary columns and keep mean intensity separately
mean_intensity_df <- props_df[, c("CD4_mean_intensity", "CD8_mean_intensity")]
#14,20
#, 9, 12, 15, 16, 17, 18, 19, 21, 22, 23, 24, 25
props_df <- props_df[, -c(1, 2, 3, 9, 12, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25)]
props_df <- props_df[, sapply(props_df, is.numeric)]

# Threshold function
cap_threshold <- function(x, threshold = 3) {
  x_mean <- mean(x, na.rm = TRUE)
  x_sd <- sd(x, na.rm = TRUE)
  x_cap <- pmin(pmax(x, x_mean - threshold * x_sd), x_mean + threshold * x_sd)
  return(x_cap)
}
props_df <- as.data.frame(lapply(props_df, cap_threshold))

# Heatmap color palette and breaks
color_divisions <- 100
color_palette <- colorRampPalette(c("navy", "white", "red"))(color_divisions)
breaks <- seq(-6, 6, length.out = (color_divisions + 1))

# Save original heatmap
output_heatmap_file <- file.path(output_dir, "heatmapclustered8_separated.png")
png(output_heatmap_file, width = 800, height = 800)

# Generate non-annotated heatmap, will use this plot to make csv for cluster groups
out <- pheatmap(props_df, 
                cluster_rows = TRUE,  
                cluster_cols = TRUE,
                scale = "column",   
                breaks = breaks,
                border_color = FALSE,
                show_rownames = FALSE,  # objects
                show_colnames = TRUE,  # properties
                angle_col = 45,
                fontsize = 7,
                cex = 1,
                clustering_distance_rows = "euclidean", 
                clustering_method = "complete",
                color = color_palette)

dev.off()

# Number of clusters
num_clusters <- 8
clusters <- cutree(out$tree_row, k = num_clusters)

# Headers
rownames(props_df) <- paste("Object", object_labels)

row_annotation_cluster <- data.frame(cluster = as.factor(clusters))
rownames(row_annotation_cluster) <- rownames(props_df)

# Save to csv to be used in next step
cluster_df <- data.frame(object_index = object_labels, cluster = clusters)
write.csv(cluster_df, file.path(output_dir, "object_clusters8_separated.csv"), row.names = FALSE)

# Uses cluster numbers from csv
cluster_file <- file.path(output_dir, "object_clusters8_separated.csv")
cluster_df <- read.csv(cluster_file)

# Cluster_df index match object_labels
props_df_filtered <- props_df[as.character(rownames(props_df)) %in% paste("Object", cluster_df$object_index), ]
props_df_numeric <- props_df_filtered[, sapply(props_df_filtered, is.numeric)]

#colors for each cluster
unique_clusters <- sort(unique(cluster_df$cluster))
cluster_colors <- c("#1b9e77", "#d95f02", "#7570b3", "#e7298a", "#66a61e", "#e6ab02", "#a6761d", "#666666", "magenta", "grey", "indianred", "lavenderblush","darkblue","deepskyblue3","forestgreen")[1:length(unique_clusters)]

#map cluster colors to annotations
cluster_colors_map <- setNames(cluster_colors, unique_clusters)
annotation_row_cluster <- data.frame(cluster = factor(cluster_df$cluster, levels = unique_clusters))
rownames(annotation_row_cluster) <- paste("Object", cluster_df$object_index)
ann_colors_cluster <- list(cluster = cluster_colors_map)

# Ensure mean_intensity_df columns are numeric
mean_intensity_df$CD4_mean_intensity <- as.numeric(mean_intensity_df$CD4_mean_intensity)
mean_intensity_df$CD8_mean_intensity <- as.numeric(mean_intensity_df$CD8_mean_intensity)

# Define colors for continuous annotations
cd4_colors <- c('#FFFFFF', '#E1E8E1', '#C2D0C2', '#84A184', '#477246', '#094208')
cd8_colors <- c('#FFFFFF', '#F4E0E0', '#E8C0C0', '#D08080', '#B94040', '#A10000')

# Custom quantile labels
quantile_labels <- function(x, probs = seq(0, 1, by = 0.2), labels = NULL) {
  if (is.null(labels)) {
    labels <- c("0-20%", "20-40%", "40-60%", "60-80%", "80-100%")
  }
  cut(x, breaks = quantile(x, probs, na.rm = TRUE), include.lowest = TRUE, labels = labels)
}

mean_intensity_df$CD4_quantile <- quantile_labels(mean_intensity_df$CD4_mean_intensity, labels = c("0-20%", "20-40%", "40-60%", "60-80%", "80-100%"))
mean_intensity_df$CD8_quantile <- quantile_labels(mean_intensity_df$CD8_mean_intensity, labels = c("0-20%", "20-40%", "40-60%", "60-80%", "80-100%"))

# Map colors to quantiles
cd4_color_map <- setNames(cd4_colors[1:5], levels(mean_intensity_df$CD4_quantile))
cd8_color_map <- setNames(cd8_colors[1:5], levels(mean_intensity_df$CD8_quantile))

# Annotation for heatmap
annotation_row <- data.frame(cluster = factor(cluster_df$cluster, levels = unique_clusters),
                             CD4 = mean_intensity_df$CD4_quantile,
                             CD8 = mean_intensity_df$CD8_quantile)
rownames(annotation_row) <- paste("Object", cluster_df$object_index)
ann_colors <- list(cluster = cluster_colors_map,
                   CD4 = cd4_color_map,
                   CD8 = cd8_color_map)

# Generate and save the annotated heatmap
output_heatmap_file <- file.path(output_dir, "heatmapclustered8_annotated.png")
png(output_heatmap_file, width = 800, height = 800)

pheatmap(props_df_numeric, 
         cluster_rows = TRUE,  
         cluster_cols = TRUE,
         scale = "column",   
         breaks = breaks,
         border_color = FALSE,
         show_rownames = FALSE,  # objects
         show_colnames = TRUE,  # properties
         angle_col = 45,
         fontsize = 10,
         cex = 1,
         clustering_distance_rows = "euclidean", 
         clustering_method = "complete",
         color = color_palette,
         annotation_row = annotation_row,
         annotation_colors = ann_colors)

dev.off()

# Histograms for each cluster
create_histograms_grid <- function(df, clusters, output_dir) {
  cluster_list <- split(df, clusters)
  
  for (cluster in names(cluster_list)) {
    cluster_data <- cluster_list[[cluster]]
    plots <- list()
    
    for (feature in colnames(cluster_data)) {
      if (is.numeric(cluster_data[[feature]])) {  # Check if the feature is numeric
        p <- ggplot(cluster_data, aes_string(x = feature)) +
          geom_histogram(bins = 30, fill = cluster_colors_map[cluster], color = "black", alpha = 0.7) +
          labs(x = paste("Cluster", cluster, "-", feature), y = "Count") +
          theme_classic()
        plots[[feature]] <- p
      }
    }
    
    output_file <- file.path(output_dir, paste0("cluster", cluster, "_histogram.png"))
    png(output_file, width = 800, height = 800)
    do.call(gridExtra::grid.arrange, c(plots, ncol = 2))
    dev.off()
  }
}

create_histograms_grid(props_df_filtered, cluster_df$cluster, output_dir)





#dotplot with clusters
mean_intensity_df$CD4_mean_intensity <- as.numeric(mean_intensity_df$CD4_mean_intensity)
mean_intensity_df$CD8_mean_intensity <- as.numeric(mean_intensity_df$CD8_mean_intensity)
mean_intensity_df$cluster <- cluster_df$cluster

mean_intensity_df$z_scores_CD4 <- (mean_intensity_df$CD4_mean_intensity-mean(mean_intensity_df$CD4_mean_intensity))/sd(mean_intensity_df$CD4_mean_intensity)
mean_intensity_df$z_scores_CD8 <- (mean_intensity_df$CD8_mean_intensity-mean(mean_intensity_df$CD8_mean_intensity))/sd(mean_intensity_df$CD8_mean_intensity)

plot <- ggplot(mean_intensity_df, aes(x = z_scores_CD4,
                                      y = z_scores_CD8,
                                      color = as.factor(cluster),
                                      fill = as.factor(cluster))) +
  scale_color_manual(values = cluster_colors_map) +
  geom_point(size = 3, alpha = 0.9)+

  #facet_grid(~as.factor(cluster)) +

  labs(x = "CD4 Mean Intensity", y = "CD8 Mean Intensity") +
  theme_classic()


ggsave(file.path(output_dir, "mean_intensity_dotplot.png"), plot, width = 11, height = 11)

