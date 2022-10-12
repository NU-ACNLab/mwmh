### This script defines a function to run power spectral interpolation over every
### voxel in a nifti image
### https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.lombscargle.html
###
### Ellyn Butler
### October 12, 2022

def power_interp(img_cen, mask, tr):
    mask_array = mask.get_fdata()
    voxels =
    for i, j, k in voxels:



#https://stackoverflow.com/questions/25438420/indexes-of-elements-in-numpy-array-that-satisfy-conditions-on-the-value-and-the
