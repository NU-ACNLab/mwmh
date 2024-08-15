### This script plots the ICs for the 17 networks, 
### with the limits set by the network, not by
### the processing method
###
### Ellyn Butler
### August 15, 2024

# Load libraries
library(templateICAr)
library(ciftiTools)
library(ggpubr)
ciftiTools.setOption('wb_path', '/projects/b1108/software/workbench')

# Set paths
#neurodir <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/'
neurodir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/'
plotdir <- '/projects/b1108/studies/mwmh/plots/'

# Load templates
min <- readRDS(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-minpostproc.rds'))
med <- readRDS(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-medpostproc.rds'))
sme <- readRDS(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-smepostproc.rds'))
max <- readRDS(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-maxpostproc.rds'))

# Define ICs
base <- min
for (i in 1:17) {
    base$template$mean <- cbind(min$template$mean[,i], med$template$mean[,i], 
                                sme$template$mean[,i], max$template$mean[,i])
    base$template$varNN <- cbind(min$template$varNN[,i], med$template$varNN[,i], 
                                sme$template$varNN[,i], max$template$varNN[,i])
    #base$dat_struct$meta$cifti$names <- c(paste0('Column ', 1:4))
    assign(paste0('IC', i), base) 
}
 
# Export plots
pdf(paste0(plotdir, 'temp_comparison_by_IC.pdf'), width=10, height=34)
par(mfrow=c(17, 4))
for (i in 1:17) {
    plot(get(paste0('IC', i)), idx=1)
    plot(get(paste0('IC', i)), idx=2)
    plot(get(paste0('IC', i)), idx=3)
    plot(get(paste0('IC', i)), idx=4)
}
dev.off()