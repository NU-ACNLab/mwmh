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
    yline(FDthresh,'k',FDthresh);
    xlim([1,length(FD)]);
    xlabel('TR');
    ylabel('mm');
end