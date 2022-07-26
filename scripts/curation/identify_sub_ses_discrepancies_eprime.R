### This script parses the output of `identify_sub_ses_discrepancies_eprime.sh`
### to find where the subject and session IDs disagree, and details what subject
#### and session identifiers in the eprime merge output need to be modified to
### match the date they were collected.
###
### Ellyn Butler
### July 26, 2022


df <- read.csv('/projects/b1108/studies/mwmh/data/processed/demographic/eprime_sub_ses_discrepancies.csv')

visit_df <- read.csv('/projects/b1108/studies/mwmh/data/processed/demographic/age_visits_2022-07-26.csv')

df[df$subid_dir != df$subid_edat | df$subid_dir != df$subid_txt |
   df$sesid_dir != df$sesid_edat | df$sesid_dir != df$sesid_txt, ]


########################### Going through one by one ###########################

# LOGIC: If the date from the visit of the sub/ses listed in the dir/edat name
# matches the date in the txt file, then the dir/edat name are the correct
# identifiers.

#### 1) subid_dir=MWMH320,sesid_dir=1,subid_edat=MWMH320,sesid_edat=1,
#       subid_txt=MWMH302,sesid_txt=1,date_txt=12-02-2016,task=PA
# A: sub-MWMH320_ses-1 (txt is wrong)

visit_df[visit_df$subid == 'MWMH320' & visit_df$sesid == 1, 'dov_mri']

#### 2) subid_dir=MWMH274,sesid_dir=2,subid_edat=MWMH274,sesid_edat=2,
#       subid_txt=MWMH274,sesid_txt=1,date_txt=08-16-2018,task=FACES
# A: sub-MWMH274_ses-2 (txt is wrong)

visit_df[visit_df$subid == 'MWMH274' & visit_df$sesid == 2, 'dov_mri']

#### 3) subid_dir=MWMH293,sesid_dir=2,subid_edat=MWMH293,sesid_edat=2,
#       subid_txt=MWMH298,sesid_txt=2,date_txt=09-10-2018,task=FACES
# A: sub-MWMH293_ses-2 (txt is wrong)

visit_df[visit_df$subid == 'MWMH293' & visit_df$sesid == 2, 'dov_mri']

#### 4) subid_dir=MWMH106,sesid_dir=2,subid_edat=MWMH106,sesid_edat=2,
#       subid_txt=MWMH106,sesid_txt=1,date_txt=07-29-2017,task=PA
# A: sub-MWMH106_ses-2 (txt is wrong)

visit_df[visit_df$subid == 'MWMH106' & visit_df$sesid == 2, 'dov_mri']

#### 5) subid_dir=MWMH236,sesid_dir=1,subid_edat=MWMH236,sesid_edat=1,
#       subid_txt=MWMH288,sesid_txt=1,date_txt=08-31-2016,task=FACES&PA
# A: sub-MWMH236_ses-1 (txt is wrong)

visit_df[visit_df$subid == 'MWMH236' & visit_df$sesid == 1, 'dov_mri']

#### 6) subid_dir=MWMH137,sesid_dir=2,subid_edat=MWMH137,sesid_edat=2,
#       subid_txt=MWMH137,sesid_txt=1,date_txt=07-29-2017,task=FACES&PA
# A: sub-MWMH137_ses-2 (txt is wrong)

visit_df[visit_df$subid == 'MWMH137' & visit_df$sesid == 2, 'dov_mri']

#### 7) subid_dir=MWMH135,sesid_dir=2,subid_edat=MWMH135,sesid_edat=2,
#       subid_txt=MWMH135,sesid_txt=1,date_txt=07-29-2017,task=PA&FACES
# A: sub-MWMH135_ses-2 (txt is wrong)

visit_df[visit_df$subid == 'MWMH135' & visit_df$sesid == 2, 'dov_mri']

#### 8) subid_dir=MWMH311,sesid_dir=1,subid_edat=MWMH311,sesid_edat=1,
#       subid_txt=MWMH290,sesid_txt=1,date_txt=10-22-2016,task=FACES&PA
# A: sub-MWMH311_ses-1 (txt is wrong)

visit_df[visit_df$subid == 'MWMH311' & visit_df$sesid == 1, 'dov_mri']

#### 9) subid_dir=MWMH376,sesid_dir=1,subid_edat=MWMH376,sesid_edat=1,
#       subid_txt=MWMH367,sesid_txt=1,date_txt=04-03-2017,task=PA&FACES
# A: sub-MWMH376_ses-1 (txt is wrong)

visit_df[visit_df$subid == 'MWMH376' & visit_df$sesid == 1, 'dov_mri']

#### 10) subid_dir=MWMH131,sesid_dir=2,subid_edat=MWMH131,sesid_edat=2,
#        subid_txt=MWMH131,sesid_txt=1,date_txt=07-29-2017,task=FACES&PA
# A: sub-MWMH131_ses-2 (txt is wrong)

visit_df[visit_df$subid == 'MWMH131' & visit_df$sesid == 2, 'dov_mri']




#################### Identify conflicts with other subjects ####################

# These are the sessions that cannot be merge with the others in E-Prime, because
# one of the two outputs may be overwritten, data that didn't exist in the actual
# session will come from another subject, or E-Prime will throw an error.

# LOGIC: If there is already a sub/ses in the visit_df with the sub/ses identifiers
# in the incorrect txts, there will be a conflict.

#### 1) subid_txt=MWMH302,sesid_txt=1
# A: CONFLICT

visit_df[visit_df$subid == 'MWMH302' & visit_df$sesid == 1, ]

#### 2) subid_txt=MWMH274,sesid_txt=1
# A: CONFLICT

visit_df[visit_df$subid == 'MWMH274' & visit_df$sesid == 1, ]

#### 3) subid_dir=MWMH293,sesid_dir=2
# A: CONFLICT

visit_df[visit_df$subid == 'MWMH293' & visit_df$sesid == 2, ]

#### 4) subid_txt=MWMH106,sesid_txt=1
# A: CONFLICT

visit_df[visit_df$subid == 'MWMH106' & visit_df$sesid == 1, ]

#### 5) subid_txt=MWMH288,sesid_txt=1
# A: No conflict (didn't have an MRI done for this session)

visit_df[visit_df$subid == 'MWMH288' & visit_df$sesid == 1, ]

#### 6) subid_txt=MWMH137,sesid_txt=1
# A: CONFLICT

visit_df[visit_df$subid == 'MWMH137' & visit_df$sesid == 1, ]

#### 7) subid_txt=MWMH135,sesid_txt=1
# A: CONFLICT

visit_df[visit_df$subid == 'MWMH135' & visit_df$sesid == 1, ]

#### 8) subid_txt=MWMH290,sesid_txt=1
# A: CONFLICT

visit_df[visit_df$subid == 'MWMH290' & visit_df$sesid == 1, ]

#### 9) subid_txt=MWMH367,sesid_txt=1
# A: CONFLICT

visit_df[visit_df$subid == 'MWMH367' & visit_df$sesid == 1, ]

#### 10) subid_txt=MWMH131,sesid_txt=1
# A: CONFLICT

visit_df[visit_df$subid == 'MWMH131' & visit_df$sesid == 1, ]










###### TO DO:
# 1) Modify subid for MWMH192 to exclude period at the end in E-Prime merge output




#
