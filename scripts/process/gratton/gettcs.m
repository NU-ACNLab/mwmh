
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tc] = gettcs(roimasks,tempimg)

d=size(roimasks);
for i=1:d(2) % cycle all masks
    tc(:,i)=(mean(tempimg(logical(roimasks(:,i)),:)))';
end