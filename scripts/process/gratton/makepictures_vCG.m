
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function makepictures_vCG(QC,stage,rightsignallim,leftsignallim,FDmult)

% FOR TESTING:
%set(0, 'DefaultFigureVisible', 'off');

% constants
numpts=numel(QC.FD);
%rightsignallim = [-20:20]; %GS limits (2% assuming mode 1000 normalization)
%lefsignallim = [0:20:10]; % DVARS limits
rylimz=[min(rightsignallim) max(rightsignallim)];
lylimz=[min(leftsignallim) max(leftsignallim)];
%FDmult = 10; %multiplier to get FD in range of DVARS values

figure('Position',[1 1 1700 1200],'Visible','Off');

% subplot1 = mvm
subplot(10,1,1:2);
pointindex=1:numpts;
plot(pointindex,QC.MVM);
xlim([0 numpts]);
ylim([-1 1]);
ylabel('mvm');

% subplot2 = GS
subplot(10,1,3)
%[h a(1) a(2)]=plotyy(pointindex,QC.DV_GLM(:,stage),pointindex,QC.MEAN_GLM(:,stage));
%[h a(1) a(2)]=plotyy(pointindex,QC.dvars,pointindex,QC.global_signal);
%set(h(1),'xlim',[0 numpts],'ylim',lylimz,'ycolor',[0 0 0],'ytick',leftsignallim);
%ylabel(sprintf('B:DV G:GS R:FD*%d C:fFD*%d',FDmult,FDmult));
%set(a(1),'color',[0 0 1]);
%set(h(2),'xlim',[0 numpts],'ycolor',[0 0 0],'xlim',[0 numel(QC.dvars)],'ylim',rylimz,'ytick',rightsignallim);
%set(a(2),'color',[0 .5 0]);
%axis(h(1)); hold on;
plot(pointindex,QC.global_signal,'g');
hline(0,'k');
xlim([0 numpts]);
ylim(rylimz);
ylabel('G:GS');

% subplot3 = FD
subplot(10,1,4:5)
plot([1:numpts],QC.FD,'Color',[1 0.8 0.8],'LineWidth',0.1); hold on;
plot([1:numpts],QC.fFD,'r','LineWidth',1.5);
hline(0.1,'k');
xlim([0 numpts]);
ylim([0 1])
ylabel('mm, R:fFD, M=FD');
% hold(h(2),'off');
% set(h(1),'children',[a(1) h3 h4]);
% set(h(1),'YaxisLocation','left','box','off');
% set(h(2),'xaxislocation','top','xticklabel','');

% subplots 3-4: 
subplot(10,1,6:9);
imagesc(QC.GMtcs(:,:,stage),rylimz); colormap(gray); ylabel('GRAY');
subplot(10,1,10);
imagesc([QC.WMtcs(:,:,stage);QC.CSFtcs(:,:,stage)],rylimz); ylabel('WM CSF');

