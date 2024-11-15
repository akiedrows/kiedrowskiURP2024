# kiedrowskiURP2024

### Purpose:
Using only a nuclear stain, we can group the cells using Euclidean hierarchical clustering to see if there is a phenotypic difference in the nucleus during the T cell maturation process in the thymus.

### Order of execution:
1. Cellpose segmentation on dapi channel ([Cellpose github](https://github.com/MouseLand/cellpose))    
2. With seg file and original tif file, execute cellpose_segmentation/index_components for all channels (dapi, cd4, cd8, etc)  
3. Combine property tables with mergeproperties.R  
4. pheatmap.R for if you want to annotate for multiple clone channels, or pheatmap_dapi for if only analyzing dapi    
5. map_colored_clusters.py uses the clusters from the output of pheatmap and displays them on the original seg masks  
6. overlay_spatial will make the masks semi-transparent and map ontop of the original tif image

For further information: email me @ akiedrowski2@mail.niagara.edu
