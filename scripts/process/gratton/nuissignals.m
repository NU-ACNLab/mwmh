
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function QC = nuissignals(QC,i,tboldconf)
% CG - added in to draw confound signals from fmriprep output

% relevant confounds to carry forward:
conf_names = {'csf','csf_derivative1','csf_power2','csf_derivative1_power2',...
    'white_matter','white_matter_derivative1','white_matter_power2','white_matter_derivative1_power2',...
    'global_signal','global_signal_derivative1','global_signal_power2','global_signal_derivative1_power2',...
    'std_dvars','dvars'};

%prep structure with empty arrays
for cn = 1:length(conf_names)
    QC(i).(conf_names{cn}) = [];
end

% load confounds signals from fmriprep
confounds = bids.util.tsvread(tboldconf);
for cn = 1:length(conf_names)
    temp_confounds=demean_detrend(confounds.(conf_names{cn})');           
    QC(i).(conf_names{cn}) = [QC(i).(conf_names{cn}); temp_confounds'];
end

