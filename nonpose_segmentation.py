import skimage as ski
from skimage import io, measure#, color, exposure
#from skimage.measure import regionprops_table
from skimage.feature import peak_local_max
from skimage.filters import threshold_otsu#, difference_of_gaussians, window
from skimage.segmentation import watershed
from scipy import ndimage as ndi
#from scipy.fft import fftn, fftshift
#import matplotlib.pyplot as plt
import numpy as np
#import pandas as pd
import os
#import matplotlib.patches as patches

input_file = 'dilutions/DAPI_1-32_date_7_12_no_2.tif'
basename = os.path.splitext(os.path.basename(input_file))[0] 

min_area = 100
max_area = 400
buffer_size = 20

#new folder
output_dir = f'{basename}_segmentation_nonpose'
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

#reads the input image
print(f"Reading image: {input_file}")

image = io.imread(input_file)

print("Image read successfully")
print(f"Image shape: {image.shape}")

#Rescaling original image for cutting out objects
img_rescaled = ski.exposure.rescale_intensity(image, in_range='image', out_range='dtype')
save_image(f'{basename}_original_rescaled.tif', img_rescaled)

################################################################################
#Band-pass filtering
filtered_image = ski.filters.gaussian(image, sigma=4) #change second number

#for cellpose
save_image(f'{basename}_blur4.tif', filtered_image)

#for nonpose
#save_image(f'{basename}dapi_2_snal_1_blurred.tif', ski.exposure.rescale_intensity(filtered_image, in_range='image', out_range='dtype'))

print("Blurred channel saved")


################################################################################
#otsu thresholding for the first channel#
print("Applying Otsu thresholding to the filtered channel")

thresh = threshold_otsu(filtered_image)
binary_channel = filtered_image > thresh
save_image(f'{basename}_thresholded_image_channel_1.tif', binary_channel)

print("Otsu thresholding applied")

################################################################################
#labeling connected components#
print("Labeling connected components")

all_labels = measure.label(binary_channel)
blobs_labels, num_connected_comp = measure.label(binary_channel, background=0, return_num=True)

#print(num_connected_comp)
print("Connected components labeled")

np.save(os.path.join(output_dir, f'{basename}_blobs.npy'), blobs_labels)
blobs_labels_color = ski.color.label2rgb(blobs_labels, bg_label=0)
save_image(f'{basename}_blobs.png', blobs_labels_color)

print("Blobs labeled image saved")

################################################################################
#watershed segmentation#
print("Applying watershed segmentation")

#generates the markers as local maxima of the distance to the background
distance = ndi.distance_transform_edt(binary_channel)
coords = peak_local_max(distance, min_distance=3, labels=binary_channel) #set to 3
mask = np.zeros(distance.shape, dtype=bool)
mask[tuple(coords.T)] = True
markers, _ = ndi.label(mask)

#labels now has watershed applied
watershed_labels = watershed(-distance, markers, mask=binary_channel, 
                             connectivity=2, watershed_line=False)
print("Watershed segmentation applied")

save_image(f'{basename}_watershed_label.tif', watershed_labels)

watershed_labels_image = ski.color.label2rgb(watershed_labels, bg_label=0)
save_image(f'{basename}_labeled.png', watershed_labels_image)

################################################################################
import index_components

img_gray = image if image.ndim == 2 else image[:, :, 0]

index_components.properties_table(watershed_labels, img_gray, basename, output_dir)

index_components.histograms(basename, output_dir)

index_components.save_ROIs(min_area, max_area, buffer_size, img_rescaled, basename, output_dir)

index_components.isolate_ROIs(min_area, max_area, buffer_size, img_rescaled, watershed_labels, basename, output_dir)
################################################################################
print("Pipeline complete. Input csv into cluster10.r")