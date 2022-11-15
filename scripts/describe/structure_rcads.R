### This script analyses the factor structure of the depression and anxiety items
### from MWMH
###
### Ellyn Butler
### May 31, 2022 - November 10, 2022

library(psych) # November 10, 2022: not playing nicely with Quest
library(ggplot2)
library(ggcorrplot)
library(dplyr)
library(nloptr)
library(nlme)
library(lme4)
library(lavaan)
library(sjPlot)
library(ggpubr)


################################## Clean data ##################################

###### Load the data
full_df <- read.csv('/Users/flutist4129/Documents/Northwestern/projects/violence_mediation/data/combined_data.csv')
dep_df <- read.csv('/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/clinical/depanx_2022-10-04.csv')

###### Clean
# Filter dataframe for cleaned variables
first_df <- dep_df[which(!is.na(dep_df$RCADS_25r) & dep_df$sesid == 1), c('subid', 'sesid', grep('RCADS', names(first_df), value=TRUE))]
first_df <- merge(full_df, dep_df)

#### Depression
first_df <- first_df %>% rename(MDD1 = RCADS_1r, SP1 = RCADS_2r, SAD1 = RCADS_3r,
                              MDD2 = RCADS_4r, GAD1 = RCADS_5r, SAD2 = RCADS_6r,
                              SP2 = RCADS_7r, MDD3 = RCADS_8r, MDD4 = RCADS_9r,
                              MDD5 = RCADS_10r, PDA1 = RCADS_11r, OCD1 = RCADS_12r,
                              MDD6 = RCADS_13r, PDA2 = RCADS_14r, MDD7 = RCADS_15r,
                              MDD8 = RCADS_16r, OCD2 = RCADS_17r, GAD2 = RCADS_18r,
                              MDD9 = RCADS_19r, PDA3 = RCADS_20r, MDD10 = RCADS_21r,
                              SP3 = RCADS_22r, OCD3 = RCADS_23r, MDD11 = RCADS_24r,
                              GAD3 = RCADS_25r)

# full dataframe
first_df$internalizing_sumscore <- scale(rowSums(first_df[, 3:27]))
first_df <- first_df[, c('subid', 'sesid', paste0('MDD', 1:11), paste0('GAD', 1:3),
                       paste0('SP', 1:3), paste0('OCD', 1:3), 'SAD1', 'SAD2',
                       paste0('PDA', 1:3), 'internalizing_sumscore')]

viol_df <- read.csv('/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/violence/violence_2022-10-06.csv')
viol_df <- merge(full_df, viol_df)

############################ Descriptive Statistics ############################

describe(first_df[, 3:27])


##### Violence plot
ever_df <- data.frame(Variable=paste0('ETV', 1:7),
                      Violence=c('Family Hurt or Killed', 'Friends Hurt or Killed',
                        'Saw Attacked Knife', 'Saw Shot', 'Shoved Kicked Punched',
                        'Attacked Knife', 'Shot At'),
                      N=c(nrow(viol_df[!is.na(viol_df$etv1_ever), ]),
                        nrow(viol_df[!is.na(viol_df$etv2_ever), ]),
                        nrow(viol_df[!is.na(viol_df$etv3_ever), ]),
                        nrow(viol_df[!is.na(viol_df$etv4_ever), ]),
                        nrow(viol_df[!is.na(viol_df$etv5_ever), ]),
                        nrow(viol_df[!is.na(viol_df$etv6_ever), ]),
                        nrow(viol_df[!is.na(viol_df$etv7_ever), ])),
                      Proportion=c(sum(viol_df$etv1_ever, na.rm=TRUE)/nrow(viol_df[!is.na(viol_df$etv1_ever), ]),
                        sum(viol_df$etv2_ever, na.rm=TRUE)/nrow(viol_df[!is.na(viol_df$etv2_ever), ]),
                        sum(viol_df$etv3_ever, na.rm=TRUE)/nrow(viol_df[!is.na(viol_df$etv3_ever), ]),
                        sum(viol_df$etv4_ever, na.rm=TRUE)/nrow(viol_df[!is.na(viol_df$etv4_ever), ]),
                        sum(viol_df$etv5_ever, na.rm=TRUE)/nrow(viol_df[!is.na(viol_df$etv5_ever), ]),
                        sum(viol_df$etv6_ever, na.rm=TRUE)/nrow(viol_df[!is.na(viol_df$etv6_ever), ]),
                        sum(viol_df$etv7_ever, na.rm=TRUE)/nrow(viol_df[!is.na(viol_df$etv7_ever), ]))
                      )


