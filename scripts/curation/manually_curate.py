### This script is designed to replace heudiconv because it is bugging out in
### far too many ways.
###
### Ellyn Butler
### April 19, 2022 - May 3, 2022

import pydicom #https://github.com/pydicom/pydicom
# https://pydicom.github.io/pydicom/stable/old/getting_started.html
import os
import pandas as pd
import numpy as np
from datetime import datetime
from nipype.interfaces.dcm2nii import Dcm2niix
import json
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-i', default='/projects/b1108/studies/mwmh/data/raw/neuroimaging/dicoms')
parser.add_argument('-o', default='/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids')
parser.add_argument('-s')
parser.add_argument('-ss')
args = parser.parse_args()

indir = args.i
outdir = args.o
sub = args.s
ses = args.ss

def convert_dicoms(dicomdir, bidsdir, modality):
    converter = Dcm2niix()
    converter.inputs.source_dir = dicomdir
    converter.inputs.compression = 5
    converter.inputs.output_dir = bidsdir+'/'+modality
    converter.run()


def curate_scan(sub, ses, scan, indir):
    dicomdir = indir+'/'+sub+'/'+ses+'/SCANS/'+scan+'/DICOM'
    dcm_path = os.popen('find '+dicomdir+' -name "*.dcm"').read().split("\n")[0]
    dicoms = os.popen('find '+dicomdir+' -name "*.dcm"').read().split("\n")[:-1]
    if len(dcm_path) == 0:
        dcm_path = os.popen('find '+dicomdir+' -regex ".*/[0-9]+"').read().split("\n")[0]
        dicoms = os.popen('find '+dicomdir+' -regex ".*/[0-9]+"').read().split("\n")[:-1]
    ndicoms = len(dicoms)
    # If the sub outdir doesn't exist, make it
    if not os.path.isdir(outdir+'/'+sub):
        os.mkdir(outdir+'/'+sub)
    # If the ses outdir doesn't exist, make it
    if not os.path.isdir(outdir+'/'+sub+'/'+ses):
        os.mkdir(outdir+'/'+sub+'/'+ses)
    bidsdir = outdir+'/'+sub+'/'+ses
    if ndicoms > 10:
        dcm = pydicom.dcmread(dcm_path)
        # T1w image
        if (('l_epinav_ME2' in dcm.ProtocolName) or 'MPRAGE_SAG_0.8iso' in dcm.ProtocolName) and (ndicoms == 208) and (dcm.AcquisitionMatrix[1] == 320):
            # If the modality directory doesn't exist, make it
            modality = 'anat'
            if not os.path.isdir(bidsdir+'/'+modality):
                os.mkdir(bidsdir+'/'+modality)
            convert_dicoms(dicomdir, bidsdir, modality)
            filejson = os.popen('find '+bidsdir+'/'+modality+' -name "*.json"').read().split("\n")[0]
            os.rename(filejson, bidsdir+'/'+modality+'/'+sub+'_'+ses+'_T1w.json')
            nifti = os.popen('find '+bidsdir+'/'+modality+' -name "*.nii.gz"').read().split("\n")[0]
            os.rename(nifti, bidsdir+'/'+modality+'/'+sub+'_'+ses+'_T1w.nii.gz')
        # DTI 9 (10-13 derived)
        elif ('DTI_MB4_68dir_1pt5mm_b1k' == dcm.SeriesDescription) and (ndicoms > 60) and (ndicoms < 70) and (dcm.SliceThickness == 1.5) and (dcm.RepetitionTime == 2500):
            modality = 'dwi'
            if not os.path.isdir(bidsdir+'/'+modality):
                os.mkdir(bidsdir+'/'+modality)
            convert_dicoms(dicomdir, bidsdir, modality)
            # Rename files to be BIDS compliant
            filejson = os.popen('find '+bidsdir+'/'+modality+' -name "*.json"').read().split("\n")[0]
            os.rename(filejson, bidsdir+'/'+modality+'/'+sub+'_'+ses+'_'+modality+'.json')
            nifti = os.popen('find '+bidsdir+'/'+modality+' -name "*.nii.gz"').read().split("\n")[0]
            os.rename(nifti, bidsdir+'/'+modality+'/'+sub+'_'+ses+'_'+modality+'.nii.gz')
            bvec = os.popen('find '+bidsdir+'/'+modality+' -name "*.bvec"').read().split("\n")[0]
            os.rename(bvec, bidsdir+'/'+modality+'/'+sub+'_'+ses+'_'+modality+'.bvec')
            bval = os.popen('find '+bidsdir+'/'+modality+' -name "*.bval"').read().split("\n")[0]
            os.rename(bval, bidsdir+'/'+modality+'/'+sub+'_'+ses+'_'+modality+'.bval')
        # faces 16 (15 for 181 1)
        elif (('FACES' in dcm.ProtocolName) or ('MB2_task' in dcm.ProtocolName)) and (ndicoms < 205) and (ndicoms > 195) and (dcm.SliceThickness < 1.8):
            modality = 'func'
            if not os.path.isdir(bidsdir+'/'+modality):
                os.mkdir(bidsdir+'/'+modality)
            convert_dicoms(dicomdir, bidsdir, modality)
            filejson = os.popen('find '+bidsdir+'/'+modality+' -name "*FACES*.json"').read().split("\n")[0]
            if len(filejson) == 0:
                filejson = os.popen('find '+bidsdir+'/'+modality+' -name "*MB2_task*.json"').read().split("\n")[0]
            json_obj = json.load(open(filejson, 'r'))
            json_obj['TaskName'] = 'faces'
            with open(filejson, 'w') as f:
                json.dump(json_obj, f)
            os.rename(filejson, bidsdir+'/'+modality+'/'+sub+'_'+ses+'_task-faces_bold.json')
            nifti = os.popen('find '+bidsdir+'/'+modality+' -name "*FACES*.nii.gz"').read().split("\n")[0]
            if len(nifti) == 0:
                nifti = os.popen('find '+bidsdir+'/'+modality+' -name "*MB2_task*.nii.gz"').read().split("\n")[0]
            os.rename(nifti, bidsdir+'/'+modality+'/'+sub+'_'+ses+'_task-faces_bold.nii.gz')
        # passive avoidance 17
        elif (('PASSIVE' in dcm.ProtocolName) or ('MB2_task' in dcm.ProtocolName)) and (ndicoms > 295) and (ndicoms < 305) and (dcm.SliceThickness < 1.8):
            modality = 'func'
            if not os.path.isdir(bidsdir+'/'+modality):
                os.mkdir(bidsdir+'/'+modality)
            convert_dicoms(dicomdir, bidsdir, modality)
            filejson = os.popen('find '+bidsdir+'/'+modality+' -name "*PASSIVE*.json"').read().split("\n")[0]
            if len(filejson) == 0:
                filejson = os.popen('find '+bidsdir+'/'+modality+' -name "*MB2_task*.json"').read().split("\n")[0]
            json_obj = json.load(open(filejson, 'r'))
            json_obj['TaskName'] = 'avoid'
            with open(filejson, 'w') as f:
                json.dump(json_obj, f)
            os.rename(filejson, bidsdir+'/'+modality+'/'+sub+'_'+ses+'_task-avoid_bold.json')
            nifti = os.popen('find '+bidsdir+'/'+modality+' -name "*PASSIVE*.nii.gz"').read().split("\n")[0]
            if len(nifti) == 0:
                nifti = os.popen('find '+bidsdir+'/'+modality+' -name "*MB2_task*.nii.gz"').read().split("\n")[0]
            os.rename(nifti, bidsdir+'/'+modality+'/'+sub+'_'+ses+'_task-avoid_bold.nii.gz')
        # resting state 18
        elif ('Mb8_rest_HCP' in dcm.ProtocolName) and (dcm.SliceThickness == 2):
            modality = 'func'
            if not os.path.isdir(bidsdir+'/'+modality):
                os.mkdir(bidsdir+'/'+modality)
            convert_dicoms(dicomdir, bidsdir, modality)
            filejson = os.popen('find '+bidsdir+'/'+modality+' -name "*Mb8_rest_HCP*.json"').read().split("\n")[0]
            json_obj = json.load(open(filejson, 'r'))
            json_obj['TaskName'] = 'rest'
            with open(filejson, 'w') as f:
                json.dump(json_obj, f)
            os.rename(filejson, bidsdir+'/'+modality+'/'+sub+'_'+ses+'_task-rest_bold.json')
            nifti = os.popen('find '+bidsdir+'/'+modality+' -name "*Mb8_rest_HCP*.nii.gz"').read().split("\n")[0]
            os.rename(nifti, bidsdir+'/'+modality+'/'+sub+'_'+ses+'_task-rest_bold.nii.gz')

scans = os.listdir(indir+'/'+sub+'/'+ses+'/SCANS/')
scans = [item for item in scans if 'DICOM' in os.listdir(indir+'/'+sub+'/'+ses+'/SCANS/'+item)]
for scan in scans:
    curate_scan(sub, ses, scan, indir)
