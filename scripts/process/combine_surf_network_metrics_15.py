### This script combines the individual session csvs of amygdala connectivity
### into one master csv
###
### Ellyn Butler
### March 30, 2025

import glob
import csv
import pandas as pd
from datetime import datetime

basedir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging'

files = glob.glob(basedir+'/surfnet/sub*/ses*/*_surf_network_metrics_15.csv')
df = pd.concat((pd.read_csv(f, header = 0) for f in files))

df.to_csv(basedir+'/tabulated/surf_network_metrics_15_'+datetime.today().strftime('%Y-%m-%d')+'.csv', index=False)
