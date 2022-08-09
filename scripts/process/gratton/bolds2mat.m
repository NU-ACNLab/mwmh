
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fcimg]=bolds2mat(bolds,trtot,trborders,GLMmask,WBmask_sub)

vox = nnz(GLMmask);
%vox=902629;%147456;
fcimg=zeros(vox,trtot);
for j=1:size(bolds,2)
    temp = load_nii_wrapper([bolds{j} '.nii.gz']);
    %temp = read_4dfpimg_HCP(bolds{j,1});
    %    fcimg(:,trborders(j,1):trborders(j,2))=read_4dfpimg_HCP(bolds{j,1});
    
    %CG added, based on BK code, based on EMG code
    temp1000 = mode1000norm(temp,WBmask_sub); % use the more sub specific mask for this
   
    fcimg(:,trborders(j,1):trborders(j,2))=temp1000(logical(GLMmask),:);
    clear temp temp1000;
end
