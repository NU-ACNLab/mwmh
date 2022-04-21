### This script checks that the curate conditions in manually_curate.py do not
### pick up on any unwanted scans
###
### Ellyn Butler
### April 21, 2022

df <- read.csv('/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta/params_2022-04-20.csv')

# How many sessions are in here? 448
length(unique(paste0(df$subid, df$sesid)))


##################################### T1w #####################################

t1w_df <- df[grepl('tfl_epinav_ME2', df$ProtocolName) & df$NDicoms == 208,
  c('RepetitionTime', 'SequenceName', 'SliceThickness')]
dim(t1w_df) # Should be 448...
dim(df[df$NDicoms == 208,]) # 463... Loosen ProtocolName restriction?

t1w_df2 <- df[df$NDicoms == 208, c('ProtocolName', 'RepetitionTime', 'SequenceName', 'SliceThickness')]
# A lot of them have "tffl" instead of "tfl"
unique(t1w_df2$ProtocolName) # four unique ones
table(t1w_df2$ProtocolName)

# 416 dicoms? Two separate echos

##################################### DTI #####################################

dti_df <- df[grepl('DTI_MB4_68dir_1pt5mm_b1k', df$ProtocolName) & df$NDicoms > 60 &
  df$SliceThickness == 1.5 & df$RepetitionTime == 2500,]
dim(dti_df) # 2240 sessions... whoops. Need to be more exclusionary

dti_df2 <- df[grepl('DTI_MB4_68dir_1pt5mm_b1k', df$ProtocolName) & df$NDicoms > 60 &
  df$SliceThickness == 1.5 & df$RepetitionTime == 2500 & df$NDicoms < 70,]
dim(dti_df2) # 448. Yes.


#################################### FACES ####################################

faces_df <- df[(grepl('FACES', df$ProtocolName) | grepl('MB2_task', df$ProtocolName)) &
  df$NDicoms < 205 & df$NDicoms > 195 & df$SliceThickness < 1.8,]
dim(faces_df) # 424
table(faces_df$ProtocolName)

# Check out the wonky protocol name
faces_df[faces_df$ProtocolName == 'MB2_task_20_70_2000_1pt7iso', ]


#################################### AVOID ####################################

avoid_df <- df[(grepl('PASSIVE', df$ProtocolName) | grepl('MB2_task', df$ProtocolName)) &
  df$NDicoms < 305 & df$NDicoms > 295 & df$SliceThickness < 1.8,]
dim(avoid_df) # 431
table(avoid_df$ProtocolName)


##################################### REST #####################################

rest_df <- df[grepl('Mb8_rest_HCP', df$ProtocolName) & df$SliceThickness %in% 2,]
dim(rest_df) # 437





# TO DO:
# 1.) Check out task confusion with behavioral files. If behavioral files have
#     sequence number, should be able to figure out what this crap is.
#     Still a problem? Doesn't look like it.
boo <- df[df$ProtocolName == 'MB2_task_20_70_2000_1pt7iso', ]
df[grepl('MB2_task', df$ProtocolName), ]


#
