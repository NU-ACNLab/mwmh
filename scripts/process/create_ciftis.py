### This script takes the postprocessed functional niftis and puts them into
### fsLR32k space using neuromaps
###
### Ellyn Butler
### September 26, 2023 - October 30, 2023

#from neuromaps.datasets import fetch_annotation
from neuromaps import transforms
import nibabel as nib

subid = 'MWMH212'
sesid = '2'

surfdir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/surf/'
sssurfdir = surfdir+'sub-'+subid+'/ses-'+sesid+'/'
surf_lh = nib.load(sssurfdir+'sub-'+subid+'_ses-'+sesid+'_task-rest_space-fsaverage_desc-preproc_bold_lh.func.gii')
surf_rh = nib.load(sssurfdir+'sub-'+subid+'_ses-'+sesid+'_task-rest_space-fsaverage_desc-preproc_bold_rh.func.gii')


fslr_lh = transforms.fsaverage_to_fslr(surf_lh, '32k', hemi='L')
fslr_rh = transforms.fsaverage_to_fslr(surf_rh, '32k', hemi='R')


img = nib.load('/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/sub-MWMH212/ses-2/func/')
fslr = transforms.mni152_to_fslr(neurosynth, '32k')
