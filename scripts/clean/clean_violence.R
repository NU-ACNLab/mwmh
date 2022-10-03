### This script creates some basic summary statistics and plots of the violence
### data
###
### Ellyn Butler
### December 9, 2021

library('ggplot2')
library('dplyr')
library('ggcorrplot')

viol_df <- read.csv('~/Documents/Northwestern/studies/mwmh/data/violence/violence_11-22-2021.csv')

viol_df$v2.etv1 <- recode(viol_df$ETVv2_1, `1`=1, `2`=0)
viol_df$v2.etv2 <- recode(viol_df$ETVv2_2, `1`=1, `2`=0)
viol_df$v2.etv3 <- recode(viol_df$ETVv2_3, `1`=1, `2`=0)
viol_df$v2.etv4 <- recode(viol_df$ETVv2_4, `1`=1, `2`=0)
viol_df$v2.etv5 <- recode(viol_df$ETVv2_5, `1`=1, `2`=0)
viol_df$v2.etv6 <- recode(viol_df$ETVv2_6, `1`=1, `2`=0)
viol_df$v2.etv7 <- recode(viol_df$ETVv2_7, `1`=0, `2`=1)


# To Do: Clean past year data


# Filter dataframe for cleaned variables
viol_df2 <- viol_df[, c('ID', 'ci.murder.v1', 'ci.murder.v2',
  paste0('v1.etv', 1:7), paste0('v2.etv', 1:7))]
names(viol_df2)[names(viol_df2) == 'ID'] <- 'subid'

first_df <- viol_df2[, c('subid', 'ci.murder.v1', paste0('v1.etv', 1:7))]
first_df$sesid <- 1
first_df <- rename(first_df, etv1_ever=v1.etv1, etv2_ever=v1.etv2,
  etv3_ever=v1.etv3, etv4_ever=v1.etv4, etv5_ever=v1.etv5, etv6_ever=v1.etv6,
  etv7_ever=v1.etv7, murder=ci.murder.v1)

second_df <- viol_df2[, c('subid', 'ci.murder.v2', paste0('v2.etv', 1:7))]
second_df$sesid <- 2
second_df <- rename(second_df, etv1_ever=v2.etv1, etv2_ever=v2.etv2,
  etv3_ever=v2.etv3, etv4_ever=v2.etv4, etv5_ever=v2.etv5, etv6_ever=v2.etv6,
  etv7_ever=v2.etv7, murder=ci.murder.v2)

viol_df3 <- rbind(first_df, second_df)
viol_df3 <- viol_df3[, c('subid', 'sesid', 'murder', paste0('etv', 1:7, '_ever'))]
viol_df3$subid <- paste0('MWMH', viol_df3$subid)

viol_df3$ever <- pmax(viol_df3$etv1_ever, viol_df3$etv2_ever, viol_df3$etv3_ever,
  viol_df3$etv4_ever, viol_df3$etv5_ever, viol_df3$etv6_ever, viol_df3$etv7_ever,
  na.rm=TRUE)

viol_df3$ever_wo5 <- pmax(viol_df3$etv1_ever, viol_df3$etv2_ever, viol_df3$etv3_ever,
  viol_df3$etv4_ever, viol_df3$etv6_ever, viol_df3$etv7_ever, na.rm=TRUE)

write.csv(viol_df3, '~/Documents/Northwestern/projects/violence_mediation/data/violence.csv', row.names=FALSE)
