### This script returns dscalars that indicate
### which vertices are "bad" - i.e., have low
### mean, low variance, or low SNR
###
### Ellyn Butler
### August 20, 2024


##### Load packages
library(argparse)
library(stats)
library(fMRIscrub)
library(fMRItools)
library(ciftiTools)
ciftiTools.setOption('wb_path', '/projects/b1108/software/workbench')

##### Set directories
indir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/'
#indir <- '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/'

##### Parse command line options
parser <- ArgumentParser()
parser$add_argument('-s', '--subid', type='character', help='Subject Identifier')
parser$add_argument('-e', '--sesid', type='character', help='Session Identifier')

args <- parser$parse_args()

subid = args$subid #'MWMH142'
sesid = args$sesid #1

##### Identify bad voxels
cii <- read_cifti(paste0(indir, 'surf/sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
                '_ses-', sesid, '_task-rest_space-fsLR_desc-medpostproc_bold.dscalar.nii'))

cii_mean <- apply_xifti(cii, margin = 1, mean)
cii_sd <- apply_xifti(cii, margin = 1, sd) #mean and sd maps look identical, just on different scales
cii_snr <- cii_mean/cii_sd #transform_xifti

##### Write out
write_cifti(cii_mean, paste0(indir, 'surf/sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
                '_ses-', sesid, '_task-rest_space-fsLR_desc-medpostproc_mean.dscalar.nii'))
write_cifti(cii_sd, paste0(indir, 'surf/sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
                '_ses-', sesid, '_task-rest_space-fsLR_desc-medpostproc_sd.dscalar.nii'))
write_cifti(cii_snr, paste0(indir, 'surf/sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
                '_ses-', sesid, '_task-rest_space-fsLR_desc-medpostproc_snr.dscalar.nii'))