ever_df$Violence <- ordered(ever_df$Violence, c('Family Hurt or Killed', 'Friends Hurt or Killed',
  'Saw Attacked Knife', 'Saw Shot',
  'Attacked Knife', 'Shot At', 'Shoved Kicked Punched'))

prop_ever_plot <- ggplot(ever_df, aes(x=Violence, y=Proportion, fill=Violence)) +
  theme_linedraw() + geom_bar(stat='identity', position='dodge') +
  theme(legend.position='none', axis.title.x=element_blank(), axis.title.y=element_text(size=7),
		panel.spacing=unit(.1, 'lines'), axis.text.y=element_text(size=6),
    axis.text.x = element_text(angle=45, hjust=1, size=6)) +
  scale_y_continuous(limits=c(0, .5), breaks=round(seq(0, .5, .1), digits=1)) +
  scale_fill_manual(values=c('deepskyblue3', 'steelblue1', 'springgreen3', 'palegreen1', 'pink1', 'violetred1', 'firebrick2'))

# stats
sum(viol_df$ever)/nrow(viol_df)

# export
jpeg('/Users/flutist4129/Documents/Northwestern/projects/violence_mediation/plots/ever_violence_ses-1.jpg', res=300, units='mm', width=80, height=80)
prop_ever_plot
dev.off()


############################### Factor Structure ###############################


##### Correlation matrices
# T1
first_corr <- round(cor(first_df[, 3:27]), 3)
first_ggcorr <- ggcorrplot(first_corr)

jpeg('/Users/flutist4129/Documents/Northwestern/projects/violence_mediation/plots/corrmats_rcads_ses-1.jpg', res=200, units='mm', width=160, height=160)
first_ggcorr
dev.off()

##### Scree plots
eigenvalues1 <- eigen(first_corr)$values
eigen_df1 <- data.frame(matrix(NA, nrow=length(eigenvalues1), ncol=2))
names(eigen_df1) <- c("compnum", "eigen")
eigen_df1$compnum <- 1:25
eigen_df1$eigen <- eigenvalues1

first_scree <- ggplot(eigen_df1, aes(x=compnum, y=eigen)) +
    geom_line(stat="identity") + geom_point() +  theme_minimal() +
    xlab("Component Number") + ylab("Eigenvalues of Components") +
    scale_y_continuous(limits=c(0, 10)) +
    theme(plot.title = element_text(size=12), axis.title = element_text(size=10),
      axis.text = element_text(size=6))

jpeg('/Users/flutist4129/Documents/Northwestern/projects/violence_mediation/plots/screes_rcads_ses-1.jpg', res=200, units='mm', width=125, height=125)
first_scree
dev.off()

################################## Reliability #################################

##### test-retest
# NOTES: singular matrix...
#retest_rel <- testRetest(first_df, second_df, id='subid', time='sesid')
# alpha: T1 (0.8953563), T2 (0.9070000)
# Correlation of scale scores over time = 0.6255501
# Mean between person, across item reliability =  0.37
# Mean within person, across item reliability =  0.44

##### internal consistency: alpha (same as above)
t1_alpha <- psych::alpha(first_df[, 3:27])

##### internal consistency: omega hierarchical (if more than 1 factor)
t1_omegah <- omegah(first_df[, 3:27]) #.72


################################## Histogram #################################

hist_plot <- ggplot(full_df, aes(RCADS_sum)) + theme_minimal() +
  geom_histogram() + xlab('RCADS Sum Score')

jpeg('/Users/flutist4129/Documents/Northwestern/projects/violence_mediation/plots/histogram_rcads_ses-1.jpg', res=200, units='mm', width=125, height=125)
hist_plot
dev.off()
