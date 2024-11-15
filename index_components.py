import skimage as ski
from skimage import io
from skimage.measure import regionprops_table
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import os
from skimage.feature import graycomatrix, graycoprops

#for snakemake, remove basename+output_dir replace with outputfile

def properties_table(index_labels, img_rescaled, basename, output_dir):
    print("Calculating region properties for watershed segmented labels")

    props = regionprops_table(index_labels, intensity_image=img_rescaled, properties=(
                'label', 'centroid', 'area', 'mean_intensity', 'intensity_std','eccentricity', 'axis_major_length', 'axis_minor_length'))

    print("Region properties calculated")

    props_df = pd.DataFrame(props)
    props_df.to_csv(os.path.join(output_dir, f'{basename}_propertiestable.csv'), index=False)
    #props_df.to_csv(outputfile, index=False)
    

    print("Properties table saved")
    print(props_df)

    num_rows = len(props_df)
    print(f"The CSV file has {num_rows} rows")
    return props_df

def histograms(basename, output_dir):
    props_df_path = os.path.join(output_dir, f'{basename}_propertiestable.csv')
    props_df = pd.read_csv(props_df_path)

    columns_to_plot = ['area', 'mean_intensity', 'intensity_std', 'eccentricity', 'axis_major_length', 'axis_minor_length']
    fig, axes = plt.subplots(2, 3, figsize=(15, 10))

    for ax, column in zip(axes.flatten(), columns_to_plot):
        ax.hist(props_df[column], bins=30)
        ax.set_title(column)
        ax.set_xlabel('Value')
        ax.set_ylabel('Frequency')

    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, f'{basename}_histograms.png'))

    print("Histogram plots saved")

def save_ROIs(buffer_size, img_rescaled, basename, output_dir):
    blobs_img_path = os.path.join(output_dir, f'{basename}_labeled.png')
    props_df_path = os.path.join(output_dir, f'{basename}_propertiestable.csv')

    blobs_img = io.imread(blobs_img_path)
    props_df = pd.read_csv(props_df_path)

    centroids = np.array(list(zip(props_df['centroid-1'], props_df['centroid-0'])))
    labels = props_df['label'].values
    areas = props_df['area'].values
    axis_major_lengths = props_df['axis_major_length'].values

    objects_output_dir = os.path.join(output_dir, 'objects')
    os.makedirs(objects_output_dir, exist_ok=True)

    for (x, y), label in zip(centroids, labels):
            half_box_size = int(axis_major_lengths[label - 1] // 2 + buffer_size)
            x_min = int(x - half_box_size)
            x_max = int(x + half_box_size)
            y_min = int(y - half_box_size)
            y_max = int(y + half_box_size)

            x_min = max(x_min, 0)
            x_max = min(x_max, blobs_img.shape[1])
            y_min = max(y_min, 0)
            y_max = min(y_max, blobs_img.shape[0])

            object_img = img_rescaled[y_min:y_max, x_min:x_max]

            if np.any(object_img):
                object_filename = f'object{label:04d}.png'
                object_filepath = os.path.join(objects_output_dir, object_filename)

                # comment out if you do not want to save every image, only needed for sanity check
                # needed if wanting to print isolate roi images
                if object_img.dtype != np.uint16:
                    object_img = (object_img / np.max(object_img) * 65535).astype(np.uint16)
                
                io.imsave(object_filepath, object_img)
                print(f"Saved {object_filepath}")
            else:
                print(f"{label} at ({x}, {y}) is empty, skipping save.")

    print("All objects with pixel area 10000-30000 saved")

def grayco_features(isolated_img_gray):
    P = graycomatrix(isolated_img_gray, distances=[1], angles=[0], levels=256, symmetric=True, normed=True)
    contrast = graycoprops(P, 'contrast')[0, 0]
    homogeneity = graycoprops(P, 'homogeneity')[0, 0]
    ASM = graycoprops(P, 'ASM')[0, 0]
    correlation = graycoprops(P, 'correlation')[0, 0]      
    return contrast, homogeneity, ASM, correlation


def isolate_ROIs(buffer_size, image, masks, basename, output_dir):
    # blobs_img_path = os.path.join(output_dir, f'{basename}_seg.npy')
    props_df_path = os.path.join(output_dir, f'{basename}_propertiestable.csv')

    #props_df_path = os.path.join(output_dir, 'CD4_cd4_cd8_cd45-crop-1_propertiestable32.csv')

    # blobs_img = io.imread(blobs_img_path)
    blobs_img = masks
    props_df = pd.read_csv(props_df_path)

    centroids = np.array(list(zip(props_df['centroid-1'], props_df['centroid-0'])))
    labels = props_df['label'].values
    areas = props_df['area'].values
    axis_major_lengths = props_df['axis_major_length'].values

    isolated_objects_dir = os.path.join(output_dir, 'isolated_objects')
    os.makedirs(isolated_objects_dir, exist_ok=True)

    grayco_data = [] 

    for (x, y), label in zip(centroids, labels):
        half_box_size = int(axis_major_lengths[label - 1] // 2 + buffer_size)
        x_min = int(x - half_box_size)
        x_max = int(x + half_box_size)
        y_min = int(y - half_box_size)
        y_max = int(y + half_box_size)

        # Ensure coordinates are within image bounds
        x_min = max(x_min, 0)
        x_max = min(x_max, blobs_img.shape[1])
        y_min = max(y_min, 0)
        y_max = min(y_max, blobs_img.shape[0])

        isolated_img = np.zeros_like(blobs_img[y_min:y_max, x_min:x_max], dtype=np.uint16)
            

        for i in range(y_min, y_max):
            for j in range(x_min, x_max):
                if masks[i, j] == label:
                    isolated_img[i - y_min, j - x_min] = 1
                
        isolated_object_img = image[y_min:y_max, x_min:x_max]

        isolated_with_values = isolated_object_img * isolated_img
        isolated_with_values_scaled = ski.exposure.rescale_intensity(isolated_with_values, in_range='image', out_range=np.uint8)
        contrast, homogeneity, ASM, correlation = grayco_features(isolated_with_values_scaled)
        #print(contrast, homogeneity, ASM, correlation)
        #contrast, homogeneity, ASM, correlation, P = grayco_features(isolated_with_values)
        grayco_data.append({'label': label, 'contrast': contrast, 'homogeneity':homogeneity, 'ASM':ASM, 'correlation':correlation})
        # comment out if you do not want to save every image, only needed for sanity check
        isolated_object_filename = f'isolated_object{label:04d}.png'
        isolated_object_filepath = os.path.join(isolated_objects_dir, isolated_object_filename)
        io.imsave(isolated_object_filepath, isolated_with_values_scaled)
        print(f"Saved {isolated_object_filepath}")
        print(label)
            

    grayco_df = pd.DataFrame(grayco_data)
    #grayco_df.to_csv(os.path.join(output_dir, f'{basename}_graycotable.csv'), index=False) #add label number
    combined_df = props_df.merge(grayco_df, on='label', how='left')
    updated_props_path = os.path.join(output_dir, f'{basename}_propertiestable.csv')
    combined_df.to_csv(updated_props_path, index=False)

    print("All grayco features saved to properties table")
