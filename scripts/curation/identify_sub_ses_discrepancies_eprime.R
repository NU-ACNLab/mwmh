### This script parses the output of `identify_sub_ses_discrepancies_eprime.sh`
### to find where the subject and session IDs disagree. `modify_eprime_merge.R`
### then details what subject and session identifiers in the eprime merge output
### need to be modified to match the date they were collected.
###
### Ellyn Butler
### July 26, 2022


df <- read.csv('/projects/b1108/studies/mwmh/data/processed/demographic/eprime_sub_ses_discrepancies.csv')

df[df$subid_dir != df$subid_edat | df$subid_dir != df$subid_txt |
   df$sesid_dir != df$sesid_edat | df$sesid_dir != df$sesid_txt, ]
