### Parses duplicates
###
### Ellyn Butler
### November 18, 2021


df <- read.csv('/projects/b1108/data/MWMH/demographics/duplicate_T1w.csv')
table(df[, 3:4])
