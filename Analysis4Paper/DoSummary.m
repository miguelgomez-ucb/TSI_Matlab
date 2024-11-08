%% Create data matrix for analysis
clear, clc, close all

analysis_type = 'OB';  % Here select [OB: over bridge | AG: at grade]

% Names and information of all runs
TheFiles = dir(strcat('C:\Users\Miguel.MIGUEL-DESK\Documents\PhD Files\TSI_Runs\Runs_', analysis_type, '\*.mat'));

SummMatrix = zeros(length(TheFiles), 21);
doPlots = false;

%% Load each run file and extract relevant information

for File = 1:length(SummMatrix)
    % Load DataSet
    [DataSet] = LoadData(strcat(TheFiles(File).folder,'\' ,TheFiles(File).name));
    
    % Get ground motion ID
    groundmotion = str2double(TheFiles(File).name(6:7));
    
    % Relative wheelset/track displacement
    RelDispl = 100 / 2.54 * (DataSet.TrainResponse.X(7, :) + ...
        - DataSet.BridgeResponse.X_Track(1, :)); % inches
    
    % Rotation of the track
    TrackRotation = (DataSet.BridgeResponse.X(3,:) + ...
        + (-DataSet.BridgeResponse.X(8,:) + ...
        + DataSet.BridgeResponse.X(5,:)) / 1.7742);
    
    % Relative rotation track/wheelset
    RelRotation = rad2deg(abs(-DataSet.TrainResponse.X(9, :) - TrackRotation));
    
    % If wanted, create plots
    if doPlots
        figure()
        plot(TrackRotation)
        hold on
        plot(-DataSet.TrainResponse.X(9,:), ':')
    
        figure()
        plot(RelRotation)
    
        figure()
        plot(DataSet.TrainResponse.X(7, :))
        hold on
        plot(DataSet.BridgeResponse.X_Track(1, :))
    
        figure()
        plot(abs(RelDispl))
    end

    % Check for derailment (if relative displacement at the end of the
    % analysis is large, then identify derailment).
    if or(abs(RelDispl(end)) >= 10, max(abs(RelRotation)) > 30)
        DRCase = 1;
    else
        DRCase = 0;
    end
    
    % Now, check for derailment type and find derailment instant
    climb_strt = find(abs(RelDispl) > 1.0, 1);     % start climbing instant
    climb_full = find(abs(RelDispl) > 3.0, 1);     % Full climbing instant
    overt_full = find(abs(RelRotation) > 30, 1); % Overturning instant
    
    if DRCase == 1
        if ~isempty(overt_full) && abs(DataSet.NormalForce(overt_full)) > 0
            disp('Overturning Derail')
            firstDerail = overt_full;
            drType = 3;

        elseif ~isempty(climb_full) && abs(RelRotation(climb_full)) < 3.0
            disp('Sliding Derail')
            firstDerail = climb_full;
            drType = 1;
            
        else
            disp('Combined Derail')
            firstDerail = max(find(DataSet.NormalForce(50:end)==0, 50));
            drType = 2;

        end
    else
        disp('No derailment')
        firstDerail = length(RelDispl);
        drType = 0;
    end

    % Get max response of bridge (for the whole analysis)
    PeakDBridge = max(abs(DataSet.BridgeResponse.X(1,1:end)));
    PeakVBridge = max(abs(DataSet.BridgeResponse.Xtdot(1,1:end)));
    PeakABridge = max(abs(DataSet.BridgeResponse.Xddot(1,1:end) + DataSet.ugddot));
    PeakRBridge = max(abs(DataSet.BridgeResponse.X(2,1:end)));
    
    % Get max response of train (until derailment)
    PeakDCarBody = max(abs(DataSet.TrainResponse.X(1,1:firstDerail)));
    PeakDWheelSet = max(abs(DataSet.TrainResponse.X(7,1:firstDerail)));
    PeakRCarBody = max(abs(DataSet.TrainResponse.X(3,1:firstDerail)));
    PeakRWheelSet = max(abs(DataSet.TrainResponse.X(9,1:firstDerail)));
    
    % Get peak relative rotation between wheelset and track
    PeakRotUplift = max(abs(RelRotation(1:firstDerail)));    % Degrees

    % Get peak response of train
    PeakAhCarBody = max(abs(DataSet.TrainResponse.A(1,1:firstDerail)));
    PeakAvCarBody = max(abs(DataSet.TrainResponse.A(2,1:firstDerail)));
    
    % Ground Motion parameters
    PGA = max(abs(DataSet.ugddot));
    PGV = max(abs(DataSet.ugdot));
    
    % Store Variables
    SummMatrix(File,:) = [...
        DataSet.HL, DataSet.CF, DataSet.Vel, DataSet.BM, PGA, PGV,...
        PeakDBridge, PeakVBridge, PeakABridge, PeakRBridge,...
        PeakDCarBody, PeakDWheelSet, PeakRCarBody, PeakRWheelSet,...
        PeakRotUplift, PeakAhCarBody, PeakAvCarBody,...
        abs(PeakDBridge - PeakDWheelSet), DRCase, groundmotion, drType];
    
    clear DataSet

end

SummTable = array2table(SummMatrix,...
    'VariableNames', ...
    {'hazlvl', 'cf', 'spd', 'bridgemodel', 'pga', 'pgv', ...
    'pbd', 'pbv', 'pba', 'pbrot', ... 
    'pcd', 'pwd', 'pcrot', 'pwrot', ...
    'purot', 'pcha', 'pcva', 'drdis', 'drcase', 'gm', 'drtype'});

save("SummTable", "SummTable")

%% Functions

function [Data] = LoadData(FileName)
    % This function loads analysis and extracts required data
    load(FileName, 'BridgeResponse', 'X', 'V', 'A', 'HL', 'Vel', ...
        'ugddot', 'ugdot', 'NL', 'CF', 'Left_Cont', 'Right_Cont');
    
    Data.HL = HL;
    Data.ugddot = ugddot;
    Data.ugdot = ugdot;
    Data.BM = NL;
    Data.BridgeResponse = BridgeResponse;
    Data.Vel = Vel;
    Data.TrainResponse.X = X;
    Data.TrainResponse.V = V;
    Data.TrainResponse.A = A;
    Data.CF = CF;
    Data.NormalForce = Left_Cont + Right_Cont;

end

