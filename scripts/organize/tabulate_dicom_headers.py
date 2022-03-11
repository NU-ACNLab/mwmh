### This script creates a csv of the various key parameters in the dicom headers
### for all of the sequences, subjects and sessions
###
### Ellyn Butler
### February 1, 2022 - March 8, 2022

import pydicom #https://github.com/pydicom/pydicom
# https://pydicom.github.io/pydicom/stable/old/getting_started.html
import os
import pandas as pd
from datetime import datetime

todd_dir = '/projects/b1108/todd'
subject_dirs = os.popen('find '+todd_dir+' -maxdepth 1 -name "MWMH*"').read().split("\n")[:-1]
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

for sub_dir in subject_dirs:
    sequences = os.popen('ls '+sub_dir+'/SCANS/').read().split("\n")[:-1]
    sequences = [seq for seq in sequences if seq != 'junk']
    # Skip 99, not a real sequence?
    sequences = [seq for seq in sequences if '99' not in seq]
    if 'C' in sub_dir:
        sub = sub_dir.split('/')[-1].split('C')[0]
        ses = int(sub_dir.split('/')[-1].split('V')[1].split('_')[0].split('-')[0])
    else:
        sub = sub_dir.split('/')[-1].split('_')[0]
        osub_dir = os.popen('find '+todd_dir+' -maxdepth 1 -name "'+sub+'CV*"').read().split("\n")[0]
        oses = int(osub_dir.split('/')[-1].split('V')[1].split('_')[0].split('-')[0])
        if oses == 1:
            ses = 2
        else:
            ses = 1
    if sub == 'MWMH257' and ses == 1:
        print(sub, ses)
    for seq in sequences:
        dcm_path = os.popen('find '+sub_dir+'/SCANS/'+seq+'/DICOM/ -name "*.dcm"').read().split("\n")[0]
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
            dicoms = os.popen('find '+sub_dir+'/SCANS/'+seq+'/DICOM/'+' -name "*.dcm"').read().split("\n")[:-1]
            ndicoms = len(dicoms)
            param_dict['NDicoms'].append(ndicoms)

param_df = pd.DataFrame.from_dict(param_dict)
param_df.to_csv('/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta/params_'+datetime.today().strftime('%Y-%m-%d')+'.csv', index=False)
