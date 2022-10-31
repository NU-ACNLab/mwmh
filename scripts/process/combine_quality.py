### This script combines the individual session csvs of amygdala connectivity
### into one master csv
###
### Ellyn Butler
### December 12, 2021 - October 25, 2022

import glob
import csv
import pandas as pd
from datetime import datetime

basedir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging'

files = glob.glob(basedir+'/amygconn/sub*/ses*/*_quality.csv')
df = pd.concat((pd.read_csv(f, header = 0) for f in files))

df.to_csv(basedir+'/tabulated/quality_'+datetime.today().strftime('%Y-%m-%d')+'.csv', index=False)
