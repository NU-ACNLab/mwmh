### This script cleans all of the immune related variables and outputs them in
### one csv.
###
### Ellyn Butler
### October 3, 2022

library('dplyr')
library('naniar')


################################### Cytokines ##################################

cyto_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/immune/MWMH_Biomarkers_Depression_Raw_Dec1_2021.csv')

# Filter dataframe for cleaned variables
cyto_df2 <- cyto_df[, c('ID', grep('IL', names(cyto_df), value=TRUE),
  grep('TNF', names(cyto_df), value=TRUE), grep('CRP', names(cyto_df), value=TRUE),
  grep('uPAR', names(cyto_df), value=TRUE))]
names(cyto_df2)[names(cyto_df2) == 'ID'] <- 'subid'

first_df <- cyto_df2[, c('subid', grep('v1', names(cyto_df2), value=TRUE))]
first_df$sesid <- 1
first_df <- rename(first_df, IL10=IL10v1E, IL6=IL6v1E, IL8=IL8v1E, TNFa=TNFav1E,
  CRP=CRPv1, uPAR=uPARv1)

second_df <- cyto_df2[, c('subid', grep('v2', names(cyto_df2), value=TRUE))]
second_df$sesid <- 2
second_df <- rename(second_df, IL10=IL10v2E, IL6=IL6v2E, IL8=IL8v2E, TNFa=TNFav2E,
  CRP=CRPv2, uPAR=uPARv2)

cyto_df3 <- rbind(first_df, second_df)
cyto_df3 <- cyto_df3[, c('subid', 'sesid', 'IL10', 'IL6', 'IL8', 'TNFa', 'CRP', 'uPAR')]
cyto_df3$subid <- paste0('MWMH', cyto_df3$subid)


################################### Monocytes ##################################

mono_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/immune/MWMH_Classical_Monocytes.csv')

mono_df <- mono_df[mono_df$ID != '#NULL!',]

mono_df <- mono_df %>% replace_with_na(replace = list(Classical.Monos.V1 = '#NULL!',
                                                    Non.classical.Monos.V1 = '#NULL!',
                                                    Classical.Monos.V2 = '#NULL!',
                                                    Non.classical.Monos.V2 = '#NULL!'))

names(mono_df)[names(mono_df) == 'ID'] <- 'subid'

first_df <- mono_df[, c('subid', grep('V1', names(mono_df), value=TRUE))]
first_df$sesid <- 1
first_df <- rename(first_df, ClassicalMono=Classical.Monos.V1, NonClassicalMono=Non.classical.Monos.V1)

second_df <- mono_df[, c('subid', grep('V2', names(mono_df), value=TRUE))]
second_df$sesid <- 2
second_df <- rename(second_df, ClassicalMono=Classical.Monos.V2, NonClassicalMono=Non.classical.Monos.V2)

mono_df2 <- rbind(first_df, second_df)
mono_df2 <- mono_df2[, c('subid', 'sesid', 'ClassicalMono', 'NonClassicalMono')]
mono_df2$subid <- paste0('MWMH', mono_df2$subid)


################################# Granulocytes #################################

gran_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/immune/cell_counts_sex_mwmh_sept27_2022.csv')


names(gran_df)[names(gran_df) == 'ID'] <- 'subid'
gran_df$subid <- paste0('MWMH', gran_df$subid)
gran_df$sesid <- 1







############################## Merge and write out #############################

final_df <- merge(cyto_df3, mono_df2, all.x=TRUE)
final_df <- merge(final_df, gran_df2, all.x=TRUE)

write.csv(paste0('/projects/b1108/studies/mwmh/data/processed/immune/immune_', Sys.Date(), '.csv'), row.names=FALSE)













#
