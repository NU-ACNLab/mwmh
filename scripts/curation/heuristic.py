### This heuristic curates MWMH into BIDS
### Written for heudiconv v 0.9.0
###
### Ellyn Butler
### February 2, 2022 - February 9, 2022

import os

def create_key(template, outtype=('nii.gz',), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return template, outtype, annotation_classes

# Build lists of sequences
def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where
    allowed template fields - follow python string module:
    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """

    ##### Create Keys
    # Structural
    t1w = create_key(
       'sub-{subject}/anat/sub-{subject}_{session}_T1w') #dim3?

    # Diffusion
    dti = create_key(
        'sub-{subject}/{session}/func/sub-{subject}_{session}_dwi')

    # fMRI
    faces = create_key(
        'sub-{subject}/{session}/func/sub-{subject}_{session}_task-faces_bold')
    avoid = create_key(
        'sub-{subject}/{session}/func/sub-{subject}_{session}_task-avoid_bold')
    rest = create_key(
        'sub-{subject}/{session}/func/sub-{subject}_{session}_task-rest_bold')

    info = {t1w: [], dti: [], faces: [], avoid: [], rest: []}

    for idx, s in enumerate(seqinfo):
        if (s.dim3 == 208) and ('tfl_epinav_ME2' in s.protocol_name) and (s.is_derived == False):
            info[t1w].append(s.series_id)
        elif ('DTI_MB4_68dir' in s.protocol_name) and (s.is_derived == False):
            info[dti].append(s.series_id)
        elif ('FACES' in s.protocol_name) and (s.is_derived == False):
            info[faces].append(s.series_id)
        elif ('PASSIVE_AVOIDANCE' in s.protocol_name) and (s.is_derived == False):
            info[avoid].append(s.series_id)
        elif ('Mb8_rest_HCP' in s.protocol_name) and (s.is_derived == False):
            info[rest].append(s.series_id)

    return info

# Want this information in DWI json sidecars:
#{
#    "PhaseEncodingDirection": "__",
#    "TotalReadoutTime":__
#}
