% Create animation in gif
clear, clc, close all
LatexPlots

% 
filesdir = 'C:\Users\Miguel.MIGUEL-DESK\Documents\PhD Files\TSI_Runs\Runs_OB';
filename = '\OB_1_08_2_1_1.mat';

load(strcat(filesdir, filename))

AnimateEarthquake