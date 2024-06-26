### This script creates a template to serve as a prior for the 
### individualized network metrics generated by templateICA
###
### Ellyn Butler & Damon Pham
### April 17, 2024 - May 25, 2024

library(dplyr)

# Input directory
indir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/'
#indir <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/'

# Output directory
outdir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/template_Yeo17/'
#outdir <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/template_Yeo17/'

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

###### Load and modify the Yeo 17 parcellation
GPARC <- ciftiTools::load_parc('Yeo_17')
### Get new labels by removing the subnetwork and LH/RH parts of the label.
y <- rownames(GPARC$meta$cifti$labels[[1]])
z <- gsub('17Networks_LH_|17Networks_RH_', '', y)
z <- gsub('_.*', '', z)
# ### Uncomment the below two lines if you want to keep left and right separate.
# y <- gsub('17Networks_', '', gsub('H_.*', 'H_', gsub('???', '', y)))
# z <- paste0(y, z)
### Apply new labels.
z <- factor(z, levels=z[!duplicated(z)])
GPARC <- convert_to_dlabel(
  newdata_xifti(GPARC, as.numeric(z)[c(as.matrix(GPARC))+1]),
  levels_old=as.numeric(z)[!duplicated(z)],
  levels=as.numeric(z)[!duplicated(z)] - 1,
  labels=levels(z),
  colors=rgb(
    GPARC$meta$cifti$labels[[1]]$Red,
    GPARC$meta$cifti$labels[[1]]$Green,
    GPARC$meta$cifti$labels[[1]]$Blue,
    GPARC$meta$cifti$labels[[1]]$Alpha
  )[!duplicated(z)],
  add_white=FALSE
)
GPARC$meta$cifti$labels[[1]] <- GPARC$meta$cifti$labels[[1]]
### Handle medial wall
GPARC$meta$cifti$labels[[1]] <- rbind(
  data.frame(Key=-1, Red=1, Green=1, Blue=1, Alpha=0, row.names='BOLD_mwall'),
  GPARC$meta$cifti$labels[[1]]
)

mwall_path <- paste0(hcp_dir, 'Human.MedialWall_Conte69.32k_fs_LR.dlabel.nii')
mwall_cifti <- read_cifti(mwall_path)

mwall_L <- c(mwall_cifti$data$cortex_left)
mwall_L <- recode(mwall_L, `0`=TRUE, `1`=FALSE)
mwall_R <- c(mwall_cifti$data$cortex_right)
mwall_R <- recode(mwall_R, `0`=TRUE, `1`=FALSE)

GPARC$data$cortex_left[!mwall_L,] <- NA
GPARC$data$cortex_right[!mwall_R,] <- NA

GPARC <- move_to_mwall(GPARC, values = c(NA, 0)) #why not NA?

mwall_L <- GPARC$meta$cortex$medial_wall$left
mwall_R <- GPARC$meta$cortex$medial_wall$right

save(list=ls(), file=paste0(outdir, 'template_Yeo17_MWMH_task-all_args.rda'))

temp_subjs <- read.csv(paste0(indir, 'tabulated/temp_subjs_task-all.csv'))

Sys.setenv('R_MAX_VSIZE'=32000000000)
for (j in 1:nrow(temp_subjs)) { 
  subid <- temp_subjs[j, 'subid']
  sesid <- temp_subjs[j, 'sesid']
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

  # Mask out medial walls
  cii$data$cortex_left[!mwall_L,] <- NA
  cii$data$cortex_right[!mwall_R,] <- NA
  cii <- move_to_mwall(cii, values = NA)
  cii <- smooth_cifti(cii, surf_FWHM = 5)
  assign(paste0('cii', j), cii)
}



temp <- estimate_template(
  mget(paste0('cii', 1:nrow(temp_subjs))),
  GICA = GPARC,
  hpf = 0, 
  brainstructures = c('left', 'right'),
  FC = FALSE,
  scale_sm_surfL = load_surf('left'),
  scale_sm_surfR = load_surf('right')#, usePar=4, wb_path=wb_path
) 

saveRDS(temp, paste0(outdir, 'temp_task-all.rds'))
