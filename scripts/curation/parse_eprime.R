### This script turns eprime task response and task design information into
### a tsv compliant with BIDS
###
### Ellyn Butler
### March 29, 2022

library('reshape2')

# TO DO: Turn these into command line arguments for job submission
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

#eprime_to_pulse <- avoid_df[1, 'Stm.OnsetTime'] - # TO DO: Look at design file for constant
eprime_to_pulse <- 0 #TMP

# NOTE: First onset time seems suspiciously late
time_df <- data.frame(onset_cue=(avoid_df$Stm.OnsetTime - eprime_to_pulse)/1000,
            duration_cue=(avoid_df$Fixation.OnsetTime - avoid_df$Stm.OnsetTime)/1000,
            onset_fix1=(avoid_df$Fixation.OnsetTime - eprime_to_pulse)/1000,
            duration_fix1=(avoid_df$Fixation.OnsetToOnsetTime)/1000,
            onset_feedback=(avoid_df$Fixation.OnsetTime + avoid_df$Fixation.OnsetToOnsetTime - eprime_to_pulse)/1000,
            duration_feedback=(avoid_df$Stm.OnsetToOnsetTime)/1000,
            onset_fix2=(avoid_df$Stm.OnsetToOnsetTime + avoid_df$Fixation.OnsetTime + avoid_df$Fixation.OnsetToOnsetTime - eprime_to_pulse)/1000,
            duration_fix2=fix2_dur/1000)
            # ^ duration_fix2 is correct here

avoid_df <- cbind(avoid_df, time_df)

final_avoid_df <- data.frame(subid=rep('MWMH166', nrow(avoid_df)*4),
                       sesid=rep(1, nrow(avoid_df)*4),
                       onset=NA, duration=NA, trial=NA, cue=NA, fix1=NA,
                       feedback=NA, fix2=NA, approach=NA, avoid=NA,
                       reward=NA, loss=NA, nothing=NA, gain50=NA, gain10=NA,
                       lose10=NA, lose50=NA)

########## Stimuli

#onset,duration,trial,cue,fix1,feedback,fix2,approach,avoid,reward,loss,nothing

