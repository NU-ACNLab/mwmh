### This script conducts the post-processing steps after fmriprep
###
### Ellyn Butler
### November 22, 2021 - October 20, 2022

# Python version: 3.8.4
import os
import json
import pandas as pd #1.0.5
import nibabel as nib #3.2.1
import numpy as np #1.19.1
#from bids.layout import BIDSLayout #may not be needed
from nilearn.input_data import NiftiLabelsMasker #0.8.1
from nilearn import plotting
from nilearn import signal
from nilearn import image
import matplotlib
matplotlib.use('pdf')
import matplotlib.pyplot as plt
import scipy.signal as sgnl
import sys, getopt
import argparse
from postproc_rest_space_mni import postproc_rest_space_mni
from postproc_avoid_space_mni import postproc_avoid_space_mni
from postproc_faces_space_mni import postproc_faces_space_mni

parser = argparse.ArgumentParser()
parser.add_argument('-i', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.2.0/')
parser.add_argument('-o', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/postproc/')
parser.add_argument('-b', default='/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/')
parser.add_argument('-s')
parser.add_argument('-ss')
parser.add_argument('-t', nargs='+') #https://www.codegrepper.com/code-examples/python/python+argparse+multiple+values
args = parser.parse_args()

indir = args.i #indir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep/'
outdir = args.o #outdir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/amygconn/'
bidsdir = args.b #bidsdir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/neuroimaging/bids/'
sub = args.s #sub = 'sub-MWMH359'
ses = args.ss #ses = 'ses-1'
tasks = args.t

# Directory where preprocessed fMRI data is located
subindir = os.path.join(indir, sub)
sesindir = os.path.join(subindir, ses)
funcindir = os.path.join(sesindir, 'func')

# Directory where outputs should go
suboutdir = os.path.join(outdir, sub)
sesoutdir = os.path.join(suboutdir, ses)
os.makedirs(os.path.join(outdir, sub, ses), exist_ok=True)

# Get the bids directory for this session
bidssubdir = os.path.join(bidsdir, sub)
bidssesdir = os.path.join(bidssubdir, ses)

############################ Process available tasks ###########################

if 'rest' in tasks:
    postproc_rest_space_mni(sub, ses, funcindir, bidssesdir, sesoutdir)
if 'avoid' in tasks:
    postproc_avoid_space_mni(sub, ses, funcindir, bidssesdir, sesoutdir)
if 'faces' in tasks:
    postproc_faces_space_mni(sub, ses, funcindir, bidssesdir, sesoutdir)
