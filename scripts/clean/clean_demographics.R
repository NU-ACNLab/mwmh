### This script cleans the demographics file that Greg sent Ellyn in July 2022
###
### Ellyn Butler
### August 22, 2022 - October 4, 2022

library('dplyr')

racebmipub_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/demographic/MWMH_EB_July2022.csv')
age_df <- read.csv('/projects/b1108/studies/mwmh/data/processed/demographic/age_visits_2022-07-26.csv')
# ^ Had to calculate the ages locally because we can't store birthdates on Quest
sexipr_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/immune/cell_counts_sex_mwmh_sept27_2022.csv')


############################## Race, BMI, puberty ##############################

racebmipub_df$subid <- paste0('MWMH', df$ID)

first_df <- racebmipub_df[, c('subid', grep('v1', names(racebmipub_df), value=TRUE))]
first_df$sesid <- 1
first_df <- rename(first_df, black=v1.c.black, white=v1.c.white,
                  otherrace=v1.c.otherrace, BMIperc=BMI.perc.v1, PubCat=PubCatv1)
first_df <- first_df[, c('subid', 'sesid', 'black', 'white', 'otherrace', 'BMIperc', 'PubCat')]

second_df <- racebmipub_df[, c('subid', grep('v2', names(racebmipub_df), value=TRUE))]
second_df$sesid <- 2
second_df <- rename(second_df, BMIperc=BMI.perc.v2, PubCat=PubCat.v2)
second_df <- merge(first_df[, c('subid', 'black', 'white', 'otherrace')], second_df, all=TRUE)
second_df <- second_df[, c('subid', 'sesid', 'black', 'white', 'otherrace', 'BMIperc', 'PubCat')]

racebmipub_df <- rbind(first_df, second_df)
racebmipub_df <- racebmipub_df[, c('subid', 'sesid', 'black', 'white', 'otherrace', 'BMIperc', 'PubCat')]


################################### Sex & IPR ##################################




################################ Merge & Export ################################

final_df <- merge(racebmipub_df, age_df, all.x=TRUE)
final_df <- merge(final_df, sexipr_df)

write.csv(final_df, paste0('/projects/b1108/studies/mwmh/data/processed/demographic/demographics_', Sys.Date(), '.csv'), row.names=FALSE)
