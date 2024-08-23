### This script identifies vertices that are "bad" according
### to the median of the mean of the time series for a given
### vertex.
###
### Ellyn Butler
### August 21, 2024

##### Load packages
library(stats)
library(fMRIscrub)
library(fMRItools)
library(ciftiTools)
ciftiTools.setOption('wb_path', '/projects/b1108/software/workbench')

##### Set directories
indir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/'
#indir <- '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/'

outdir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/template/'
#outdir <- '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/template/'

##### Load template subjects
temp_subjs <- read.csv(paste0(indir, 'tabulated/temp_subjs_sub-all_ses-2_task-rest_desc-medpostproc.csv'))
for (j in 1:nrow(temp_subjs)) { 
    subid <- temp_subjs[j, 'subid']
    sesid <- temp_subjs[j, 'sesid']
    path <- c(system(paste0('find ', indir, 'surf/sub-', subid, '/ses-', 
            sesid, '/func/ ', '-name "*_space-fsLR_desc-medpostproc_meanmed.dscalar.nii"'), intern=TRUE))
    cii <- read_xifti(path)
    assign(paste0('cii', j), cii)
}

xiftis_list <- lapply(1:nrow(temp_subjs), function(i) get(paste0("cii", i)))
meanmeds <- do.call(merge_xifti, xiftis_list)
ciis_mean <- apply_xifti(meanmeds, margin = 1, mean)
ciis_med <- apply_xifti(meanmeds, margin = 1, median)
ciis_mask <- ciis_mean > 0.65

##### Write out
write_cifti(ciis_mean, paste0(outdir, 
    'sub-all_ses-2_task-rest_space-fsLR_desc-medpostproc_mean_meanmeds.dscalar.nii'))
write_cifti(ciis_med, paste0(outdir, 
    'sub-all_ses-2_task-rest_space-fsLR_desc-medpostproc_median_meanmeds.dscalar.nii'))
write_cifti(ciis_mask, paste0(outdir, 
    'sub-all_ses-2_task-rest_space-fsLR_desc-medpostproc_mask_meanmeds.dscalar.nii'))