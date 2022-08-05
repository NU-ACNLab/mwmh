%This script runs Caterina's motion calc functions
%
% Ellyn Butler
% July 28, 2022 - August 1, 2022

% load paths
%addpath('/Users/flutist4129/Documents/Northwestern/bids/bids-matlab')
addpath('/projects/b1108/software/bids-matlab')
%addpath('/Users/flutist4129/Documents/Northwestern/gratton/GrattonLab-General-Repo/motion_calc_utilities')
addpath('/projects/b1108/GrattonLab-General-Repo/motion_calc_utilities')

datafile = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/lists/test_list_for_motioncalc.xlsx'
%datafile = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/lists/test_list_for_motioncalc_local.xlsx'

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
    % get in and output dirs
    inputdir = [df.topDir{i} '/' df.dataFolder{i} '/fmriprep/sub-' subject '/ses-' num2str(df.sess(i)) '/func/'];
    outputdir = [df.topDir{i} '/' df.dataFolder{i} '/fcon/sub-' subject '/ses-' num2str(df.sess(i)) '/'];
    if ~exist(outputdir)
        mkdir(outputdir);
    end

    % load motion data
    prefix = sprintf('sub-%s_ses-%d_task-%s',subject,df.sess(i),df.task{i});
    confounds = bids.util.tsvread([inputdir prefix '_desc-confounds_timeseries.tsv']);
    
    % make a single matrix organized as we want
    mot_data_orig = [];
    for m = 1:length(mvm_fields)
        mot_data_orig = [mot_data_orig confounds.(mvm_fields{m})];
    end    

    % start by doing some conversions
    % Convert roll, pitch, and yaw to mm (other parameters already in
    % mm). fmriprep = rotation in radians
    mot_data(:,rot_IDs) = mot_data_orig(:,rot_IDs).* headSize ; %.* 2 * pi./360; % rotation params modified
    mot_data(:,~rot_IDs) = mot_data_orig(:,~rot_IDs); % translation params stay the same
        
    % filter mot data
    mot_data_filtered = filter_motion(df.TR(i),mot_data);

    % save motion data
    writetable(table(mot_data(:,1),mot_data(:,2),mot_data(:,3),mot_data(:,4),mot_data(:,5),mot_data(:,6),...
           'VariableNames',mvm_fields),sprintf('%s%s_desc-mvm.txt',outputdir,prefix))
    writetable(table(mot_data_filtered(:,1),mot_data_filtered(:,2),mot_data_filtered(:,3),...
           mot_data_filtered(:,4),mot_data_filtered(:,5),mot_data_filtered(:,6),...
               'VariableNames',mvm_fields),sprintf('%s%s_desc-mvm_filt.txt',outputdir,prefix))
    
    % calculate FD pre and post filtering
    mot_data_diff = [zeros(1,6); diff(mot_data)];
    mot_data_filt_diff = [zeros(1,6); diff(mot_data_filtered)];
    FD = sum(abs(mot_data_diff),2);
    fFD = sum(abs(mot_data_filt_diff),2);
    writetable(table(FD),sprintf('%s%s_desc-FD.txt',outputdir,prefix));
    writetable(table(fFD),sprintf('%s%s_desc-fFD.txt',outputdir,prefix));

    % plot original parameters and FD
    plot_motion_params(mot_data,FD,FDthresh,mvm_fields);
    print(gcf,sprintf('%s%s_desc-motion_parameters.pdf',outputdir,prefix),'-dpdf','-bestfit');
    plot_motion_params(mot_data_filtered,fFD,fFDthresh,mvm_fields);
    print(gcf,sprintf('%s%s_desc-motion_parameters_filtered.pdf',outputdir,prefix),'-dpdf','-bestfit');

    % make some plots - FFT
    mot_FFT(mot_data,df.TR(i),1);
    print(gcf,sprintf('%s%s_desc-motion_FFT.pdf',outputdir,prefix),'-dpdf','-bestfit');
    mot_FFT(mot_data_filtered,df.TR(i),1);
    print(gcf,sprintf('%s%s_desc-motion_filtered_FFT.pdf',outputdir,prefix),'-dpdf','-bestfit');

    % make a tmask for each run
    DropFramesTR = df.dropFr(i); 
    tmask_FD = make_tmask(FD,FDthresh,DropFramesTR,contig_frames);
    tmask_fFD = make_tmask(fFD,fFDthresh,DropFramesTR,contig_frames);
    writetable(table(tmask_FD),sprintf('%s%s_desc-tmask_FD.txt',outputdir,prefix));
    writetable(table(tmask_fFD),sprintf('%s%s_desc-tmask_fFD.txt',outputdir,prefix));

    % some stats to keep track of
    good_run_FD = sum(tmask_FD) > run_min;
    good_run_fFD = sum(tmask_fFD) > run_min;
    run_frame_nums_FD = sum(tmask_FD);
    run_frame_nums_fFD = sum(tmask_fFD);
    run_frame_per_FD = sum(tmask_FD)./numel(tmask_FD);
    run_frame_per_fFD = sum(tmask_fFD)./numel(tmask_fFD);
        
    % save out some general info
    writetable(table(good_run_FD'),sprintf('%s/sub-%s_ses-%d_task-%s_desc-goodruns_FD.txt',outputdir,subject,df.sess(i),df.task{i}));
    writetable(table(good_run_fFD'), sprintf('%s/sub-%s_ses-%d_task-%s_desc-goodruns_fFD.txt',outputdir,subject,df.sess(i),df.task{i}));
    
    writetable(table(run_frame_nums_FD'),sprintf('%s/sub-%s_ses-%d_task-%s_desc-framenums_FD.txt',outputdir,subject,df.sess(i),df.task{i}));
    writetable(table(run_frame_nums_fFD'),sprintf('%s/sub-%s_ses-%d_task-%s_desc-framenums_fFD.txt',outputdir,subject,df.sess(i),df.task{i}));
    
    writetable(table(run_frame_per_FD'),sprintf('%s/sub-%s_ses-%d_task-%s_desc-framepers_FD.txt',outputdir,subject,df.sess(i),df.task{i}));
    writetable(table(run_frame_per_fFD'),sprintf('%s/sub-%s_ses-%d_task-%s_desc-framepers_fFD.txt',outputdir,subject,df.sess(i),df.task{i}));
    
    close('all');
    clear mot_data;  

    clear good_run_FD run_frame_nums_FD run_frame_per_FD;
    clear good_run_fFD run_frame_nums_fFD run_frame_per_fFD;
end














