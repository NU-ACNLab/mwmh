### This script cleans the classical/non-classical monocytes data
###
### Ellyn Butler
### May 15, 2022


library('dplyr')
library('naniar')

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

write.csv(mono_df2, '/projects/b1108/studies/mwmh/data/processed/immune/monocytes.csv', row.names=FALSE)
