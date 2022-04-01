### This script turns eprime task response and task design information into
### a tsv compliant with BIDS
###
### Ellyn Butler
### March 29, 2022

library('reshape2')


base_path <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/'

#faces_df <- read.csv(paste0(base_path, 'behavioral/sub-MWMH166_ses-1_task-faces.csv'))


#################################### Avoid ####################################

avoid_df <- read.csv(paste0(base_path, 'behavioral/sub-MWMH166_ses-1_task-avoid.csv'))

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

time_df <- data.frame(onset_cue=avoid_df$Stm.OnsetTime,
            duration_cue=avoid_df$Fixation.OnsetTime - avoid_df$Stm.OnsetTime,
            onset_firstfix=avoid_df$Fixation.OnsetTime,
            duration_firstfix=avoid_df$Fixation.OnsetToOnsetTime,
            onset_feedback=avoid_df$Fixation.OnsetTime + avoid_df$Fixation.OnsetToOnsetTime,
            duration_feedback=avoid_df$Stm.OnsetToOnsetTime,
            onset_secfix=avoid_df$Stm.OnsetToOnsetTime + avoid_df$Fixation.OnsetTime + avoid_df$Fixation.OnsetToOnsetTime,
            duration_secfix=avoid_df$Jit2)

avoid_df <- cbind(avoid_df, time_df)

final_df <- data.frame(subid=rep('MWMH166', nrow(avoid_df)*4),
                       sesid=rep(1, nrow(avoid_df)*4),
                       onset=NA, duration=NA, trial=NA, cue=NA, fix1=NA,
                       feedback=NA, fix2=NA, approach=NA, avoid=NA,
                       reward=NA, loss=NA, nothing=NA)

########## Stimuli
j=1
k=1
for (i in 1:nrow(final_df)) {
  if (j == 5) {
    j = 1
    k = k+1
  }
  final_df[i, 'onset'] <- avoid_df[k, ]

  j=j+1
}


#onset,duration,trial,cue,fix1,feedback,fix2,approach,avoid,reward,loss,nothing

# final_df should have 96*4 = 384 rows

#### Questions
# 1. Is Stm.OnsetToOnsetTime or Fixation.OnsetToOnsetTime the length of the
#    cue phase? Length of the feedback phase?


#### Notes
# 1. avoid_df$Stm.DurationError = - avoid_df$Stm.OnsetDelay
# 2. avoid_df$Stm.OnsetToOnsetTime == avoid_df$Fixation.OnsetToOnsetTime (FALSE)
# 3. avoid_df$Stm.OnsetTime < avoid_df$Fixation.OnsetTime + avoid_df$Fixation.OnsetToOnsetTime
#    (TRUE) ==> The latter is the onset time of the Feedback Phase
# 4. Jit1 and Jit2 are different
# 5. Jit2 is monotonically non-decreasing
# 6. Difference between Stm.RTTime (time that they reacted) and Stm.RT (how long
#    it took them to react to the stimulus)
