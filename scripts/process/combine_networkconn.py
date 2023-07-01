### This script combines the individual session csvs of network connectivity
### into one master csv
###
### Ellyn Butler
### July 1, 2023

import glob
import csv
import pandas as pd
from datetime import datetime

basedir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging'

files = glob.glob(basedir+'/networkconn/sub*/ses*/*_networkconn.csv')
df = pd.concat((pd.read_csv(f, header = 0) for f in files))

df.to_csv(basedir+'/tabulated/networkconn_'+datetime.today().strftime('%Y-%m-%d')+'.csv', index=False)
