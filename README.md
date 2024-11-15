# kiedrowskiURP2024

# Order of execution:
# Cellpose segmentation on dapi channel (Cellpose github)
# With seg file and original tif file, execute cellpose_segmentation/index_components for all channels (dapi, cd4, cd8, etc)
# Combine property tables with mean_intensity.R
# pheatmap.R for if you want to annotate for multiple clone channels, or pheatmap_dapi for if only analyzing dapi
# map_colored_clusters.py uses the clusters from the output of pheatmap and displays them on the original seg masks
# overlay_spatial will use make the masks transparent so you can see it ontop of the original tif image
