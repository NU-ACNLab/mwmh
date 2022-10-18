### This script contains a function that outputs quality metrics in a pandas
### dataframe, along with subject and session ids
###
### Ellyn Butler
### October 18, 2022

import pandas as pd
import numpy as np

def get_qual_metrics(confounds_df, task, subid, sesid):
    qual_dict = {
        'subid':[],
        'sesid':[],
        'task':[],
        'mean_fd':[],
        'mean_ffd':[],
        'num_trs':[],
        'num_trs_kept':[]
    }
    qual_dict['subid'].append(subid)
    qual_dict['sesid'].append(sesid)
    qual_dict['task'].append(task)
    qual_dict['mean_fd'].append(confounds_df['framewise_displacement'].mean())
    qual_dict['mean_ffd'].append(confounds_df['ffd'].mean())
    qual_dict['num_trs'].append(confounds_df.shape[0])
    qual_dict['num_trs_kept'].append(confounds_df['keep_ffd'].sum())
    qual_df = pd.DataFrame.from_dict(qual_dict)
    return qual_df
