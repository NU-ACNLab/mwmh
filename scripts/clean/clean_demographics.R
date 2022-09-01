### This script cleans the demographics file that Greg sent Ellyn in July 2022
###
### Ellyn Butler
### August 22, 2022

library('dplyr')

#df <- read.csv('/projects/b1108/studies/mwmh/data/raw/demographic/MWMH_EB_July2022.csv')
df <- read.csv('/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/demographic/MWMH_EB_July2022.csv')

df$subid <- paste0('MWMH', df$ID)

first_df <- df[, c('subid', grep('v1', names(df), value=TRUE))]
first_df$sesid <- 1
first_df <- rename(first_df, black=v1.c.black, white=v1.c.white,
                  otherrace=v1.c.otherrace, BMIperc=BMI.perc.v1, PubCat=PubCatv1)
first_df <- first_df[, c('subid', 'sesid', 'black', 'white', 'otherrace', 'BMIperc', 'PubCat')]

second_df <- df[, c('subid', grep('v2', names(df), value=TRUE))]
second_df$sesid <- 2
second_df <- rename(second_df, BMIperc=BMI.perc.v2, PubCat=PubCat.v2)
second_df <- merge(first_df[, c('subid', 'black', 'white', 'otherrace')], second_df, all=TRUE)
second_df <- second_df[, c('subid', 'sesid', 'black', 'white', 'otherrace', 'BMIperc', 'PubCat')]


df2 <- rbind(first_df, second_df)
df2 <- df2[, c('subid', 'sesid', 'black', 'white', 'otherrace', 'BMIperc', 'PubCat')]

#write.csv(df2, paste0('/projects/b1108/studies/mwmh/data/processed/demographic/demographics_', Sys.Date(), '.csv'), row.names=FALSE)
write.csv(df2, paste0('/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/demographic/demographics_', Sys.Date(), '.csv'), row.names=FALSE)
