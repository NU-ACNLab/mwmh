### This script estimates within network connectivity by averaging the Pearson
### correlations between regions within a given network
###
### Ellyn Butler
### June 29, 2023

import os
import numpy as np #1.19.1
import argparse
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-i', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/amygconn/')
parser.add_argument('-o', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/networkconn/')
parser.add_argument('-s')
parser.add_argument('-ss')
args = parser.parse_args()

indir = args.i #indir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/amygconn/'
outdir = args.o #outdir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/networkconn/'
sub = args.s #sub = 'sub-MWMH359'
ses = args.ss #ses = 'ses-1'

# Directory where the Seitzman correlation matrices are
subindir = os.path.join(indir, sub)
sesindir = os.path.join(subindir, ses)

# Directory where outputs should go
suboutdir = os.path.join(outdir, sub)
sesoutdir = os.path.join(suboutdir, ses)
os.makedirs(os.path.join(outdir, sub, ses), exist_ok=True)

# Get the IDs
subid = sub.split('-')[1]
sesid = ses.split('-')[1]

# Get the labeled image and labels
seitzdir = '/projects/b1081/Atlases/Seitzman300/' #seitzdir='/Users/flutist4129/Documents/Northwestern/templates/Seitzman300/'
network_df = pd.read_csv(seitzdir+'ROIs_extended_info.txt', sep=',')

corr_matrix = pd.read_csv(sesindir+'/'+sub+'_'+ses+'_atlas-seitz_corrmat.csv',
                            header=None, sep=',')

networks = network_df['netName'].unique()

ave_dict = {
    'subid':subid,
    'sesid':sesid,
    'unassigned':[],
    'SomatomotorDorsal':[],
    'SomatomotorLateral':[],
    'CinguloOpercular':[],
    'Auditory':[],
    'DefaultMode':[],
    'ParietoMedial':[],
    'Visual':[],
    'FrontoParietal':[],
    'Salience':[],
    'VentralAttention':[],
    'DorsalAttention':[],
    'MedialTemporalLobe':[],
    'Reward':[]
}

for net in networks:
    # get the row numbers for the regions that are part of the network
    net_indices = network_df[network_df['netName'] == net].index
    net_corr = corr_matrix[net_indices]
    net_corr = net_corr.iloc[net_indices]
    net_corr = net_corr.to_numpy()
    numi = len(net_indices)
    ave_conn = (np.sum(net_corr) - numi)/(2*(numi*numi - numi)) # TO DO Jun 29: figure out what to do about nans
    ave_dict[net] = ave_conn

ave_df = pd.DataFrame.from_dict(ave_dict)
param_df.to_csv(sesoutdir+sub+'_'+ses+'_networkconn.csv', index=False)
