function FDcalc_FMRIPREP(datafile,varargin)
% function for calculating FD and making tmasks from FMRIPREP
% difference from FMRIPREP output: filters FD values, does more
% conservative tmasking (contig frames, min per run, etc.)
%
% Dependencies:
% need the BIDS matlab toolbox in your path to load confounds: https://github.com/bids-standard/bids-matlab
% plotting_utilities: hline_new.m (see GrattonLab Scripts folder - better hline)
%
% Primary input:
% datafile = 'EXAMPLESUB_DATALIST.txt'
% varargin: structure with project specific information on
% FD/filtering parameters (see below for standard examples if this
% isn't provided


% read in the subject data including location, vcnum, and boldruns
df = readtable(datafile); %reads into a table structure, with datafile top row as labels
numdatas=size(df.sub,1); %number of datasets to analyses (subs X sessions)


%%% FD/filtering parameters (these will probably be constant within a study but potentially vary across studies)
if nargin == 1
    % if FD/filtering parameters are not provided, use these defaults
    %TR = 1.1; % read from data list
    contig_frames = 5; % Number of continuous samples w/o high FD necessary for inclusion
    %DropFramesSec = 30; % number of seconds of frames to drop at the start of each run
    headSize = 50; % assume 50 mm head radius
    FDthresh = 0.2;
    fFDthresh = 0.1;
    run_min = 50; % minimum number of frames in a run
    tot_min = 150; % minimum number of frames needed across all runs
elseif nargin > 2
    % assume varargin{1} = structure with each of the following fields
    %TR = varargin{1}.TR; %read from data list
    contig_frames = varargin{1}.contig_frames;
    %DropFramesSec = varargin{1}.DropFramesSec;
    %DropFramesTR = round(DropFramesSec/TR);
    headsize = varargin{1}.headsize;
    FDthresh = varargin{1}.FDthresh;
    fFDthresh = varargin{1}.fFDthresh;
    run_min = varargin{1}.run_min;
    tot_min = varargin{1}.tot_min;
else
    error('incorrect number of inputs');
end



% fmriprep relevant field names from confounds file
%   order in most sensible order you like
%   n.b: rotation parameters are in radians (from FSL mcflirt)
mvm_fields = {'trans_x','trans_y','trans_z','rot_x','rot_y','rot_z'};
rot_IDs = logical([0 0 0 1 1 1]);

for i = 1:numdatas

    %to account for subject numbers that are all numeric
    if isa(df.sub(i),'double')
        subject = num2str(df.sub(i));
    elseif isa(df.sub(i),'cell')
        subject = df.sub{i};
    else
        error('can not recognize subject data type')
    end

    % where is the data stored for this particular session
    inputdir = [df.topDir{i} '/' df.dataFolder{i} '/fmriprep/sub-' subject '/ses-' num2str(df.sess(i)) '/func/'];
    %inputdir = [projectdir 'ses-' num2str(ses) '/func/'];
    outputdir = [inputdir 'FD_outputs/'];
    if ~exist(outputdir)
        mkdir(outputdir);
    end

    % search for relevant motion files
    % infiles = dir([inputdir '*' input_filestr]);
    % loop through runs in datalist
    %runs = str2double(regexp(df.runs{i},',','split'))'; % get runs, converting to numerical array (other orientiation since that's what's expected

    %for r = 1:length(runs)

        % load motion data
        % assume fmriprep data organization
        %confounds = bids.util.tsvread([inputdir infiles(i).name]); %reads into a structure, each field = col in tsv
        %run_str = sprintf('sub-%s_ses-%d_task-%s_run-%02d',df.sub{i},df.sess(i),df.task{i},df.space{i});
        run_str = sprintf('sub-%s_ses-%d_task-%s_space-%d',subject,df.sess(i),df.task{i},df.space{i});
        confounds = bids.util.tsvread([inputdir run_str '_desc-confounds_timeseries.tsv']); %reads into a structure, each field = col in tsv

        % str for naming output (contains subject, task, and run info):
        %run_str = infiles(i).name(1:end-length(input_filestr));

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

        %% these lines might need changing throughout the code or txt files might not save appropriately
        %Here are two option: writematrix is more likely to work, but
        %adding -ascii, -double, and -tabs to the save command works for
        %some of these lines (not all). Change throughout the code!
        %writematrix(mot_data,sprintf('%s%smvm.txt',outputdir,outstr)); %only works in Matlab 2019, not 2018 on quest
        writetable(table(mot_data(:,1),mot_data(:,2),mot_data(:,3),mot_data(:,4),mot_data(:,5),mot_data(:,6),...
            'VariableNames',mvm_fields),sprintf('%s%s_desc-mvm.txt',outputdir,run_str));
        %save(sprintf('%s%smvm.txt',outputdir,outstr),'mot_data', '-ascii','-double','-tabs');
        %writematrix(mot_data_filtered,sprintf('%s%smvm_filt.txt',outputdir,outstr));
        writetable(table(mot_data_filtered(:,1),mot_data_filtered(:,2),mot_data_filtered(:,3),...
            mot_data_filtered(:,4),mot_data_filtered(:,5),mot_data_filtered(:,6),...
                'VariableNames',mvm_fields),sprintf('%s%s_desc-mvm_filt.txt',outputdir,run_str));
        %save(sprintf('%s%smvm_filt.txt',outputdir,outstr),'mot_data_filtered', '-ascii','-double','-tabs');

        % calculate FD pre and post filtering
        mot_data_diff = [zeros(1,6); diff(mot_data)];
        mot_data_filt_diff = [zeros(1,6); diff(mot_data_filtered)];
        FD = sum(abs(mot_data_diff),2);
        fFD = sum(abs(mot_data_filt_diff),2);
        %writematrix(FD,sprintf('%s%sFD.txt',outputdir,outstr));
        writetable(table(FD),sprintf('%s%s_desc-FD.txt',outputdir,run_str));
        %save(sprintf('%s%sFD.txt',outputdir,outstr),'FD', '-ascii','-double','-tabs');
        %writematrix(fFD,sprintf('%s%sfFD.txt',outputdir,outstr));
        writetable(table(fFD),sprintf('%s%s_desc-fFD.txt',outputdir,run_str));
        %save(sprintf('%s%sfFD.txt',outputdir,outstr),'fFD', '-ascii','-double','-tabs');

        % plot original parameters & FD
        plot_motion_params(mot_data,FD,FDthresh,mvm_fields);
        print(gcf,sprintf('%s%s_desc-motion_parameters.pdf',outputdir,run_str),'-dpdf','-bestfit');
        plot_motion_params(mot_data_filtered,fFD,fFDthresh,mvm_fields);
        print(gcf,sprintf('%s%s_desc-motion_parameters_filtered.pdf',outputdir,run_str),'-dpdf','-bestfit');

        % make some plots - FFT
        mot_FFT(mot_data,df.TR(i),1);
        print(gcf,sprintf('%s%s_desc-motion_FFT.pdf',outputdir,run_str),'-dpdf','-bestfit');
        mot_FFT(mot_data_filtered,df.TR(i),1);
        print(gcf,sprintf('%s%s_desc-motion_filtered_FFT.pdf',outputdir,run_str),'-dpdf','-bestfit');

        % make a tmask for each run
        DropFramesTR = df.dropFr(i); %round(DropFramesSec/df.TR(i)); % Calculate num TRs to drop
        tmask_FD = make_tmask(FD,FDthresh,DropFramesTR,contig_frames);
        tmask_fFD = make_tmask(fFD,fFDthresh,DropFramesTR,contig_frames);
        %writematrix(tmask_FD,sprintf('%s%stmask_FD.txt',outputdir,outstr));
        writetable(table(tmask_FD),sprintf('%s%s_desc-tmask_FD.txt',outputdir,run_str));
        %save(sprintf('%s%stmask_FD.txt',outputdir,outstr),'tmask_FD', '-ascii','-double','-tabs');
        %writematrix(tmask_fFD,sprintf('%s%stmask_fFD.txt',outputdir,outstr));
        writetable(table(tmask_fFD),sprintf('%s%s_desc-tmask_fFD.txt',outputdir,run_str));
        %save(sprintf('%s%stmask_fFD.txt',outputdir,outstr),'tmask_fFD', '-ascii','-double','-tabs');

        % some stats to keep track of
        good_run_FD(r) = sum(tmask_FD) > run_min;
        good_run_fFD(r) = sum(tmask_fFD) > run_min;
        run_frame_nums_FD(r) = sum(tmask_FD);
        run_frame_nums_fFD(r) = sum(tmask_fFD);
        run_frame_per_FD(r) = sum(tmask_FD)./numel(tmask_FD);
        run_frame_per_fFD(r) = sum(tmask_fFD)./numel(tmask_fFD);

        close('all');
        clear mot_data;
    %end

    % save out some general info
    %writematrix(good_run_FD,sprintf('%sgoodruns_FD.txt',outputdir));
    writetable(table(good_run_FD'),sprintf('%s/sub-%s_ses-%d_task-%s_desc-goodruns_FD.txt',outputdir,subject,df.sess(i),df.task{i}));
    %save(sprintf('%sgoodruns_FD.txt',outputdir),'good_run_FD', '-ascii', '-double', '-tabs');
    %writematrix(good_run_fFD, sprintf('%sgoodruns_fFD.txt',outputdir));
    writetable(table(good_run_fFD'), sprintf('%s/sub-%s_ses-%d_task-%s_desc-goodruns_fFD.txt',outputdir,subject,df.sess(i),df.task{i}));
    %save(sprintf('%sgoodruns_fFD.txt',outputdir),'good_run_fFD', '-ascii','-double','-tabs');

    %writematrix(run_frame_nums_FD,sprintf('%sframenums_FD.txt',outputdir));
    writetable(table(run_frame_nums_FD'),sprintf('%s/sub-%s_ses-%d_task-%s_desc-framenums_FD.txt',outputdir,subject,df.sess(i),df.task{i}));
    %save(sprintf('%sframenums_FD.txt',outputdir),'run_frame_nums_FD', '-ascii','-double','-tabs');
    %writematrix(run_frame_nums_fFD,sprintf('%sframenums_fFD.txt',outputdir));
    writetable(table(run_frame_nums_fFD'),sprintf('%s/sub-%s_ses-%d_task-%s_desc-framenums_fFD.txt',outputdir,subject,df.sess(i),df.task{i}));
    %save(sprintf('%sframenums_fFD.txt',outputdir),'run_frame_nums_fFD', '-ascii','-double','-tabs');

    %writematrix(run_frame_per_FD,sprintf('%sframepers_FD.txt',outputdir));
    writetable(table(run_frame_per_FD'),sprintf('%s/sub-%s_ses-%d_task-%s_desc-framepers_FD.txt',outputdir,subject,df.sess(i),df.task{i}));
    %save(sprintf('%sframepers_FD.txt',outputdir),'run_frame_per_FD', '-ascii', '-double', '-tabs');
    %writematrix(run_frame_per_fFD,sprintf('%sframepers_fFD.txt',outputdir));
    writetable(table(run_frame_per_fFD'),sprintf('%s/sub-%s_ses-%d_task-%s_desc-framepers_fFD.txt',outputdir,subject,df.sess(i),df.task{i}));
    %save(sprintf('%sframepers_fFD.txt',outputdir),'run_frame_per_fFD', '-ascii','-double','-tabs');

    clear good_run_FD run_frame_nums_FD run_frame_per_FD;
    clear good_run_fFD run_frame_nums_fFD run_frame_per_fFD;
end

end

function plot_motion_params(mot_data,FD,FDthresh,param_names)
figure('Position',[1 1 800 1000]);

subplot(2,3,1:3)
title('motion')
plot(mot_data);
%legend('Roll', 'Pitch', 'Yaw', 'Z', 'X', 'Y');
legend(param_names);
xlim([1,size(mot_data,1)]);
xlabel('TR');
ylabel('mm');

subplot(2,3,4:6);
title('FD');
plot(FD);
hline_new(FDthresh,'k',1);
xlim([1,length(FD)]);
xlabel('TR');
ylabel('mm');

end
