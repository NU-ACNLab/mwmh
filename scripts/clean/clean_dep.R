### This script plots the depression data from both visits
###
### Ellyn Butler
### December 9, 2021 - December 12, 2021

library('dplyr')

dep_df <- read.csv('~/Documents/Northwestern/studies/mwmh/data/clinical/depressionimmune_12-09-2021.csv')

dep_df$RCADSv1_sum <- rowSums(dep_df[, grep('RCADSv1', names(dep_df), value=TRUE)])
dep_df$RCADSv2_sum <- rowSums(dep_df[, grep('RCADSv2', names(dep_df), value=TRUE)])


# Filter dataframe for cleaned variables
dep_df2 <- dep_df[, c('ID', 'RCADSv1_sum', 'RCADSv2_sum', grep('IL', names(dep_df), value=TRUE),
  grep('TNF', names(dep_df), value=TRUE), grep('CRP', names(dep_df), value=TRUE),
  grep('uPAR', names(dep_df), value=TRUE))]
names(dep_df2)[names(dep_df2) == 'ID'] <- 'subid'

first_df <- dep_df2[, c('subid', grep('v1', names(dep_df2), value=TRUE))]
first_df$sesid <- 1
first_df <- rename(first_df, IL10=IL10v1E, IL6=IL6v1E, IL8=IL8v1E, TNFa=TNFav1E,
  CRP=CRPv1, uPAR=uPARv1, RCADS_sum=RCADSv1_sum)

second_df <- dep_df2[, c('subid', grep('v2', names(dep_df2), value=TRUE))]
second_df$sesid <- 2
second_df <- rename(second_df, IL10=IL10v2E, IL6=IL6v2E, IL8=IL8v2E, TNFa=TNFav2E,
  CRP=CRPv2, uPAR=uPARv2, RCADS_sum=RCADSv2_sum)

dep_df3 <- rbind(first_df, second_df)
dep_df3 <- dep_df3[, c('subid', 'sesid', 'RCADS_sum', 'IL10', 'IL6', 'IL8',
  'TNFa', 'CRP', 'uPAR')]
dep_df3$subid <- paste0('MWMH', dep_df3$subid)

write.csv(dep_df3, '~/Documents/Northwestern/projects/violence_mediation/data/dep_immune.csv', row.names=FALSE)
