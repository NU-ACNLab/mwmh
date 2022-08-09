function [bolds]=conc2bolds(concfile)

system(['cat ' concfile ' | grep file: | awk -F: ''{print $2}'' >! tmpAB']);
[bolds]=textread('tmpAB','%s');
system('rm tmpAB');