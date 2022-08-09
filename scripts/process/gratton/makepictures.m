
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function makepictures(QC,stage,switches,rightsignallim,leftsignallim,FDmult)

% FOR TESTING:
% set(0, 'DefaultFigureVisible', 'on');

rylimz=[min(rightsignallim) max(rightsignallim)];
lylimz=[min(leftsignallim) max(leftsignallim)];

numpts=numel(QC.FD);
clf;
subplot(8,1,1:2);
pointindex=1:numpts;
%[h a(1) a(2)]=plotyy(pointindex,QC.DV_GLM(:,stage),pointindex,QC.MEAN_GLM(:,stage));
[h a(1) a(2)]=plotyy(pointindex,QC.dvars,pointindex,QC.global_signal);
set(h(1),'xlim',[0 numpts],'ylim',lylimz,'ycolor',[0 0 0],'ytick',leftsignallim);
ylabel('B:DV G:GS');
set(a(1),'color',[0 0 1]);
set(h(2),'xlim',[0 numpts],'ycolor',[0 0 0],'xlim',[0 numel(QC.dvars)],'ylim',rylimz,'ytick',rightsignallim);
set(a(2),'color',[0 .5 0]);
axis(h(1)); hold on;
h3=plot([1:numpts],QC.FD*FDmult,'r');
h4=plot([1:numpts],QC.fFD*FDmult,'Color',[0.8 0 0]);
hold off;
axes(h(2)); hold(h(2),'on');
hline(0,'k');
hold(h(2),'off');
set(h(1),'children',[a(1) h3 h4]);
set(h(1),'YaxisLocation','left','box','off');
set(h(2),'xaxislocation','top','xticklabel','');
if switches.regressiontype==1 | switches.regressiontype==9
    subplot(8,1,3);
    imagesc(QC.MVM',[-.5 .5]);
    ylabel('XYZPYR');
    subplot(8,1,4:7);
    imagesc(QC.GMtcs(:,:,stage),rylimz); colormap(gray); ylabel('GRAY');
    subplot(8,1,8);
    imagesc([QC.WMtcs(:,:,stage);QC.CSFtcs(:,:,stage)],rylimz); ylabel('WM CSF');
end

