clear;
clc;
close all;
format shortG;
folder1='C:\Local Matlab Data\3.1GHz';
cd(folder1)
pause(0.1)


tiremSetup('C:\USGS\TIREM5')
freq = 28e9;
r = 0:100:10000;
z = zeros(1,numel(r));
[tirem_pl,tirem_info]=tirempl(r,z,freq,'TransmitterAntennaHeight',5,'ReceiverAntennaHeight',5)

tirem_pl
pathloss_answer=142.6089

