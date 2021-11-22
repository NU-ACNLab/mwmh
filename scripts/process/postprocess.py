### This script conducts the post-processing steps after fmriprep
### https://nbviewer.org/github/sathayas/JupyterfMRIFall2019/blob/master/Level1.ipynb
###
### Ellyn Butler
### November 22, 2021

import os
#import matplotlib.pyplot as plt
#import matplotlib.image as mpimg
import pandas as pd
import nibabel as nib   # nibabel to read TR from image header
import nipype.interfaces.fsl as fsl # importing FSL interface functions
from nipype import Node, Workflow  # components to construct workflow
from nipype.interfaces.io import DataSink  # datasink
from nipype.algorithms import modelgen  # GLM model generator
from nipype.interfaces.base import Bunch
from bids.layout import BIDSLayout  # BIDSLayout object to specify file(s)
from templateflow import api as tflow
from nilearn.input_data import NiftiLabelsMasker

##### DIRECTORY BUSINESS ######
# original data directory
dataDir = '/projects/b1108/data/MWMH'
# Output directory
outDir = os.path.join(dataDir, 'amygconn')

##### PARAMETERS TO BE USED #####
nDelfMRI = 10

#############################################################################
# SPECIFYING THE FMRI DATA AND OTHER IMAGE FILES
#############################################################################

# directory where preprocessed fMRI data is located
baseDir = os.path.join(dataDir, 'fmriprep')
subjDir = os.path.join(baseDir, 'sub-MWMH117')
sesDir = os.path.join(subjDir, 'ses-1/func')

# location of the pre-processed fMRI & mask
fList = os.listdir(sesDir)
imagefMRI = [x for x in fList if ('preproc_bold.nii.gz' in x)][0]
imageMask = [x for x in fList if ('brain_mask.nii.gz' in x)][0]

filefMRI = os.path.join(sesDir, imagefMRI)
fileMask = os.path.join(sesDir, imageMask)

# skip dummy scans
extract = Node(fsl.ExtractROI(in_file=filefMRI, t_min=nDelfMRI, t_size=-1),
    name='extract')

# smoothing with SUSAN
susan = Node(fsl.SUSAN(brightness_threshold = 2000.0, fwhm=6.0), name='susan')

# masking the fMRI with a brain mask
applymask = Node(fsl.ApplyMask(mask_file=fileMask), name='applymask')

# creating the workflow
smoothandmask = Workflow(name='SmoothAndMask', base_dir=outDir)

# connecting nodes
smoothandmask.connect(extract, 'roi_file', susan, 'in_file')
smoothandmask.connect(susan, 'smoothed_file', applymask, 'in_file')

# running the workflow
smoothandmask.run()

# Create masker object
masker = NiftiLabelsMasker(labels_img='MNI152NLin2009cAsym', standardize=True)

#
confounds_file = os.path.join(sesDir, [x for x in fList if ('confounds_timeseries.tsv' in x)][0])
time_series = masker.fit_transform(filefMRI, confounds=confounds_file)
