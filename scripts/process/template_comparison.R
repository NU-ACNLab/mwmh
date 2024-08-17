### This script plots the ICs for the 17 networks, 
### with the limits set by the network, not by
### the processing method
###
### Ellyn Butler
### August 15, 2024

# Load libraries
library(templateICAr)
library(ciftiTools)
library(png)
library(grid)
library(gridExtra)
ciftiTools.setOption('wb_path', '/projects/b1108/software/workbench')

# Set paths
#neurodir <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/'
neurodir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/'
#plotdir <- '~/Documents/Northwestern/studies/mwmh/plots/'
plotdir <- '/projects/b1108/studies/mwmh/plots/'

# Load templates
min <- readRDS(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-minpostproc.rds'))
export_template(min, out_fname = paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-minpostproc'))
med <- readRDS(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-medpostproc.rds'))
export_template(med, out_fname = paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-medpostproc'))
sme <- readRDS(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-smepostproc.rds'))
export_template(sme, out_fname = paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-smepostproc'))
max <- readRDS(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-maxpostproc.rds'))
export_template(max, out_fname = paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-maxpostproc'))

min_mean <- read_cifti(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-minpostproc_mean.dscalar.nii'))
min_var <- read_cifti(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-minpostproc_var.dscalar.nii'))
med_mean <- read_cifti(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-medpostproc_mean.dscalar.nii'))
med_var <- read_cifti(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-medpostproc_var.dscalar.nii'))
sme_mean <- read_cifti(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-smepostproc_mean.dscalar.nii'))
sme_var <- read_cifti(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-smepostproc_var.dscalar.nii'))
max_mean <- read_cifti(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-maxpostproc_mean.dscalar.nii'))
max_var <- read_cifti(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-maxpostproc_var.dscalar.nii'))

mean_temp <- merge_xifti(min_mean, med_mean, sme_mean, max_mean)
var_temp <- merge_xifti(min_var, med_var, sme_var, max_var)

# Define ICs
for (i in 1:17) {
    mt <- select_xifti(mean_temp, seq(i, ncol(mean_temp), 17))
    vt <- select_xifti(var_temp, seq(i, ncol(mean_temp), 17))
    mt$meta$cifti$names <- paste0(mt$meta$cifti$names, c('_Fewmotion_NoGSR', 
            '_Manymotion_NoGSR', '_Fewmotion_GSR', '_Manymotion_GSR'))
    vt$meta$cifti$names <- paste0(vt$meta$cifti$names, c('_Fewmotion_NoGSR', 
            '_Manymotion_NoGSR', '_Fewmotion_GSR', '_Manymotion_GSR'))
    assign(paste0('IC', i, '_mean'), mt) 
    assign(paste0('IC', i, '_var'), vt) 
}
 
# Export plots
for (i in 1:17) {
    plot(get(paste0('IC', i, '_var')), fname=paste0(plotdir, 'IC', i, '_var'), idx=1:4)
}

# Load plots
for (i in 1:17) {
    vt <- get(paste0('IC', i, '_var'))
    plot1 <- readPNG(paste0(plotdir, 'IC', i, '_var_', vt$meta$cifti$names[1], '.png'))
    plot2 <- readPNG(paste0(plotdir, 'IC', i, '_var_', vt$meta$cifti$names[2], '.png'))
    plot3 <- readPNG(paste0(plotdir, 'IC', i, '_var_', vt$meta$cifti$names[3], '.png'))
    plot4 <- readPNG(paste0(plotdir, 'IC', i, '_var_', vt$meta$cifti$names[4], '.png'))
    assign(vt$meta$cifti$names[1], plot1)
    assign(vt$meta$cifti$names[2], plot2)
    assign(vt$meta$cifti$names[3], plot3)
    assign(vt$meta$cifti$names[4], plot4)
}

pdf(paste0(plotdir, 'IC_var.pdf'), width = 4.5, height = 4)
for(i in 1:17) {
    vt <- get(paste0('IC', i, '_var'))
    grid.arrange(rasterGrob(get(vt$meta$cifti$names[1])), 
                 rasterGrob(get(vt$meta$cifti$names[2])), 
                 rasterGrob(get(vt$meta$cifti$names[3])), 
                 rasterGrob(get(vt$meta$cifti$names[4])),  
                 ncol = 2, nrow = 2)
}
dev.off()