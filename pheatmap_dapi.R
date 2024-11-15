library(pheatmap)
library(RColorBrewer)
library(ggplot2)
library(gridExtra)
library(grid)

output_dir <- "/grid/meyer/home/akiedrow/results/hu_cd45_63x_1_s8"
csv_file <- file.path(output_dir, "hu_cd45_63x_1_s8_dapi_propertiestable.csv")
props_df <- read.csv(csv_file)

#for 20x
#props_df <- props_df[props_df$area > 50 & props_df$area < 350, ]
#object_labels <- props_df$label

#use if over 60,000 cells
#samples <- sample(seq(1:nrow(props_df)), 60000, replace = F)

#props_df <- props_df[samples,]

object_labels <- props_df$label

# runs if all these columns exist in file
props_df <- props_df[, c("area", "eccentricity", "mean_intensity",
                         "contrast", "homogeneity")]

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
png(output_heatmap_file, width = 2000, height = 2000, res = 300)
#output_heatmap_file <- file.path(output_dir, "heatmap_human1_separated.pdf")
#pdf(output_heatmap_file, width = 7, height = 7)




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
                fontsize = 10,
                cex = 1,
                clustering_distance_rows = "euclidean", 
                clustering_method = "complete",
                color = color_palette)

grid.draw(rectGrob(gp=gpar(fill="black", lwd=0)))
grid.draw(out)
grid.gedit("layout", gp = gpar(col = "white", text = ""))

dev.off()

# Number of clusters
num_clusters <- 6
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

# Annotation for heatmap
annotation_row <- data.frame(cluster = factor(cluster_df$cluster, levels = unique_clusters))
rownames(annotation_row) <- paste("Object", cluster_df$object_index)
ann_colors <- list(cluster = cluster_colors_map)

# Generate and save the annotated heatmap
output_heatmap_file <- file.path(output_dir, "human_heatmapclustered8_annotated.png")
png(output_heatmap_file, width = 2000, height = 2000, res = 300)
#output_heatmap_file <- file.path(output_dir, "heatmap_human1_annotated.pdf")
#pdf(output_heatmap_file, width = 7, height = 7)

out <- pheatmap(props_df_numeric, 
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

grid.draw(rectGrob(gp=gpar(fill="black", lwd=0)))
grid.draw(out)
grid.gedit("layout", gp = gpar(col = "white", text = ""))

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
