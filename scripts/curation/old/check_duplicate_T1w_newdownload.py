### This script checks if the duplicate T1w images in from the dicom download
### performed by Todd are identical. MWMH219 V2
###
### Ellyn Butler
### February 10, 2022

#import os
import glob
import numpy as np
import nibabel as nib
import pandas as pd

baseDir = '/home/erb9722/scratch/'

niftis = glob.glob(baseDir + "*_7*.nii")
niftis.append(glob.glob(baseDir + "*_8*.nii")[0])

firstT1w_img = nib.load(niftis[0])
firstT1w_array = firstT1w_img.get_fdata()

secondT1w_img = nib.load(niftis[1])
secondT1w_array = secondT1w_img.get_fdata()

thirdT1w_img = nib.load(niftis[2])
thirdT1w_array = thirdT1w_img.get_fdata()

np.array_equal(firstT1w_array, secondT1w_array)
np.array_equal(firstT1w_array, thirdT1w_array)
