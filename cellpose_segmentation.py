import skimage as ski
from skimage import io, color
import numpy as np
import os

#seg file comes from Cellpose - either run the model or edit, saves to it should be automatic
#tif comes from Fiji -> czi save as tif
#have them in the same folder, dilutions is the one all of my currect experiment images are in
#you can also set your dir in its own line if you want

#for hpc
#input_seg_file = '../photofiles/cd4_cd8_63x_2_s8/cd4_cd8_63x_2_s8_seg.npy'
#input_tif_file = '../photofiles/cd4_cd8_63x_2_s8/cd4_cd8_63x_2_s8_dapi.tif'

input_seg_file = '../photofiles/hu_cd45_63x_1_s8/hu_cd45_63x_1_s8_seg.npy'
input_tif_file = '../photofiles/hu_cd45_63x_1_s8/hu_cd45_63x_1_s8_dapi.tif'

#input_seg_file = snakemake.input.og_seg_file
#input_tif_file = snakemake.input.components


buffer_size = 20


#for 63x
#micron_width= 6
#micron_length_of_square_image= 134.26
#3804x3804 pixels

#new folder
basename = os.path.splitext(os.path.basename(input_tif_file))[0]
dirname = f'{basename}_segmentation_cellpose'
output_dir = "../results/%s" %basename
os.makedirs(output_dir, exist_ok=True)
print("Directory successfully made")

#saves images in the folder
def save_image(filename, image):
    filepath = os.path.join(output_dir, filename)
    print(f"Saving image to {filepath} with shape {image.shape} and dtype {image.dtype}")
    if image.dtype == bool:
        image = image.astype('uint8') * 255
    elif image.dtype == np.float64:
        image = (image * 255).astype('uint8')
    print(f"Image converted to dtype {image.dtype}")
    io.imsave(filepath, image)
    print(f'Saved {filepath}')


################################################################################
#load segmentation output
data = np.load(input_seg_file, allow_pickle=True).item()
labels = data['masks']
image = io.imread(input_tif_file)

#Rescaling original image for cutting out objects
img_rescaled = ski.exposure.rescale_intensity(image, in_range='image', out_range='dtype')
save_image(f'{basename}_original_rescaled.tif', img_rescaled)


#label connected components
# print("Labeling connected components")
# labels = measure.label(masks)

#save labeled image#
labels_color = color.label2rgb(labels, bg_label=0)
save_image(f'{basename}_labeled.png', labels_color)
np.save(os.path.join(output_dir, f'{basename}_labels.npy'), labels)
print("Labeled image and labels array saved")

################################################################################
import index_components

#img_gray = image if image.ndim == 2 else image[:, :, 0]

index_components.properties_table(labels, image, basename, output_dir)
#index_components.properties_table(labels, image, snakemake.output.properties)

index_components.histograms(basename, output_dir)

index_components.save_ROIs(buffer_size, img_rescaled, basename, output_dir) 

index_components.isolate_ROIs(buffer_size, image, labels, basename, output_dir)


################################################################################
print("Pipeline complete. Input csv into mergeproptable.r")
