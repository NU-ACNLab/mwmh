### This script is designed to replace heudiconv because it is bugging out in
### far too many ways.
###
### Ellyn Butler
### April 19, 2022 - April 21, 2022

import pydicom #https://github.com/pydicom/pydicom
# https://pydicom.github.io/pydicom/stable/old/getting_started.html
import os
import pandas as pd
import numpy as np
from datetime import datetime
from nipype.interfaces.dcm2nii import Dcm2niix

indir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/dicoms'
outdir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids'

#sub = 'sub-MWMH320'
#ses = 'ses-1'

def curate_scan(sub, ses, scan, indir):
    dicomdir = indir+'/'+sub+'/'+ses+'/SCANS/'+scan+'/DICOM'
    dcm_path = os.popen('find '+dicomdir+' -name "*.dcm"').read().split("\n")[0]
    dicoms = os.popen('find '+dicomdir+' -name "*.dcm"').read().split("\n")[:-1]
    ndicoms = len(dicoms)
    # If the sub outdir doesn't exist, make it
    if not os.path.isdir(outdir+'/'+sub):
        os.mkdir(outdir+'/'+sub)
    # If the ses outdir doesn't exist, make it
    if not os.path.isdir(outdir+'/'+sub+'/'+ses):
        os.mkdir(outdir+'/'+sub+'/'+ses)
    ssoutdir = outdir+'/'+sub+'/'+ses
    if len(dcm_path) > 0:
        dcm = pydicom.dcmread(dcm_path)
        # T1w image
        if (('l_epinav_ME2' in dcm.ProtocolName) or 'MPRAGE_SAG_0.8iso' in dcm.ProtocolName) and (ndicoms == 208) and (dcm.AcquisitionMatrix[1] == 320):
            # If the modality directory doesn't exist, make it
            if not os.path.isdir(ssoutdir+'/anat'):
                os.mkdir(ssoutdir+'/anat')
            converter = Dcm2niix()
            converter.inputs.source_dir = dicomdir
            converter.inputs.compression = 5
            converter.inputs.output_dir = ssoutdir+'/anat'
            converter.run()
            # Rename files to be BIDS compliant
            anatjson = os.popen('find '+ssoutdir+'/anat'+' -name "*.json"').read().split("\n")[0]
            os.rename(anatjson, ssoutdir+'/anat/'+sub+'_'+ses+'_T1w.json')
            anatnifti = os.popen('find '+ssoutdir+'/anat'+' -name "*.nii.gz"').read().split("\n")[0]
            os.rename(anatnifti, ssoutdir+'/anat/'+sub+'_'+ses+'_T1w.nii.gz')
        # DTI 9 (10-13 derived)
        elif ('DTI_MB4_68dir_1pt5mm_b1k' == dcm.SeriesDescription) and (ndicoms > 60) and (ndicoms < 70) and (dcm.SliceThickness == 1.5) and (dcm.RepetitionTime == 2500):

        # faces 16 (15 for 181 1)
        elif (('FACES' in dcm.ProtocolName) or ('MB2_task' in dcm.ProtocolName)) and (ndicoms < 205) and (ndicoms > 195) and (dcm.SliceThickness < 1.8):

        # passive avoidance 17
        elif (('PASSIVE' in dcm.ProtocolName) or ('MB2_task' in dcm.ProtocolName)) and (ndicom > 295) and (ndicoms < 305) and (dcm.SliceThickness < 1.8):

        # resting state 18
        elif ('Mb8_rest_HCP' in dcm.ProtocolName) and (dcm.SliceThickness == 2):






subjects = os.listdir(indir)
subjects = [item for item in subjects if 'sub' in item]

#sub = 'sub-MWMH179'
for sub in subjects:
    sessions = os.listdir(indir+'/'+sub)
    sessions = [item for item in sessions if 'ses' in item]
    for ses in sessions:
        scans = os.listdir(indir+'/'+sub+'/'+ses+'/SCANS/')
        scans = [item for item in scans if 'DICOM' in os.listdir(indir+'/'+sub+'/'+ses+'/SCANS/'+item)]
        for scan in scans:
            curate_scan(sub, ses, scan, indir)
