### This script does the medial wall modification and smoothing
### separately for each subject because I am guessing failing
### to do this is why I was getting a segmentation fault
###
### Ellyn Butler
### June 25, 2024

# Packages
#devtools::install_github('mandymejia/fMRItools', '0.4') # Need dev version, not CRAN
library(argparse)
library(fMRItools)
stopifnot(utils::packageVersion('fMRItools') >= '0.4.4')
#install.packages('ciftiTools')
library(ciftiTools)
ciftiTools.setOption('wb_path', '/projects/b1108/software/workbench')
#devtools::install_github('mandymejia/templateICAr', '8.0') # Need dev version, not CRAN
#^ try again
library(templateICAr)
stopifnot(utils::packageVersion('templateICAr') >= '0.8.5')
library(dplyr)

# Paths
indir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/'

# Parse command line arguments
parser <- ArgumentParser()
parser$add_argument('-s', '--subid', type='character', help='Subject Identifier')
parser$add_argument('-e', '--sesid', type='character', help='Session Identifier')

args <- parser$parse_args()

subid = args$subid #'MWMH317'
sesid = args$sesid #1

print(subid)
print(sesid)

Sys.setenv('R_MAX_VSIZE'=32000000000)


print('Merge across tasks')
paths <- c(system(paste0('find ', indir, 'surf/sub-', subid, '/ses-', 
        sesid, '/func/ ', '-name "*_space-fsLR_desc-postproc_bold.dscalar.nii"'), intern=TRUE))
i = 1
for (path in paths) {
    cifti <- read_cifti(path)
    if (i == 1) {
        cii <- cifti
    } else {
        cii <- merge_xifti(cii, cifti)
    }
    i = i + 1
}

print('Read in the image with the correct medial wall masks')
GPARC <- readRDS('/projects/b1108/studies/mwmh/data/processed/neuroimaging/template/GPARC.rds')
mwall_L <- GPARC$meta$cortex$medial_wall$left
mwall_R <- GPARC$meta$cortex$medial_wall$right

print('Mask out medial walls and smooth the data')
cii$data$cortex_left[!mwall_L,] <- NA
cii$data$cortex_right[!mwall_R,] <- NA
cii <- move_to_mwall(cii, values = NA)
cii <- smooth_cifti(cii, surf_FWHM = 5)
write_cifti(cii, paste0(indir, 'surf/sub-', subid, '/ses-', 
            sesid, '/func/sub-', subid, '_ses-', sesid, 
            '_task-all_space-fsLR_desc-postproc_smoothed.dscalar.nii'))
