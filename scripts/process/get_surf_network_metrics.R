### This script is a first stab at creating a single subject template using
### templateICAr
### https://github.com/mandymejia/templateICAr
### Yeo networks: https://www.researchgate.net/figure/Network-parcellation-of-Yeos-17-networks-The-17-networks-include-the-following-regions_fig1_352966687#:~:text=The%2017%2Dnetworks%20include%20the%20following%20regions%3A%20N1%3A%20VisCent,N7%3A%20SalVentAttnA%20%2DSalience%2FVentral
###
### Ellyn Butler
### April 1, 2024

library(templateICAr)
library(ciftiTools)
library(dplyr)
ciftiTools.setOption('wb_path', '/Applications/workbench')

surf_dir <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/surf/'
rest_path <- paste0(surf_dir, 'sub-MWMH317/ses-1/func/sub-MWMH317_ses-1_task-rest_space-fsLR_desc-postproc_bold.dscalar.nii')
rest_cifti <- read_cifti(rest_path)

bold_scans <- # vector of paths to all of the bold scans, just practicing with rest now

###### Mask out the medial wall
# load the medial wall image
hcp_dir <- '~/Documents/Northwestern/templates/HCP_S1200_GroupAvg_v1/'
mwall_path <- paste0(hcp_dir, 'Human.MedialWall_Conte69.32k_fs_LR.dlabel.nii')
mwall_cifti <- read_cifti(mwall_path)

# declare logical vectors for whether or not a given vertex is part of the medial wall
mwall_L <- c(mwall_cifti$data$cortex_left)
mwall_L <- recode(mwall_L, `0`=TRUE, `1`=FALSE)
mwall_R <- c(mwall_cifti$data$cortex_right)
mwall_R <- recode(mwall_R, `0`=TRUE, `1`=FALSE)

rest_cifti$meta$cortex$medial_wall_mask$left <- mwall_L
rest_cifti$meta$cortex$medial_wall_mask$right <- mwall_R

# set these vertices to NA... not working
rest_cifti <- move_to_mwall(rest_cifti, values = NA)

###### Downsample surfaces (if necessary)
resample_cifti()

###### Add in subcortical data
# Load postproc image in MNI space
rest_mni <- read_xifti()

# 
parc_add_subcortex()

# Write out resulting image

###### Load the template to serve as a prior
template <- read_cifti()

###### Single subject template estimation
networks_img <- templateICA(rest_cifti, template, tvar_method = 'unbiased', 
            scale = 'global', spatial_model = FALSE)

###### Identify areas of engagement and deviation
activations()

###### Get the area that each network takes up (expansiveness)
surf_area()

###### Estimate within network connectivity

###### Estimate amygdala betweenness centrality
