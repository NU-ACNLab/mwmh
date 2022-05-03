### This script creates a csv of the various key parameters in the dicom headers
### for all of the sequences, subjects and sessions
###
### Ellyn Butler
### February 1, 2022 - May 3, 2022

import pydicom #https://github.com/pydicom/pydicom
# https://pydicom.github.io/pydicom/stable/old/getting_started.html
import os
import pandas as pd
from datetime import datetime

indir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/dicoms'
subdirs = os.popen('find '+indir+' -maxdepth 1 -name "sub-MWMH*"').read().split("\n")[:-1]
#subject_dirs = [sub.replace('\n', '') for sub in subject_dirs]

param_dict = {
    'subid':[],
    'sesid':[],
    'Modality':[],
    'AcquisitionDate':[],
    'SeriesNumber':[],
    'EchoNumbers':[],
    'EchoTime':[],
    'FlipAngle':[],
    'InPlanePhaseEncodingDirection':[],
    'ProtocolName':[],
    'RepetitionTime':[],
    'SequenceName':[],
    'SliceThickness':[],
    'NDicoms':[]
}

for subdir in subdirs:
    sessions = os.listdir(subdir)
    sessions = [item for item in sessions if 'ses' in item]
    sesdirs = [subdir+'/'+ses for ses in sessions]
    for sesdir in sesdirs:
        sequences = os.popen('ls '+sesdir+'/SCANS/').read().split("\n")[:-1]
        sequences = [seq for seq in sequences if seq != 'junk']
        sequences = [seq for seq in sequences if '99' not in seq]
        sub = sesdir.split('/')[9].split('-')[1]
        ses = sesdir.split('/')[10].split('-')[1]
        for seq in sequences:
            if os.path.isdir(sesdir+'/SCANS/'+seq+'/DICOM/'):
                dcm_path = os.popen('find '+sesdir+'/SCANS/'+seq+'/DICOM/ -name "*.dcm"').read().split("\n")[0]
                if len(dcm_path) == 0:
                    dcm_path = os.popen('find '+sesdir+'/SCANS/'+seq+'/DICOM/ -regex ".*/[0-9]+"').read().split("\n")[0]
                if len(dcm_path) > 0:
                    dcm = pydicom.dcmread(dcm_path)
                    param_dict['subid'].append(sub)
                    param_dict['sesid'].append(ses)
                    if hasattr(dcm, 'AcquisitionDate'):
                        param_dict['AcquisitionDate'].append(dcm.AcquisitionDate)
                    else:
                        param_dict['AcquisitionDate'].append('NA')
                    if hasattr(dcm, 'SeriesNumber'):
                        param_dict['SeriesNumber'].append(dcm.SeriesNumber)
                    else:
                        param_dict['SeriesNumber'].append('NA')
                    if hasattr(dcm, 'EchoNumbers'):
                        param_dict['EchoNumbers'].append(dcm.EchoNumbers)
                    else:
                        param_dict['EchoNumbers'].append('NA')
                    if hasattr(dcm, 'EchoTime'):
                        param_dict['EchoTime'].append(dcm.EchoTime)
                    else:
                        param_dict['EchoTime'].append('NA')
                    if hasattr(dcm, 'FlipAngle'):
                        param_dict['FlipAngle'].append(dcm.FlipAngle)
                    else:
                        param_dict['FlipAngle'].append('NA')
                    #param_dict['ImageType'].append(dcm.ImageType)
                    if hasattr(dcm, 'InPlanePhaseEncodingDirection'):
                        param_dict['InPlanePhaseEncodingDirection'].append(dcm.InPlanePhaseEncodingDirection)
                    else:
                        param_dict['InPlanePhaseEncodingDirection'].append('NA')
                    param_dict['Modality'].append(dcm.Modality)
                    param_dict['ProtocolName'].append(dcm.ProtocolName)
                    if hasattr(dcm, 'RepetitionTime'):
                        param_dict['RepetitionTime'].append(dcm.RepetitionTime)
                    else:
                        param_dict['RepetitionTime'].append('NA')
                    if hasattr(dcm, 'SequenceName'):
                        param_dict['SequenceName'].append(dcm.SequenceName)
                    else:
                        param_dict['SequenceName'].append('NA')
                    if hasattr(dcm, 'SliceThickness'):
                        param_dict['SliceThickness'].append(dcm.SliceThickness)
                    else:
                        param_dict['SliceThickness'].append('NA')
                    # Count the number of dicoms in the dicom directory
                    dicoms = os.popen('find '+sesdir+'/SCANS/'+seq+'/DICOM/'+' -name "*.dcm"').read().split("\n")[:-1]
                    ndicoms = len(dicoms)
                    param_dict['NDicoms'].append(ndicoms)

param_df = pd.DataFrame.from_dict(param_dict)
param_df.to_csv('/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta/params_'+datetime.today().strftime('%Y-%m-%d')+'.csv', index=False)
