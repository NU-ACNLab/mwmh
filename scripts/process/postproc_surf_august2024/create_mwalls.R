### Create the mwalls to use across subjects and templates
###
### Ellyn Butler
### June 25, 2024

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

hcp_dir <- '/projects/b1108/templates/HCP_S1200_GroupAvg_v1/'
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
saveRDS(GPARC, '/projects/b1108/studies/mwmh/data/processed/neuroimaging/template/GPARC.rds')
