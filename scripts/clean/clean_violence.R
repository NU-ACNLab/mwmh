### This script creates some basic summary statistics and plots of the violence
### data
###
### Ellyn Butler
### December 9, 2021 - October 4, 2022

library('dplyr')

viol_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/violence/MWMH_V1V2_Violence_Nov21.csv')


##################################### Ever #####################################

viol_df$v2.etv1 <- recode(viol_df$ETVv2_1, `1`=1, `2`=0)
viol_df$v2.etv2 <- recode(viol_df$ETVv2_2, `1`=1, `2`=0)
viol_df$v2.etv3 <- recode(viol_df$ETVv2_3, `1`=1, `2`=0)
viol_df$v2.etv4 <- recode(viol_df$ETVv2_4, `1`=1, `2`=0)
viol_df$v2.etv5 <- recode(viol_df$ETVv2_5, `1`=1, `2`=0)
viol_df$v2.etv6 <- recode(viol_df$ETVv2_6, `1`=1, `2`=0)
viol_df$v2.etv7 <- recode(viol_df$ETVv2_7, `1`=0, `2`=1)


################################### Past year ##################################

viol_df$v2.etv1a <- viol_df$ETVv2_1a
viol_df$v2.etv2a <- viol_df$ETVv2_2a
viol_df$v2.etv3a <- viol_df$ETVv2_3a
viol_df$v2.etv4a <- viol_df$ETVv2_4a
viol_df$v2.etv5a <- viol_df$ETVv2_5a
viol_df$v2.etv6a <- viol_df$ETVv2_6a
viol_df$v2.etv7a <- viol_df$ETVv2_7a

#################### Filter dataframe for cleaned variables ####################

viol_df2 <- viol_df[, c('ID', 'ci.murder.v1', 'ci.murder.v2',
  paste0('v1.etv', 1:7), paste0('v2.etv', 1:7), paste0('v1.etv', 1:7, 'a'),
  paste0('v2.etv', 1:7, 'a'))]
names(viol_df2)[names(viol_df2) == 'ID'] <- 'subid'

first_df <- viol_df2[, c('subid', 'ci.murder.v1', paste0('v1.etv', 1:7), paste0('v1.etv', 1:7, 'a'))]
first_df$sesid <- 1
first_df <- rename(first_df, etv1_ever=v1.etv1, etv2_ever=v1.etv2,
  etv3_ever=v1.etv3, etv4_ever=v1.etv4, etv5_ever=v1.etv5, etv6_ever=v1.etv6,
  etv7_ever=v1.etv7, etv1_pastyear=v1.etv1a, etv2_pastyear=v1.etv2a,
  etv3_pastyear=v1.etv3a, etv4_pastyear=v1.etv4a, etv5_pastyear=v1.etv5a,
  etv6_pastyear=v1.etv6a, etv7_pastyear=v1.etv7a, murder=ci.murder.v1)

second_df <- viol_df2[, c('subid', 'ci.murder.v2', paste0('v2.etv', 1:7), paste0('v2.etv', 1:7, 'a'))]
second_df$sesid <- 2
second_df <- rename(second_df, etv1_ever=v2.etv1, etv2_ever=v2.etv2,
  etv3_ever=v2.etv3, etv4_ever=v2.etv4, etv5_ever=v2.etv5, etv6_ever=v2.etv6,
  etv7_ever=v2.etv7, etv1_pastyear=v2.etv1a, etv2_pastyear=v2.etv2a,
  etv3_pastyear=v2.etv3a, etv4_pastyear=v2.etv4a, etv5_pastyear=v2.etv5a,
  etv6_pastyear=v2.etv6a, etv7_pastyear=v2.etv7a, murder=ci.murder.v2)

viol_df3 <- rbind(first_df, second_df)
viol_df3 <- viol_df3[, c('subid', 'sesid', 'murder', paste0('etv', 1:7, '_ever'), paste0('etv', 1:7, '_pastyear'))]
viol_df3$subid <- paste0('MWMH', viol_df3$subid)

viol_df3$ever <- pmax(viol_df3$etv1_ever, viol_df3$etv2_ever, viol_df3$etv3_ever,
  viol_df3$etv4_ever, viol_df3$etv5_ever, viol_df3$etv6_ever, viol_df3$etv7_ever,
  na.rm=TRUE)

for (i in 1:nrow(viol_df3)) {
  if (viol_df3[i, 'etv1_ever'] %in% 0) {
    viol_df3[i, 'etv1_pastyear'] <- 0
  }
  if (viol_df3[i, 'etv2_ever'] %in% 0) {
    viol_df3[i, 'etv2_pastyear'] <- 0
  }
  if (viol_df3[i, 'etv3_ever'] %in% 0) {
    viol_df3[i, 'etv3_pastyear'] <- 0
  }
  if (viol_df3[i, 'etv4_ever'] %in% 0) {
    viol_df3[i, 'etv4_pastyear'] <- 0
  }
  if (viol_df3[i, 'etv5_ever'] %in% 0) {
    viol_df3[i, 'etv5_pastyear'] <- 0
  }
  if (viol_df3[i, 'etv6_ever'] %in% 0) {
    viol_df3[i, 'etv6_pastyear'] <- 0
  }
  if (viol_df3[i, 'etv7_ever'] %in% 0) {
    viol_df3[i, 'etv7_pastyear'] <- 0
  }
}

viol_df3$num_pastyear <- rowSums(viol_df3[, grep('pastyear', names(viol_df3), value=TRUE)])


#################################### Export ####################################

write.csv(viol_df3, paste0('/projects/b1108/studies/mwmh/data/processed/violence/violence_', Sys.Date(), '.csv'), row.names=FALSE)