j=0
for (i in 1:nrow(avoid_df)) {
  # onset
  final_avoid_df[i+j, 'onset'] <- avoid_df[i, 'onset_cue']
  final_avoid_df[i+j+1, 'onset'] <- avoid_df[i, 'onset_fix1']
  final_avoid_df[i+j+2, 'onset'] <- avoid_df[i, 'onset_feedback']
  final_avoid_df[i+j+3, 'onset'] <- avoid_df[i, 'onset_fix2']
  # duration
  final_avoid_df[i+j, 'duration'] <- avoid_df[i, 'duration_cue']
  final_avoid_df[i+j+1, 'duration'] <- avoid_df[i, 'duration_fix1']
  final_avoid_df[i+j+2, 'duration'] <- avoid_df[i, 'duration_feedback']
  final_avoid_df[i+j+3, 'duration'] <- avoid_df[i, 'duration_fix2']
  # trial
  final_avoid_df[(i+j):(i+j+3), 'trial'] <- avoid_df[i, 'Trial']
  # cue - is a cue event or not
  final_avoid_df[(i+j):(i+j+3), 'cue'] <- c(1, 0, 0, 0)
  # fix1 - is a fix1 event or not
  final_avoid_df[(i+j):(i+j+3), 'fix1'] <- c(0, 1, 0, 0)
  # feedback - is a feedback event or not
  final_avoid_df[(i+j):(i+j+3), 'feedback'] <- c(0, 0, 1, 0)
  # fix2 - is a fix1 event or not
  final_avoid_df[(i+j):(i+j+3), 'fix2'] <- c(0, 0, 0, 1)
  # approach - cue & press
  press <- as.numeric(avoid_df[i, 'Stm.RT'] > 0)
  final_avoid_df[i+j, 'approach'] <- press*final_avoid_df[i+j, 'cue']
  final_avoid_df[i+j+1, 'approach'] <- press*final_avoid_df[i+j+1, 'cue']
  final_avoid_df[i+j+2, 'approach'] <- press*final_avoid_df[i+j+2, 'cue']
  final_avoid_df[i+j+3, 'approach'] <- press*final_avoid_df[i+j+3, 'cue']
  # avoid - cue & no press
  final_avoid_df[i+j, 'avoid'] <- (1-press)*final_avoid_df[i+j, 'cue']
  final_avoid_df[i+j+1, 'avoid'] <- (1-press)*final_avoid_df[i+j+1, 'cue']
  final_avoid_df[i+j+2, 'avoid'] <- (1-press)*final_avoid_df[i+j+2, 'cue']
  final_avoid_df[i+j+3, 'avoid'] <- (1-press)*final_avoid_df[i+j+3, 'cue']
  # reward - feedback & reward ($ > 0)
  final_avoid_df[i+j, 'reward'] <- (avoid_df[i, 'Amount'] > 0)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'reward'] <- (avoid_df[i, 'Amount'] > 0)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'reward'] <- (avoid_df[i, 'Amount'] > 0)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'reward'] <- (avoid_df[i, 'Amount'] > 0)*final_avoid_df[i+j+3, 'feedback']
  # loss - feedback & loss ($ < 0)
  final_avoid_df[i+j, 'loss'] <- (avoid_df[i, 'Amount'] < 0)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'loss'] <- (avoid_df[i, 'Amount'] < 0)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'loss'] <- (avoid_df[i, 'Amount'] < 0)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'loss'] <- (avoid_df[i, 'Amount'] < 0)*final_avoid_df[i+j+3, 'feedback']
  # nothing - feedback & $0
  final_avoid_df[i+j, 'nothing'] <- (avoid_df[i, 'Amount'] == 0)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'nothing'] <- (avoid_df[i, 'Amount'] == 0)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'nothing'] <- (avoid_df[i, 'Amount'] == 0)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'nothing'] <- (avoid_df[i, 'Amount'] == 0)*final_avoid_df[i+j+3, 'feedback']
  # gain 50
  final_avoid_df[i+j, 'gain50'] <- (avoid_df[i, 'Amount'] == 50)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'gain50'] <- (avoid_df[i, 'Amount'] == 50)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'gain50'] <- (avoid_df[i, 'Amount'] == 50)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'gain50'] <- (avoid_df[i, 'Amount'] == 50)*final_avoid_df[i+j+3, 'feedback']
  # gain 10
  final_avoid_df[i+j, 'gain10'] <- (avoid_df[i, 'Amount'] == 10)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'gain10'] <- (avoid_df[i, 'Amount'] == 10)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'gain10'] <- (avoid_df[i, 'Amount'] == 10)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'gain10'] <- (avoid_df[i, 'Amount'] == 10)*final_avoid_df[i+j+3, 'feedback']
  # lose 10
  final_avoid_df[i+j, 'lose10'] <- (avoid_df[i, 'Amount'] == -10)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'lose10'] <- (avoid_df[i, 'Amount'] == -10)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'lose10'] <- (avoid_df[i, 'Amount'] == -10)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'lose10'] <- (avoid_df[i, 'Amount'] == -10)*final_avoid_df[i+j+3, 'feedback']
  # lose 50
  final_avoid_df[i+j, 'lose50'] <- (avoid_df[i, 'Amount'] == -50)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'lose50'] <- (avoid_df[i, 'Amount'] == -50)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'lose50'] <- (avoid_df[i, 'Amount'] == -50)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'lose50'] <- (avoid_df[i, 'Amount'] == -50)*final_avoid_df[i+j+3, 'feedback']
  j=j+3
}

bids_path <- '~/Documents/Northwestern/studies/mwmh/data/raw/neuroimaging/bids/sub-MWMH'

# SANITY CHECK: Does the onset time of the i+1 row equal the onset + duration of i?
sanity <- final_avoid_df[2:nrow(final_avoid_df), 'onset'] - (final_avoid_df[1:(nrow(final_avoid_df) - 1),'onset'] + final_avoid_df[1:(nrow(final_avoid_df) - 1), 'duration']) < .00001

if (FALSE %in% sanity) {
  stop('The onsets and durations are not matching up')
}

# Write out tsv to bids directory
write.table(final_avoid_df, paste0(bids_path, sub, '/ses-', ses, '/func/sub-MWMH',
  sub, '_ses-', ses, '_task-avoid.tsv'), row.names=FALSE, sep='\t')

# final_avoid_df should have 96*4 = 384 rows



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
# 6. Stm.RTTime (time that they reacted) and Stm.RT (how long it took them to
#    react to the stimulus)

#################################### Faces ####################################

faces_df <- read.csv(paste0(base_path, 'combined/task-faces.csv'))
faces_df <- faces_df[faces_df$Subject %in% sub & faces_df$Session %in% ses, ]
row.names(faces_df) <- 1:nrow(faces_df)


eprime_to_pulse = faces_df[1, 'Stm.OnsetTime'] - # TO DO: Look at design file for constant
