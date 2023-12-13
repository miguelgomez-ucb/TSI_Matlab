% Derailment Spectra
clear, clc, close all

freqvals = 0.1:0.05:5.0;
sfvals   = 0.1:0.05:5.0;

derail_matrix = nan * zeros(length(freqvals), length(sfvals));
PeakDCarBody  = nan * zeros(length(freqvals), length(sfvals));
PeakDWheelSet = nan * zeros(length(freqvals), length(sfvals));
PeakRCarBody  = nan * zeros(length(freqvals), length(sfvals));
PeakRWheelSet = nan * zeros(length(freqvals), length(sfvals));
PeakRotUplift = nan * zeros(length(freqvals), length(sfvals));


freq_index = 0;
for freq = freqvals
    freq_index = freq_index + 1;
    sf_index = 0;
    for sf = sfvals
        sf_index = sf_index + 1;
        folder = "C:\Users\Miguel Gomez\Documents\PhD Files\TSI_Runs\Pulses_AG\";
        filename = strcat("Pulse_AG_SF", num2str(100*freq, "%03.0f"), "_FQ", num2str(100*sf, "%03.0f"), ".mat");
        address = strcat(folder, filename);
        
        load(address, 'dr_type', 'BridgeResponse', 'X')

        for it = 2:size(BridgeResponse.X_Track, 2)
            rotation = abs(X(9, it - 1) + BridgeResponse.X(3, it - 1) - ...
                    (BridgeResponse.X(8, it - 1) - BridgeResponse.X(5, it - 1))/1.2);

            if (abs(X(7, it - 1) - BridgeResponse.X_Track(1, it - 1)) > 0.1 && rotation < pi/30)
                dr_type = 1;   % Derailment in slide-off mode
                disp("Slide-off Derailment")
                break
            elseif (abs(X(7, it - 1) - BridgeResponse.X_Track(1, it - 1)) > 1.0 && rotation < pi/2)
                dr_type = 2;
                disp("Combined Derailment")
                break           % Derailment in combined mode
            elseif rotation > pi/2
                dr_type = 3;   % Derailment in overturning mode
                disp("Overturning Derailment")
                break
            else 
                %dr_type = 0;
            end
        end
        firstDerail = it;

        % Store responses of interest
        PeakDCarBody(freq_index, sf_index)   = max(abs(X(1,1:firstDerail) - BridgeResponse.X_Track(1,1:firstDerail)));
        PeakDWheelSet(freq_index, sf_index)  = max(abs(X(7,1:firstDerail) - BridgeResponse.X_Track(1,1:firstDerail)));
        PeakRCarBody(freq_index, sf_index)   = max(abs(X(3,1:firstDerail) + BridgeResponse.X(3,1:firstDerail)));
        PeakRWheelSet(freq_index, sf_index)  = max(abs(X(9,1:firstDerail) + BridgeResponse.X(3,1:firstDerail)));

        
        PeakRotUplift(freq_index, sf_index)  = max(abs(X(9, 1:firstDerail) + BridgeResponse.X(3, 1:firstDerail) + ...
            - (BridgeResponse.X(8, 1:firstDerail) - BridgeResponse.X(5, 1:firstDerail))/1.2));


        derail_matrix(freq_index, sf_index) = dr_type;
    end
end

save derail_AG
%%
clear, clc, close all

freqvals = 0.1:0.05:5.0;
sfvals   = 0.1:0.05:5.0;

derail_matrix = nan * zeros(length(freqvals), length(sfvals));
PeakDCarBody  = nan * zeros(length(freqvals), length(sfvals));
PeakDWheelSet = nan * zeros(length(freqvals), length(sfvals));
PeakRCarBody  = nan * zeros(length(freqvals), length(sfvals));
PeakRWheelSet = nan * zeros(length(freqvals), length(sfvals));
PeakRotUplift = nan * zeros(length(freqvals), length(sfvals));


