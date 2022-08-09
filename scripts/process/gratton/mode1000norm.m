%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function bolddat1000 = mode1000norm(bolddat,bmask)

bolddat_masked = double(bolddat(bmask,:));
bolddat_masked = bolddat_masked(bolddat_masked > 0); %note: EMG code had an additional mask > 100 applied. Took out since didn't seem needed?
[counts,edges] = histcounts(bolddat_masked,1000);
[~,maxind] = max(counts);
%modeval = mean([edges(maxind) edges(maxind+1)]);
upper_75 = prctile(bolddat_masked, 75);%upper_75 = edges(maxind+250); %since 1000 bins  %
lower_25 = prctile(bolddat_masked, 25); %lower_25 = edges(maxind-250); %%

% add a range normalization step for NU to make it look more like MSC
bolddat_norm = (bolddat - lower_25)/(upper_75 - lower_25) .* 200; %MSC range seemed ~between 900 and 1200

% recalculate mode after normalization
bolddat_norm_masked = double(bolddat_norm(bmask,:));
bolddat_norm_masked = bolddat_norm_masked(bolddat_masked > 0); % use original mask for 0s
[counts,edges] = histcounts(bolddat_norm_masked,1000);
[~,maxind] = max(counts);
modeval = mean([edges(maxind) edges(maxind+1)]);

% change bold data to have mode 1000
bolddat1000 = bolddat_norm + (1000 - modeval);
