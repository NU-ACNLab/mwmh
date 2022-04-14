### This script evaluates the meaning of various columns in the E-Prime output
###
### Ellyn Butler
### April 14, 2022

library('stringr')
library('ggplot2')

sub = 379
ses = 1

base_path <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/behavioral/'


#################################### Avoid ####################################

avoid_df <- read.csv(paste0(base_path, 'combined/task-avoid.csv'))
avoid_df <- avoid_df[avoid_df$Subject %in% sub & avoid_df$Session %in% ses, ]
row.names(avoid_df) <- 1:nrow(avoid_df)

########## Times
head(avoid_df[, c('Stm.OnsetTime', 'Fixation.OnsetTime',
            'Fixation.OnsetToOnsetTime', 'Stm.OnsetToOnsetTime',
            'Stm.RT')])

### Length of Cue Phase (Should be: 1500, Found: ~ 1485)
# Onset of Cue Phase: 'Stm.OnsetTime'?
avoid_df$Fixation.OnsetTime - avoid_df$Stm.OnsetTime

### Length of First Fixation (Should be: 500-2500, Found: 501-2519)
# Onset of First Fixation: 'Fixation.OnsetTime'?
avoid_df$Fixation.OnsetToOnsetTime #What actually happened?
# OR (not equal!!! but very close)
avoid_df$Jit1 #What was supposed to happen?

### Length of Feedback Phase (Should be: 1500, Found: ~ 1485)
# Onset of Feedback Phase: 'Fixation.OnsetTime' + 'Fixation.OnsetToOnsetTime'?
avoid_df$Stm.OnsetToOnsetTime

### Length of Second Fixation (Should be: 0-4000, Found: )
# Onset of Second Fixation: 'Stm.OnsetToOnsetTime' + 'Fixation.OnsetTime' + 'Fixation.OnsetToOnsetTime'
avoid_df$Jit2 #? There should be a less perfect version of this, and odd increasing
# Alternatively, use the different of the onset for the second fixation and the
# onset of the subsequent cue... but don't know length of very last fix2 that way
# (just put in value for Jit2 - but Jit2's don't line up well...)
fix2_dur <- c(avoid_df[2:nrow(avoid_df), 'Stm.OnsetTime'] - (avoid_df[1:(nrow(avoid_df) - 1),
  'Stm.OnsetToOnsetTime'] + avoid_df[1:(nrow(avoid_df) - 1), 'Fixation.OnsetTime'] +
  avoid_df[1:(nrow(avoid_df) - 1), 'Fixation.OnsetToOnsetTime']),
  avoid_df[nrow(avoid_df), 'Jit2'])

#### Notes
# 1. avoid_df$Stm.DurationError = - avoid_df$Stm.OnsetDelay
# 2. avoid_df$Stm.OnsetToOnsetTime == avoid_df$Fixation.OnsetToOnsetTime (FALSE)
# 3. avoid_df$Stm.OnsetTime < avoid_df$Fixation.OnsetTime + avoid_df$Fixation.OnsetToOnsetTime
#    (TRUE) ==> The latter is the onset time of the Feedback Phase
# 4. Jit1 and Jit2 are different
# 5. Jit2 is monotonically non-decreasing
# 6. Stm.RTTime (time that they reacted) and Stm.RT (how long it took them to
#    react to the stimulus)

#################################### Faces ####################################

faces_df <- read.csv(paste0(base_path, 'combined/task-faces.csv'))

# ImageDisplay2.RESP is wonky. It should just be 1's (response is female) and
# 2's (response is male), but it also has 3's and 4's, almost in equal measure.
# The question is, what gender response do the 1's, 2's, 3's and 4's correspond to?
# And is it the same across every subject?

onetwo_df <- faces_df[faces_df$ImageDisplay2.RESP %in% c(1, 2), c('gender', 'ImageDisplay2.RESP')]
cor(onetwo_df$ImageDisplay2.RESP, onetwo_df$gender) #.80
# ^ Indicates that 1's mean female response in 'ImageDisplay2.RESP', but corr is
# suspiciously low, considering this should be a very easy question to get right

threefour_df <- faces_df[faces_df$ImageDisplay2.RESP %in% c(3, 4), c('gender', 'ImageDisplay2.RESP')]
cor(threefour_df$ImageDisplay2.RESP, threefour_df$gender) # -.82
# ^ Indicates that 4's mean female response in 'ImageDisplay2.RESP', but corr is
# suspiciously low, considering this should be a very easy question to get right

# So what are the correlations within subjects?
within_df <- data.frame(sub_ses=unique(paste0(faces_df$Subject, '_', faces_df$Session)),
                      onestwos=NA,
                      corr=NA,
                      num_NA=NA
                    )

for (i in 1:nrow(within_df)) {
  sub <- as.numeric(strsplit(within_df[i, 'sub_ses'], '_')[[1]][1])
  ses <- as.numeric(strsplit(within_df[i, 'sub_ses'], '_')[[1]][2])
  ss_df <- faces_df[faces_df$Subject == sub & faces_df$Session == ses , c('gender', 'ImageDisplay2.RESP')]
  ss_df <- ss_df[2:(nrow(ss_df)-1), ]
  if (1 %in% ss_df$ImageDisplay2.RESP & !(4 %in% ss_df$ImageDisplay2.RESP)) {
    within_df[i, 'onestwos'] <- TRUE
    within_df[i, 'corr'] <- cor(ss_df$ImageDisplay2.RESP, ss_df$gender, use='complete.obs')
  }
  if (4 %in% ss_df$ImageDisplay2.RESP & !(1 %in% ss_df$ImageDisplay2.RESP)) {
    within_df[i, 'onestwos'] <- FALSE
    within_df[i, 'corr'] <- cor(ss_df$ImageDisplay2.RESP, ss_df$gender, use='complete.obs')
  }
  if (1 %in% ss_df$ImageDisplay2.RESP & 4 %in% ss_df$ImageDisplay2.RESP) {
      print(paste0('sub ', sub, 'ses ', ses, ' OH SHIT. Both 1s and 2s are in the RESP column.'))
  }
  within_df[i, 'num_NA'] <- sum(is.na(ss_df$ImageDisplay2.RESP))
}

# One person who didn't respond at all, filter out
within_df <- within_df[!is.na(within_df$corr), ]
within_df$onestwos <- factor(within_df$onestwos, levels = c(TRUE, FALSE),
                  labels = c('Responses 1s and 2s', 'Responses 3s and 4s')
                  )
genderresp_plot <- ggplot(within_df, aes(x=corr)) + theme_linedraw() +
  geom_histogram() + facet_grid(~ onestwos) + xlab('Correlation between gender and response within subject') +
  ggtitle('Correlation between gender (1 - female, 2 - male) and identification of gender (1, 2, 3, 4)')


pdf('/Users/flutist4129/Documents/Northwestern/studies/mwmh/plots/genderresps.pdf', width=8, height=6)
genderresp_plot
dev.off()
