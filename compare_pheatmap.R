library(pheatmap)
library(RColorBrewer)
library(ggplot2)
library(gridExtra)
library(grid)


output_dir <- "/grid/meyer/home/akiedrow/results/63x_hu_mouse"

#load human
human_csv_file <- file.path(output_dir, "hu_cd45_63x_1_s8_dapi_propertiestable.csv")
human_cluster_file <- file.path(output_dir, "human_object_clusters8_separated.csv")
human_props_df <- read.csv(human_csv_file)
human_cluster_df <- read.csv(human_cluster_file)

colnames(human_props_df) <- gsub("mean_intensity", "DAPI_mean_intensity", colnames(human_props_df))
colnames(human_props_df) <- gsub("contrast", "DAPI_contrast", colnames(human_props_df))
colnames(human_props_df) <- gsub("homogeneity", "DAPI_homogeneity", colnames(human_props_df))

human_samples <- sample(seq(1:nrow(human_props_df)), 30000, replace = F)

human_props_df <- human_props_df[human_samples,]
human_cluster_df <- human_cluster_df[human_samples,]

rownames(human_props_df) <- paste0("h_", human_props_df$label)
rownames(human_cluster_df) <- paste0("h_", human_cluster_df$object_index)

human_props_df <- human_props_df[, c("area", "eccentricity", "DAPI_mean_intensity", 
                                     "DAPI_contrast", "DAPI_homogeneity")]
human_cluster_df$model <- "h" 

#load mouse
mouse_csv_file <- file.path(output_dir, "mouse_combined_propertiestable.csv")
mouse_cluster_file <- file.path(output_dir, "mouse_object_clusters8_separated.csv")
mouse_props_df <- read.csv(mouse_csv_file)
mouse_cluster_df <- read.csv(mouse_cluster_file)

mouse_samples <- sample(seq(1:nrow(mouse_props_df)), 30000, replace = F)

mouse_cluster_df <- mouse_cluster_df[mouse_samples,]
mouse_props_df <- mouse_props_df[mouse_samples,]

rownames(mouse_props_df) <- paste0("m_", mouse_props_df$label)
rownames(mouse_cluster_df) <- paste0("m_", mouse_cluster_df$object_index)

mouse_props_df <- mouse_props_df[, c("area", "eccentricity", "DAPI_mean_intensity", 
                                     "DAPI_contrast", "DAPI_homogeneity")]
mouse_cluster_df$model <- "m" 


#bind into one df
props_df <- rbind(human_props_df, mouse_props_df)
cluster_df <- rbind(human_cluster_df, mouse_cluster_df)


cluster_df <- cluster_df[, c("cluster", "model")]
cluster_df$cluster <- paste0(cluster_df$model, cluster_df$cluster)

annotation_row <- cluster_df[, "model", drop = FALSE]

# Threshold function
cap_threshold <- function(x, threshold = 3) {
  x_mean <- mean(x, na.rm = TRUE)
  x_sd <- sd(x, na.rm = TRUE)
  x_cap <- pmin(pmax(x, x_mean - threshold * x_sd), x_mean + threshold * x_sd)
  return(x_cap)
}

#applies threshold, 
#props_df <- as.data.frame(lapply(props_df[, -ncol(props_df)], cap_threshold))  
#props_df <- as.data.frame(lapply(cluster_df[, -ncol(props_df)], cap_threshold)
#props_df_numeric$model <- props_df$model  


# Heatmap color palette and breaks
color_divisions <- 100
color_palette <- colorRampPalette(c("navy", "white", "red"))(color_divisions)
breaks <- seq(-6, 6, length.out = (color_divisions + 1))

# Save original heatmap
output_heatmap_file <- file.path(output_dir, "heatmapclustered8_separated.png")
png(output_heatmap_file, width = 2000, height = 2000, res = 300)

#output_heatmap_file <- file.path(output_dir, "heatmapcombined.pdf")

#output_heatmap_file <- file.path(output_dir, "heatmapcombined.emf")

#png(output_heatmap_file, emfPlus = FALSE)

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
                color = color_palette,
		annotation_row = annotation_row)

grid.draw(rectGrob(gp=gpar(fill="black", lwd=0)))
grid.draw(out)
grid.gedit("layout", gp = gpar(col = "white", text = ""))

dev.off()

# Number of clusters, saves new cluster file
#num_clusters <- 6
#clusters <- cutree(out$tree_row, k = num_clusters)
#cluster_df <- data.frame(object_index = rownames(props_df), cluster = clusters)
#write.csv(cluster_df, file.path(output_dir, "combined_df_clusters.csv"), row.names = FALSE)#

#cluster colors
#cluster_colors <- c("#1b9e77", "#d95f02", "#7570b3", "#e7298a", "#66a61e", "#e6ab02")
#cluster_colors_map <- setNames(cluster_colors, as.character(1:num_clusters))

#model colors
#human_color <- '#094208'
#mouse_color <- '#A10000'

#annotate data row
#annotation_row <- data.frame(cluster = factor(clusters), model = props_df_numeric$model)
#rownames(annotation_row) <- rownames(props_df_numeric)
#ann_colors <- list(cluster = cluster_colors_map, model = c("h" = human_color, "m" = mouse_color))

#colnames(annotation_row)

# Generate and save the annotated heatmap
#output_heatmap_file <- file.path(output_dir, "heatmapclustered_annotated_compare.png")
#png(output_heatmap_file, width = 800, height = 800)

#pheatmap(props_df_numeric[, -ncol(props_df_numeric)], #removes model from clustering
#         cluster_rows = TRUE,  
#         cluster_cols = TRUE,
#         scale = "column",   
#         breaks = breaks,
#         border_color = FALSE,
#         show_rownames = FALSE,  # objects
#         show_colnames = TRUE,  # properties
#         angle_col = 45,
#         fontsize = 10,
#         cex = 1,
#         clustering_distance_rows = "euclidean", 
#         clustering_method = "complete",
#         color = color_palette,
#         annotation_row = annotation_row,
#         annotation_colors = ann_colors)

#dev.off()




# Histograms for each cluster
#create_histograms_grid <- function(df, clusters, output_dir) {
#  cluster_list <- split(df, clusters)
  
#  for (cluster in names(cluster_list)) {
#    cluster_data <- cluster_list[[cluster]]
#    plots <- list()
    
#    for (feature in colnames(cluster_data)) {
#      if (is.numeric(cluster_data[[feature]])) {  # Check if the feature is numeric
#        p <- ggplot(cluster_data, aes_string(x = feature)) +
#          geom_histogram(bins = 30, fill = cluster_colors_map[cluster], color = "black", alpha = 0.7) +
#          labs(x = paste("Cluster", cluster, "-", feature), y = "Count") +
#          theme_classic()
#        plots[[feature]] <- p
#      }
#    }
    
#    output_file <- file.path(output_dir, paste0("cluster", cluster, "_histogram.png"))
#    png(output_file, width = 800, height = 800)
#    do.call(gridExtra::grid.arrange, c(plots, ncol = 2))
#    dev.off()
#  }
#}

#create_histograms_grid(props_df_numeric, cluster_df$cluster, output_dir)
