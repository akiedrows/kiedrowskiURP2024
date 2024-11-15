import skimage as ski
from skimage import io, color
import numpy as np
import os
import pandas as pd
from skimage.color import label2rgb
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import matplotlib.colors as mcolors

input_seg_file = '/grid/meyer/home/akiedrow/photofiles/hu_cd45_63x_2_s8/hu_cd45_63x_2_s8_seg.npy'
input_clusters = '/grid/meyer/home/akiedrow/results/hu_cd45_63x_2_s8/object_clusters8_separated.csv'
output_dir = '/grid/meyer/home/akiedrow/results/hu_cd45_63x_2_s8'

basename = os.path.splitext(os.path.basename(input_clusters))[0]

#save image
def save_image(filename, image):
    filepath = os.path.join(output_dir, filename)
    print(f"Saving image to {filepath} with shape {image.shape} and dtype {image.dtype}")
    io.imsave(filepath, image)
    print(f'Saved {filepath}')


data = np.load(input_seg_file, allow_pickle=True).item()
masks = data['masks'] #from seg
props_df = pd.read_csv(input_clusters)


# Determine the number of unique clusters in the CSV file
#unique_clusters = props_df['cluster'].nunique()

# Generate colors dynamically for the number of unique clusters
#color_map = cm.get_cmap('tab20', unique_clusters)  # Or another colormap of your choice
#cluster_colors = {cluster: (np.array(color_map(i)[:3]) * 255).astype(int) 
#                  for i, cluster in enumerate(sorted(props_df['cluster'].unique()))}

cluster_colors = {
    #1: [255, 0, 0],       #red
    #2: [144, 238, 144],   #lightgreen
    #3: [0, 80, 255],       #blue
    #4: [255, 192, 203],   #pink
    #5: [255, 165, 0],     #orange
    #6: [137, 112, 210],     #purple
    #7: [255, 255, 0],     #yellow
    #8: [0, 255, 255],      #cyan

    1: [27,158,119],       #darkish green
    2: [217,95,2],   #burnt orange
    3: [117,112,179],       #periwinkle
    4: [231,41,138],   #hot pink
    5: [102,166,30],     #lime green
    6: [230,171,2],     #burnt yellow
    #6: [166,118,29],     #brown bear brown
    #8: [102,102,102]      #dark gray

    #I isolated the clusters by changing out the unneeded channels with black 
    #0: [0, 0, 0], #black
    #1: [0, 0, 0], #black
    #2: [0, 0, 0], #black
    #3: [0, 0, 0], #black
    #4: [0, 0, 0], #black
    #5: [0, 0, 0], #black
    #6: [0, 0, 0] #black
    #8: [0, 0, 0] #black
}

#creates a color image with 3 channels
colored_image = np.zeros((masks.shape[0], masks.shape[1], 3), dtype=np.uint8)

#slower
#make masks cluster colored
#for i, row in props_df.iterrows(): 
#    object_index = row['object_index'] #csv column data
#    cluster = row['cluster'] #csv column data
#    colored_image[masks == object_index] = cluster_colors.get(cluster)  
#    print(f"Object_index: {object_index} complete")

object_cluster_dict = {row['object_index']: row['cluster'] for i, row in props_df.iterrows()}

#pixel by pixel is way faster than mask by mask
for x in range(masks.shape[0]):
    for y in range(masks.shape[1]):
        object_index = masks[x, y]
        if object_index in object_cluster_dict:
            cluster = object_cluster_dict[object_index]
            colored_image[x, y] = cluster_colors.get(cluster)

colored_image = colored_image.astype(np.uint8)


output_filename = f'{basename}_colored_clustertitle_pheatmap.png'
save_image(output_filename, colored_image)

