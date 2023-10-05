### This script takes the postprocessed functional niftis and puts them into
### fsLR32k space using neuromaps
###
### Ellyn Butler
### September 26, 2023

from neuromaps.datasets import fetch_annotation
from neuromaps import transforms
import nibabel as nib

img = nib.load('/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/sub-MWMH212/ses-2/func/')
fslr = transforms.mni152_to_fslr(neurosynth, '32k')
