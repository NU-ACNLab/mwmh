### This script plots the depression data from both visits
###
### Ellyn Butler
### December 9, 2021 - October 4, 2022

library('dplyr')

dep_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/immune/MWMH_Biomarkers_Depression_Raw_Dec1_2021.csv')

dep_df$RCADSv1_sum <- rowSums(dep_df[, grep('RCADSv1', names(dep_df), value=TRUE)])
dep_df$RCADSv2_sum <- rowSums(dep_df[, grep('RCADSv2', names(dep_df), value=TRUE)])


# Filter dataframe for cleaned variables
dep_df2 <- dep_df[, c('ID', grep('RCADS', names(dep_df), value=TRUE))]

first_df <- dep_df2[, c('ID', grep('v1', names(dep_df2), value=TRUE))]
first_df$sesid <- 1
names(first_df) <- gsub('v1', '', names(first_df))

second_df <- dep_df2[, c('ID', grep('v2', names(dep_df2), value=TRUE))]
second_df$sesid <- 2
names(second_df) <- gsub('v2', '', names(second_df))

dep_df3 <- rbind(first_df, second_df)
dep_df3$subid <- paste0('MWMH', dep_df3$ID)
dep_df3 <- dep_df3[, c('subid', 'sesid', grep('RCADS', names(dep_df3), value=TRUE))]


write.csv(dep_df3, paste0('/projects/b1108/studies/mwmh/data/processed/clinical/depanx_', Sys.Date(), '.csv'), row.names=FALSE)
