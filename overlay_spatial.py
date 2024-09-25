import skimage as ski
from skimage import io, color, exposure
import numpy as np
import os
import pandas as pd
import matplotlib.pyplot as plt

input_colored_file = '0726_03/object_clusters8_separated_colored.png'
input_tif_file = '0726_cd4_cd8/DAPI_0726_02.tif'
output_dir = '0726_03'

# Save image function
def save_image(filename, image):
    filepath = os.path.join(output_dir, filename)
    print(f"Saving image to {filepath} with shape {image.shape} and dtype {image.dtype}")
    io.imsave(filepath, image)
    print(f'Saved {filepath}')


original_image = io.imread(input_tif_file)
img_rescaled = exposure.rescale_intensity(original_image, in_range='image', out_range=np.uint8)
img_rescaled_color = np.dstack((img_rescaled, img_rescaled, img_rescaled))
save_image('img_rescaled_uint8.png', img_rescaled_color) #check



colored_image = io.imread(input_colored_file)
colored_image_rgba = np.concatenate([colored_image, np.ones((colored_image.shape[0], colored_image.shape[1], 1)) * 0.5], axis=-1)
colored_image_uint8 = (colored_image_rgba * 255).astype(np.uint8)
save_image('colored_image_unint8.png', colored_image_uint8)


print(img_rescaled_color.shape)
print(colored_image_rgba.shape)

#combined_image = ski.color.label2rgb(colored_image, image=img_rescaled_color, alpha=0.5)
combined_image = ski.color.label2rgb(colored_image_rgba, image=img_rescaled_color, alpha=0.5)
combined_image = combined_image.astype(np.uint8) 


save_image('overlayed_combined.png', combined_image)

print("complete")