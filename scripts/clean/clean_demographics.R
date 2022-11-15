### This script cleans the demographics file that Greg sent Ellyn in July 2022
###
### Ellyn Butler
### August 22, 2022 - November 7, 2022

library('dplyr')

racebmipub_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/demographic/MWMH_EB_July2022.csv')
age_df <- read.csv('/projects/b1108/studies/mwmh/data/processed/demographic/age_visits_2022-11-07.csv')
# ^ Had to calculate the ages locally because we can't store birthdates on Quest
sexipr_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/immune/cell_counts_sex_mwmh_sept27_2022.csv')


############################## Race, BMI, puberty ##############################

racebmipub_df$subid <- paste0('MWMH', racebmipub_df$ID)

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

sexipr_df$subid <- paste0('MWMH', sexipr_df$ID)
sexipr_df$sesid <- 1

sexipr_df <- rename(sexipr_df, IPR=IPR.v1)

sexipr_df <- sexipr_df[, c('subid', 'sesid', 'female', 'IPR')]

sexipr_df2 <- sexipr_df
sexipr_df2$sesid <- 2

sexipr_df <- rbind(sexipr_df, sexipr_df2)


###################################### Age #####################################

age_df <- age_df[, c('subid', 'sesid', 'age_lab', 'age_mri', 'days_mri_minus_lab')]


################################ Merge & Export ################################

final_df <- merge(racebmipub_df, age_df, all.x=TRUE)
final_df <- merge(final_df, sexipr_df, all.x=TRUE)

write.csv(final_df, paste0('/projects/b1108/studies/mwmh/data/processed/demographic/demographics_', Sys.Date(), '.csv'), row.names=FALSE)
