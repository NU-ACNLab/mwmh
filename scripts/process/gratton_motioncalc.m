%This script runs Caterina's motion calc functions
%
% Ellyn Butler
% July 28, 2022 - August 1, 2022

%datafile = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/lists/test_list_for_motioncalc.xlsx'
datafile = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/lists/test_list_for_motioncalc_local.xlsx'

df = readtable(datafile)

numdatas = size(df.sub, 1)

contig_frames = 5

headSize = 50
FDthresh = 0.2
fFDthresh = 0.1
run_min = 50
tot_min = 150

mvm_fields = {'trans_x', 'trans_y', 'trans_z', 'rot_x', 'rot_y', 'rot_z'}
rot_IDs = logical([0 0 0 1 1 1]);

for i = 1:numdatas
    subject = df.sub{i}
    %where is the data stored for this particular session
    inputdir = [df.topDir{i} '/' df.dataFolder{i} '/fmriprep/sub-' subject '/ses-' num2str(df.sess(i)) '/func/'];
    outputdir = [df.topDir{i} '/fcon/sub-' subject '/ses-' num2str(df.sess(i))];
    if ~exist(outputdir)
        mkdir(outputdir);
    end

    % load motion data
    prefix = sprintf('sub-%s_ses-%d_task-%s_space-%s',subject,df.sess(i),df.task{i},df.space{i});
    confounds = bids.util.tsvread([inputdir prefix '_desc-confounds_timeseries.tsv']);
    
    % make a single matrix organized as we want
    mot_data_orig = [];
    for m = 1:length(mvm_fields)
        mot_data_orig = [mot_data_orig confounds.(mvm_fields{m})];
    end    








