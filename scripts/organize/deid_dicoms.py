### This script removes PHI from the dicom headers for sub-MWMH278 for Kang Hyun
### https://pydicom.github.io/pydicom/stable/tutorials/dataset_basics.html
###
### Ellyn Butler
### November 6, 2022

from glob import glob
import os
import pydicom

subdir = '/home/erb9722/scratch/sub-MWMH278'

sessions = os.listdir(subdir)
sessions = [item for item in sessions if 'ses' in item]
sesdirs = [subdir+'/'+ses for ses in sessions]
for sesdir in sesdirs:
    sequences = os.popen('ls '+sesdir+'/SCANS/').read().split("\n")[:-1]
    sequences = [seq for seq in sequences if seq != 'junk']
    sequences = [seq for seq in sequences if '99' not in seq]
    ses = sesdir.split('/')[5].split('-')[1]
    for seq in sequences:
        if os.path.isdir(sesdir+'/SCANS/'+seq+'/DICOM/'):
            dicomdir = subdir+'/ses-'+ses+'/SCANS/'+seq+'/DICOM'
            dcm_paths = os.popen('find '+dicomdir+' -name "*.dcm"').read().split("\n")[:-1]
            if len(dcm_paths) > 0:
                for dcm_path in dcm_paths:
                    dcm = pydicom.dcmread(dcm_path)
                    if hasattr(dcm, 'PatientBirthDate'):
                        dcm.PatientBirthDate = ''
                        dcm.save_as(dcm_path)