freq_index = 0;
for freq = freqvals
    freq_index = freq_index + 1;
    sf_index = 0;
    for sf = sfvals
        sf_index = sf_index + 1;
        folder = "C:\Users\Miguel Gomez\Documents\PhD Files\TSI_Runs\Pulses_OB\";
        filename = strcat("Pulse_OB_SF", num2str(100*freq, "%03.0f"), "_FQ", num2str(100*sf, "%03.0f"), ".mat");
        address = strcat(folder, filename);
        
        load(address, 'dr_type', 'BridgeResponse', 'X')
        
        for it = 2:size(BridgeResponse.X_Track, 2)
            rotation = abs(X(9, it - 1) + BridgeResponse.X(3, it - 1) - ...
                    (BridgeResponse.X(8, it - 1) - BridgeResponse.X(5, it - 1))/1.2);

            if (abs(X(7, it - 1) - BridgeResponse.X_Track(1, it - 1)) > 0.1 && rotation < pi/30)
                dr_type = 1;   % Derailment in slide-off mode
                disp("Slide-off Derailment")
                break
            elseif (abs(X(7, it - 1) - BridgeResponse.X_Track(1, it - 1)) > 1.0 && rotation < pi/2)
                dr_type = 2;
                disp("Combined Derailment")
                break           % Derailment in combined mode
            elseif rotation > pi/2
                dr_type = 3;   % Derailment in overturning mode
                disp("Overturning Derailment")
                break
            else 
                %dr_type = 0;
            end
        end

        firstDerail = it;
        
        % Store responses of interest
        PeakDCarBody(freq_index, sf_index)   = max(abs(X(1,1:firstDerail) - BridgeResponse.X_Track(1,1:firstDerail)));
        PeakDWheelSet(freq_index, sf_index)  = max(abs(X(7,1:firstDerail) - BridgeResponse.X_Track(1,1:firstDerail)));
        PeakRCarBody(freq_index, sf_index)   = max(abs(X(3,1:firstDerail) + BridgeResponse.X(3,1:firstDerail)));
        PeakRWheelSet(freq_index, sf_index)  = max(abs(X(9,1:firstDerail) + BridgeResponse.X(3,1:firstDerail)));

        
        PeakRotUplift(freq_index, sf_index)  = max(abs(X(9, 1:firstDerail) + BridgeResponse.X(3, 1:firstDerail) + ...
            - (BridgeResponse.X(8, 1:firstDerail) - BridgeResponse.X(5, 1:firstDerail))/1.2));


        derail_matrix(freq_index, sf_index) = dr_type;
    end
end

save derail_OB

%% Derailment Mode
clear

load derail_AG.mat
LatexPlots
[X, Y] = meshgrid(freqvals, sfvals);
figure(1)
[~, hCont] = contourf(X, Y, derail_matrix, 3, 'LineStyle',':'); shading interp, xlabel('Frequency $f_M$ (Hz)'), ylabel('Amplitude (g)'), grid on
xlim([0.1 2.0]), ylim([0.1 5.0])%, clim([0 0.1])
axis square
contourLegend(hCont, ["No Derailment", "Slide-Off", "Combined", "Overturning"], 'southeast')
saveas(gcf, "Derail_Mode_AtGrade.pdf")


load derail_OB.mat
LatexPlots
figure(2)
[X, Y] = meshgrid(freqvals, sfvals);
[~, hCont] = contourf(X, Y, derail_matrix, 3, 'LineStyle',':'); shading interp, xlabel('Frequency $f_M$ (Hz)'), ylabel('Amplitude (g)'), grid on
xlim([0.1 2.0]), ylim([0.1 5.0])%, clim([0 0.1])
axis square
contourLegend(hCont, ["No Derailment", "Slide-Off", "Combined", "Overturning"], 'southeast')
saveas(gcf, "Derail_Mode_OnBridge.pdf")

%%
clear all
close all
clc

load derail_AG.mat
[X, Y] = meshgrid(freqvals, sfvals);
figure()
contourf(X, Y, PeakDCarBody, 100, 'LineStyle','none'), shading interp, xlabel('Frequency $f_M$ (Hz)'), ylabel('Amplitude (g)'), grid on
xlim([0.1 4.0]), clim([0.0 1.0]), axis square
title('Peak Car Displacement (m)')
colormap(parula(100))
colorbar


load derail_OB.mat
LatexPlots
figure()
[X, Y] = meshgrid(freqvals, sfvals);
contourf(X, Y, PeakDCarBody, 100, 'LineStyle','none'), shading interp, xlabel('Frequency $f_M$ (Hz)'), ylabel('Amplitude (g)'), grid on
xlim([0.1 4.0]), clim([0.0 1.0]), axis square
title('Peak Car Displacement (m)')
colormap(parula(100))
colorbar

%%

load derail_AG.mat
[X, Y] = meshgrid(freqvals, sfvals);
figure()
contourf(X, Y, PeakDWheelSet, 100, 'LineStyle','none'), shading interp, xlabel('Frequency $f_M$ (Hz)'), ylabel('Amplitude (g)'), grid on
xlim([0.1 4.0]), clim([0.0 0.5]), axis square
title('Peak Wheel Displacement (m) - At Grade')
colormap(parula(100))
colorbar


load derail_OB.mat
LatexPlots
figure()
[X, Y] = meshgrid(freqvals, sfvals);
contourf(X, Y, PeakDWheelSet, 100, 'LineStyle','none'), shading interp, xlabel('Frequency $f_M$ (Hz)'), ylabel('Amplitude (g)'), grid on
xlim([0.1 4.0]), clim([0.0 0.5]), axis square
title('Peak Wheel Displacement (m) - Over Bridge')
colormap(parula(100))
colorbar

%load(address, 'dr_type', 'BridgeResponse', 'X')
% plot(abs(X(9, 1:firstDerail) + BridgeResponse.X(3, 1:firstDerail) + ...
%             - (BridgeResponse.X(8, 1:firstDerail) - BridgeResponse.X(5, 1:firstDerail))/1.2))

%%
[X, Y, Z]  = peaks(512);

figure
[~, hCont] = contourf(X, Y, Z, 3);
contourLegend(hCont, ["A", "B", "V", "D"])
