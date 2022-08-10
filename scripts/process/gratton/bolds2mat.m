
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fcimg]=bolds2mat(bolds,trtot,trborders,GLMmask,WBmask_sub)

vox = nnz(GLMmask);
%vox=902629;%147456;
fcimg=zeros(vox,trtot);
if size(bolds, 1) > 1
    for j=1:size(bolds,1) %NOTE: was size(bolds, 2), but I am not sure why the length of the string would have ever mattered
        temp = load_nii_wrapper([bolds{j} '.nii.gz']);
    
        temp1000 = mode1000norm(temp,WBmask_sub); % use the more sub specific mask for this
       
        fcimg(:,trborders(j,1):trborders(j,2))=temp1000(logical(GLMmask),:);
        clear temp temp1000;
    end
else
    temp = load_nii_wrapper([bolds '.nii.gz']);
    temp1000 = mode1000norm(temp,WBmask_sub); % use the more sub specific mask for this
    fcimg(:,trborders(1):trborders(2))=temp1000(logical(GLMmask),:); %NOTE: Getting
    clear temp temp1000;
end
