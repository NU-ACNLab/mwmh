### This script plots the number of TRs left after censoring
### for subjects in the template, and those not in the template,
### by task, and by session (just for those not in the template).
###
### Ellyn Butler
### May 26, 2024

library(ggplot2)
library(gridExtra)

tabdir <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/tabulated/'
plotdir <- '~/Documents/Northwestern/studies/mwmh/plots/'
df <- read.csv(paste0(tabdir, 'quality_2024-05-26.csv'))
df$sesid <- factor(df$sesid)
temp_subjs_df <- read.csv(paste0(tabdir, 'temp_subjs_task-all.csv'))

######################## Template subjects ########################

# Rest
rest_temp_df <- df[df$subid %in% temp_subjs_df$subid & df$task == 'rest', ]
rest_temp_df$min <- (rest_temp_df$num_trs_kept*0.555)/60
n_rest_temp <- nrow(rest_temp_df)
rest_temp_plot <- ggplot(rest_temp_df, aes(x = min)) + theme_linedraw() + geom_histogram() + 
                    xlab(paste0('Minutes (N = ', n_rest_temp, ')')) + 
                    ggtitle('Template Subjects\' Resting State Time After Censoring')

# Faces 
faces_temp_df <- df[df$subid %in% temp_subjs_df$subid & df$task == 'faces', ]
faces_temp_df$min <- (faces_temp_df$num_trs_kept*2)/60
n_faces_temp <- nrow(faces_temp_df)
faces_temp_plot <- ggplot(faces_temp_df, aes(x = min)) + theme_linedraw() + geom_histogram() + 
                    xlab(paste0('Minutes (N = ', n_faces_temp, ')')) +
                    ggtitle('Template Subjects\' Faces Time After Censoring')

# Avoid
avoid_temp_df <- df[df$subid %in% temp_subjs_df$subid & df$task == 'avoid', ]
avoid_temp_df$min <- (avoid_temp_df$num_trs_kept*2)/60
n_avoid_temp <- nrow(avoid_temp_df)
avoid_temp_plot <- ggplot(avoid_temp_df, aes(x = min)) + theme_linedraw() + geom_histogram() + 
                    xlab(paste0('Minutes (N = ', n_avoid_temp, ')')) +
                    ggtitle('Template Subjects\' Avoid Time After Censoring')

# Combined
comb_temp_df <- data.frame(subid = unique(temp_subjs_df$subid), min = NA) 
for (i in 1:nrow(comb_temp_df)) {
    subid <- comb_temp_df[i, 'subid']
    min <- sum(rest_temp_df[rest_temp_df$subid == subid, 'min'],
                faces_temp_df[faces_temp_df$subid == subid, 'min'],
                avoid_temp_df[avoid_temp_df$subid == subid, 'min'])
    comb_temp_df[i, 'min'] <- min
}
n_comb_temp <- nrow(comb_temp_df)
comb_temp_plot <- ggplot(comb_temp_df, aes(x = min)) + theme_linedraw() + geom_histogram() + 
                    xlab(paste0('Minutes (N = ', n_comb_temp, ')')) +
                    ggtitle('Template Subjects\' Combined Time After Censoring')

png(file = paste0(plotdir, 'template_subjs_minutes.png'), width=10, height=10, units = 'in', res=1200)
grid.arrange(rest_temp_plot, faces_temp_plot, avoid_temp_plot, comb_temp_plot, nrow = 2, ncol = 2)
dev.off()

######################## Analysis subjects ########################

# Rest
rest_anal_df <- df[!(df$subid %in% temp_subjs_df$subid) & df$task == 'rest', ]
rest_anal_df$min <- (rest_anal_df$num_trs_kept*0.555)/60
n_rest_anal <- nrow(rest_anal_df)
rest_anal_plot <- ggplot(rest_anal_df, aes(x = min, fill = sesid)) + theme_linedraw() + 
                    geom_histogram(alpha = 0.5, position = 'identity') + 
                    xlab(paste0('Minutes (N = ', n_rest_anal, ')')) +
                    ggtitle('Analysis Subjects\' Resting State Time After Censoring') +
                    labs(fill = 'Session')

# Faces 
faces_anal_df <- df[!(df$subid %in% temp_subjs_df$subid) & df$task == 'faces', ]
faces_anal_df$min <- (faces_anal_df$num_trs_kept*2)/60
n_faces_anal <- nrow(faces_anal_df)
faces_anal_plot <- ggplot(faces_anal_df, aes(x = min, fill = sesid)) + theme_linedraw() + 
                    geom_histogram(alpha = 0.5, position = 'identity') + 
                    xlab(paste0('Minutes (N = ', n_faces_anal, ')')) +
                    ggtitle('Analysis Subjects\' Faces Time After Censoring') +
                    labs(fill = 'Session')

# Avoid
avoid_anal_df <- df[!(df$subid %in% temp_subjs_df$subid) & df$task == 'avoid', ]
avoid_anal_df$min <- (avoid_anal_df$num_trs_kept*2)/60
n_avoid_anal <- nrow(avoid_anal_df)
avoid_anal_plot <- ggplot(avoid_anal_df, aes(x = min, fill = sesid)) + theme_linedraw() + 
                    geom_histogram(alpha = 0.5, position = 'identity') + 
                    xlab(paste0('Minutes (N = ', n_avoid_anal, ')')) +
                    ggtitle('Analysis Subjects\' Avoid Time After Censoring') +
                    labs(fill = 'Session')

# Combined
df$subses <- paste0(df$subid, '_', df$sesid)
temp_subjs_df$subses <- paste0(temp_subjs_df$subid, '_', temp_subjs_df$sesid)
anal_subses <- unique(df$subses[!(df$subses %in% temp_subjs_df$subses)])
comb_anal_df <- data.frame(subid = df[df$subses %in% anal_subses, 'subid'],
                           sesid = df[df$subses %in% anal_subses, 'sesid'],
                           min = NA) 
comb_anal_df <- comb_anal_df[!duplicated(comb_anal_df), ]
for (i in 1:nrow(comb_anal_df)) {
    subid <- comb_anal_df[i, 'subid']
    sesid <- comb_anal_df[i, 'sesid']
    min <- sum(rest_anal_df[rest_anal_df$subid == subid & rest_anal_df$sesid == sesid, 'min'],
                faces_anal_df[faces_anal_df$subid == subid & faces_anal_df$sesid == sesid, 'min'],
                avoid_anal_df[avoid_anal_df$subid == subid & avoid_anal_df$sesid == sesid, 'min'])
    comb_anal_df[i, 'min'] <- min
}
n_comb_anal <- nrow(comb_anal_df)
comb_anal_plot <- ggplot(comb_anal_df, aes(x = min, fill = sesid)) + theme_linedraw() + 
                    geom_histogram(alpha = 0.5, position = 'identity') + 
                    xlab(paste0('Minutes (N = ', n_comb_anal, ')')) +
                    ggtitle('Analysis Subjects\' Combined Time After Censoring') +
                    labs(fill = 'Session')

png(file = paste0(plotdir, 'analysis_subjs_minutes.png'), width=10, height=10, units = 'in', res=1200)
grid.arrange(rest_anal_plot, faces_anal_plot, avoid_anal_plot, comb_anal_plot, nrow = 2, ncol = 2)
dev.off()