

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function QC = tempimgsignals(QC,i,tempimg,switches,stage)

difftempimg=diff(tempimg')';
difftempimg=[zeros(size(difftempimg,1),1) difftempimg];

QC(i).MEAN_CSF(:,stage)=mean(tempimg(QC(i).CSFMASK_glmmask,:))';
QC(i).MEAN_WM(:,stage)=mean(tempimg(QC(i).WMMASK_glmmask,:))';
QC(i).MEAN_GLM(:,stage)=mean(tempimg(QC(i).GLMMASK_glmmask,:))';

QC(i).SD_CSF(:,stage)=std(tempimg(QC(i).CSFMASK_glmmask,:))';
QC(i).SD_WM(:,stage)=std(tempimg(QC(i).WMMASK_glmmask,:))';
QC(i).SD_GLM(:,stage)=std(tempimg(QC(i).GLMMASK_glmmask,:))';

QC(i).SDbar_CSF(:,stage)=mean(QC(i).SD_CSF(:,stage));
QC(i).SDbar_WM(:,stage)=mean(QC(i).SD_WM(:,stage));
QC(i).SDbar_GLM(:,stage)=mean(QC(i).SD_GLM(:,stage));

[jnk tempDV]=array_calc_rms(difftempimg(QC(i).CSFMASK_glmmask,:));
tempDV(QC(i).runborders(:,2))=NaN;
QC(i).DV_CSF(:,stage)=tempDV';
[jnk tempDV]=array_calc_rms(difftempimg(QC(i).WMMASK_glmmask,:));
tempDV(QC(i).runborders(:,2))=NaN;
QC(i).DV_WM(:,stage)=tempDV';
[jnk tempDV]=array_calc_rms(difftempimg(QC(i).GLMMASK_glmmask,:));
tempDV(QC(i).runborders(:,2))=NaN;
QC(i).DV_GLM(:,stage)=tempDV';

QC(i).DVbar_CSF(stage)=nanmean(QC(i).DV_CSF(:,stage));
QC(i).DVbar_WM(stage)=nanmean(QC(i).DV_WM(:,stage));
QC(i).DVbar_GLM(stage)=nanmean(QC(i).DV_GLM(:,stage));

if switches.regressiontype==1 | switches.regressiontype==9
    QC(i).MEAN_GM(:,stage)=mean(tempimg(QC(i).GMMASK_glmmask,:))';
    QC(i).MEAN_WB(:,stage)=mean(tempimg(QC(i).WBMASK_glmmask,:))';
    
    QC(i).SD_GM(:,stage)=std(tempimg(QC(i).GMMASK_glmmask,:))';
    QC(i).SD_WB(:,stage)=std(tempimg(QC(i).WBMASK_glmmask,:))';
    
    QC(i).SDbar_GM(:,stage)=mean(QC(i).SD_GM(:,stage));
    QC(i).SDbar_WB(:,stage)=mean(QC(i).SD_WB(:,stage));
    
    [jnk tempDV]=array_calc_rms(difftempimg(QC(i).GMMASK_glmmask,:));
    tempDV(QC(i).runborders(:,2))=NaN;
    QC(i).DV_GM(:,stage)=tempDV';
    [jnk tempDV]=array_calc_rms(difftempimg(QC(i).WBMASK_glmmask,:));
    tempDV(QC(i).runborders(:,2))=NaN;
    QC(i).DV_WB(:,stage)=tempDV';
    
    QC(i).DVbar_GM(stage)=nanmean(QC(i).DV_GM(:,stage));
    QC(i).DVbar_WB(stage)=nanmean(QC(i).DV_WB(:,stage));
end