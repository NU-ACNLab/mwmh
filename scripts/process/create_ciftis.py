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
sub = 'sub-'+subid
ses = 'ses-'+sesid

surfdir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/surf/'
sssurfdir = surfdir+'sub-'+subid+'/ses-'+sesid+'/'
surf_lh = nib.load(sssurfdir+sub+'_'+ses+'_task-rest_space-fsaverage5_desc-preproc_bold_lh.func.gii')
surf_rh = nib.load(sssurfdir+sub+'_'+ses+'_task-rest_space-fsaverage5_desc-preproc_bold_rh.func.gii')

surf_fslr = transforms.fsaverage_to_fslr([surf_lh, surf_rh], '32k')
surf_fslr_lh = surf_fslr[0]
surf_fslr_rh = surf_fslr[1]

surf_fslr_lh.to_filename(sssurfdir+'/'+sub+'_'+ses+'_space-fslr32k_task-rest_lh.func.gii')
surf_fslr_rh.to_filename(sssurfdir+'/'+sub+'_'+ses+'_space-fslr32k_task-rest_rh.func.gii')
