### This script creates a template to serve as a prior for the 
### individualized network metrics generated by templateICA
###
### Ellyn Butler & Damon Pham
### July 23, 2024

library(dplyr)

# Input directory
indir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/'
#indir <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/'

# Output directory
outdir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/template/'
#outdir <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/template/'

# HCP directory
hcp_dir <- '/projects/b1108/templates/HCP_S1200_GroupAvg_v1/'
#hcp_dir <- '~/Documents/Northwestern/templates/HCP_S1200_GroupAvg_v1/'

# Packages
#devtools::install_github('mandymejia/fMRItools', '0.4') # Need dev version, not CRAN
library(fMRItools)
stopifnot(utils::packageVersion('fMRItools') >= '0.4.4')
#install.packages('ciftiTools')
library(ciftiTools)
ciftiTools.setOption('wb_path', '/projects/b1108/software/workbench')
#devtools::install_github('mandymejia/templateICAr', '8.0') # Need dev version, not CRAN
#^ try again
library(templateICAr)
stopifnot(utils::packageVersion('templateICAr') >= '0.8.5')


## -----------------------------------------------------------------------------


save(list=ls(), file=paste0(outdir, 'template_Yeo17_MWMH_sub-all_ses-2_task-rest_desc-minpostproc_args.rda'))

temp_subjs <- read.csv(paste0(indir, 'tabulated/temp_subjs_sub-all_ses-2_task-rest_desc-minpostproc.csv'))

GPARC <- readRDS('/projects/b1108/studies/mwmh/data/processed/neuroimaging/template/GPARC.rds')

print('Resample GPARC')

GPARC <- resample_cifti(GPARC, resamp_res = 10000)

print('Get the paths to the minimally postprocessed resting state data.')
Sys.setenv('R_MAX_VSIZE'=32000000000)
paths <- c()
for (j in 1:nrow(temp_subjs)) { 
  subid <- temp_subjs[j, 'subid']
  sesid <- temp_subjs[j, 'sesid']
  path <- c(system(paste0('find ', indir, 'surf/sub-', subid, '/ses-', 
            sesid, '/func/ ', '-name "*_space-fsLR_desc-minpostproc_bold.dscalar.nii"'), intern=TRUE))
  paths <- c(paths, path)
}

mask <- read_xifti(paste0(outdir, 'sub-all_ses-2_task-rest_space-fsLR_desc-medpostproc_mask_meanmeds.dscalar.nii'))
mask <- as.logical(c(as.matrix(mask)))

print('Estimate template.') 
temp <- estimate_template(
  paths,
  GICA = GPARC,
  mask = mask,
  hpf = 0, 
  scale = 'local',
  brainstructures = c('left', 'right'),
  GSR = FALSE,
  FC = FALSE,
  scale_sm_surfL = load_surf('left'),
  scale_sm_surfR = load_surf('right'), 
  verbose = TRUE#, usePar=4, wb_path=wb_path
) 

saveRDS(temp, paste0(outdir, 'temp_sub-all_ses-2_task-rest_desc-minpostproc_masked.rds'))


#plot(temp, idx=1:17, fname=paste0('/Users/flutist4129/Documents/Northwestern/studies/mwmh/plots/temp_minpostproc_', 1:17))