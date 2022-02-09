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
       'sub-{subject}/anat/sub-{subject}_{session}_T1w') #                                   t1_mpg_sag_0.8iso

    # Diffusion
    dti = create_key(
        'sub-{subject}/{session}/func/sub-{subject}_{session}_task-faces_bold')

    # fMRI
    faces = create_key(
        'sub-{subject}/{session}/func/sub-{subject}_{session}_task-faces_bold')
    avoid = create_key(
        'sub-{subject}/{session}/func/sub-{subject}_{session}_task-avoid_bold')
    rest = create_key(
        'sub-{subject}/{session}/func/sub-{subject}_{session}_task-rest_bold')

    info = {t1w: [], mid_dirAP: [], mid_dirPA: [], mid_dirPA: [], chat_dirPA: []}

    for idx, s in enumerate(seqinfo):
        if (s.dim1 == 320) and ('t1_mpg_sag_0.8iso' in s.protocol_name) and (s.is_derived == False):
            info[t1w].append(s.series_id)
        elif (s.dim1 == 96) and (s.dim4 == 10) and ('cmrr_MID_AP_run-1' in s.protocol_name):
            info[mid_dirAP].append(s.series_id)
        elif (s.dim1 == 96) and (s.dim4 > 200) and ('cmrr_MID_run-1' in s.protocol_name):
            info[mid_dirPA].append(s.series_id)
        elif (s.dim1 == 96) and ('cmrr_MID_AP_run-1' in s.protocol_name):
            info[chat_dirPA].append(s.series_id)
    return info

# Specify which niftis will be used for distortion correction (key), and which images
# they are correcting distortion for (value: list)
# October 25, 2021: IntendedFor not obviously showing up in BIDS. I don't think
# the key is supposed to be a string, based on what Tinashe did for the PNC,
# but heudiconv doesn't run unless I make it a string. Might be the issue.
IntendedFor = {
    'mid_dirAP': [
        'sub-{subject}/func/sub-{subject}_task-mid_dir-PA_bold',
        'sub-{subject}/func/sub-{subject}_task-chat_dir-PA_bold'
    ]
}
