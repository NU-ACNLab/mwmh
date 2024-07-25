### This script sets up the csv to for the clean interpersonal loss variable
###
### Ellyn Butler
### November 14, 2022

df <- read.csv('/projects/b1108/studies/mwmh/data/raw/violence/MWMH_V1V2_Violence_Nov21.csv')

df$subid <- paste0('MWMH', df$ID)

desc_df1 <- df[, c('subid', 'v1.LSI.chep1des', 'v1.LSI.chep2des',
                   'v1.LSI.chep3des', 'v1.LSI.chep4des')]
names(desc_df1) <- c('subid', 'chep1', 'chep2', 'chep3', 'chep4')
desc_df1$sesid <- 1

desc_df2 <- df[, c('subid', 'v2.LSI.chep1desc', 'v2.LSI.chep2desc',
                   'v2.LSI.chep3desc', 'v2.LSI.chep4desc')]
names(desc_df2) <- c('subid', 'chep1', 'chep2', 'chep3', 'chep4')
desc_df2$sesid <- 2

desc_df <- rbind(desc_df1, desc_df2)
desc_df <- desc_df[, c('subid', 'sesid', 'chep1', 'chep2', 'chep3', 'chep4')]

write.csv(desc_df, paste0('/projects/b1108/studies/mwmh/data/processed/violence/lsi_descriptions_', Sys.Date(), '.csv'), row.names=FALSE)
