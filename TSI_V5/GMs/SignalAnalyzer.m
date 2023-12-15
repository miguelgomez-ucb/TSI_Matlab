%% Calculate and plot response spectra for all ground motions
clear, clc, close

% Some "pretty format"
set(0, 'defaultAxesTickLabelInterpreter','latex'); 
set(0, 'defaultLegendInterpreter','latex');
set(0, 'defaultTextInterpreter','latex');

filenames = dir('UsedRecords\*.mat');
load ScaleFactors
nfiles = length(filenames);

% Define target Sa
target_Sa_2 = [0.01	0.8351502;
              0.02	0.8415578;
              0.03	0.8899661;
              0.05	1.0253983;
              0.075	1.1567274;
              0.1	1.2910749;
              0.15	1.4669493;
              0.2	1.6384015;
              0.25	1.7362287;
              0.3	1.7989815;
              0.4	1.9308171;
              0.5	2.044395;
              0.75	1.8749135;
              1.0	1.5991317;
              1.5	1.2028565;
              2.0	0.93904835;
              3.0	0.60953563;
              4.0	0.4486016;
              5.0	0.3994327;
              7.5	0.2465115;
              10.0	0.18775517];

target_Sa_5 = [0.01	0.65648425;
               0.02	0.66155946;
               0.03	0.6964652;
               0.05	0.8006107;
               0.075	0.90139717;
               0.1	1.0147475;
               0.15	1.1617389;
               0.2	1.2930827;
               0.25	1.3567336;
               0.3	1.395245;
               0.4	1.4671646;
               0.5	1.5342652;
               0.75	1.3752311;
               1.0	1.1601164;
               1.5	0.867368;
               2.0	0.67576236;
               3.0	0.43804458;
               4.0	0.32429543;
               5.0	0.28109902;
               7.5	0.1713583;
               10.0	0.1278004];

target_Sa_10 = [ 0.01	0.5175917;
                 0.02	0.52168804;
                 0.03	0.5475836;
                 0.05	0.6293521;
                 0.075	0.7145896;
                 0.1	0.8123675;
                 0.15	0.9407496;
                 0.2	1.0393262;
                 0.25	1.078912;
                 0.3	1.1007546;
                 0.4	1.1298076;
                 0.5	1.1592213;
                 0.75	1.0218259;
                 1.0	0.8536943;
                 1.5	0.637292;
                 2.0	0.49499223;
                 3.0	0.32134452;
                 4.0	0.2369936;
                 5.0	0.20306984;
                 7.5	0.1222454;
                 10.0	0.08861355];

target_Sa_50 = [ 0.01	0.1936439;
                 0.02	0.19567049;
                 0.03	0.20581518;
                 0.05	0.23941128;
                 0.075	0.29643098;
                 0.1	0.35097677;
                 0.15	0.42553714;
                 0.2	0.45757508;
                 0.25	0.45612442;
                 0.3	0.4522229;
                 0.4	0.41964778;
                 0.5	0.39702424;
                 0.75	0.3127809;
                 1.0	0.25173715;
                 1.5	0.17542867;
                 2.0	0.13073543;
                 3.0	0.082794584;
                 4.0	0.06088886;
                 5.0	0.0509459;
                 7.5	0.028028723;
                 10.0	0.018584456];

% Range of periods
T  = 0.01:0.01:10;
wn = 2*pi./T; m  = 1; k  = (wn.^2)*m; z = 0.05;

Sd = zeros(1,length(T));
Sv = zeros(1,length(T));
Sa = zeros(1,length(T));

Spectra = struct();
Spectra.Sd = zeros(20, length(T));
Spectra.Sv = zeros(20, length(T));
Spectra.Sa = zeros(20, length(T));


for i = [2, 6]
    
    % Load Ground Motion
    recName = filenames(i).name;
    SFactor = ScaleFactors(i);
    
    currentRec = load([filenames(i).folder,'\',recName]);
    currentRec = currentRec.TimeAccelData;

    currentRec(:,2) = currentRec(:,2)*SFactor;
    dt = currentRec(2,1) - currentRec(1,1);

    % Run Ground Motion and Create Spectrum
    for j = 1:length(T)
        clear u v a
        [u,v,a] = CA_script(m,k(j),z,dt,currentRec(:,2));

        Sd(j) = max(abs(u));
        Sv(j) = Sd(j)*wn(j);
        Sa(j) = Sv(j)*wn(j);
        
    end

    Spectra.Sd(i, :) = Sd;
    Spectra.Sv(i, :) = Sv;
    Spectra.Sa(i, :) = Sa;
    
    figure(1) % Pseudo-acceleration spectra
    if i == 2
        plot(T, Spectra.Sa(i, :), 'r-', 'HandleVisibility','off'), hold on, xlabel('Period T (sec)'), ylabel('Pseudo-Accel. (g)'), grid on, axis([0.01 4 0.01 4.0])
    else
        plot(T, Spectra.Sa(i, :), 'k-', 'HandleVisibility','on'), hold on, xlabel('Period T (sec)'), ylabel('Pseudo-Accel. (g)'), grid on, axis([0.01 4 0.01 4.0])
    end
% %     % figure(2) % Pseudo-acceleration spectra
% %     % loglog(T,Spectra(i).Sd), hold on, xlabel('Period T (sec)'), ylabel('Pseudo-Disp. (g)'), grid on
% %     
% %     [ff,psdResult] = MyFFT(dt,currentRec(:,2));
% %     %figure(3)
% %     %plot(ff,psdResult), hold on, xlabel('Freq. (Hz)'), ylabel('Power'), grid on
% %     %axis([0 25 0 70])
% %     [maxvalue,maxindex] = max(psdResult);
% %     PredFreq(i) = ff(maxindex);
% % 
% %     [maxvalue,maxindex] = max(Sa);
% %     PredPeriod(i) = T(maxindex);
% % 
% %     PredCumVel(i) = trapz(abs(currentRec(:,2)))*dt;
end

%
% Sa_mean = (prod(Spectra.Sa)).^(1/20);
% figure(1)
% loglog(T, Sa_mean, 'k', 'linewidth', 1.5)
% loglog(target_Sa_2(:, 1),  target_Sa_2(:, 2), 'm', ...
%        target_Sa_5(:, 1),  target_Sa_5(:, 2), 'r',...
%        target_Sa_10(:, 1), target_Sa_10(:, 2), 'b',...
%        target_Sa_50(:, 1), target_Sa_50(:, 2), 'g',...
%        'linewidth', 1.5)
% legend('Selected Ground Motions', 'Suite Average', '2\% POE in 50 yr', '5\% POE in 50 yr', '10\% POE in 50 yr', '50\% POE in 50 yr', 'location', 'southwest')

%% Plot time history of selected ground motion

i = 1;
%  6 (100)
% 13 ( 75)
% 15 ( 75)
% 17 (100)

recName = filenames(i).name;
SFactor = ScaleFactors(i);


currentRec = load([filenames(i).folder,'\',recName]);
currentRec = currentRec.TimeAccelData;


acc = currentRec(:,2)*SFactor;
dt  = currentRec(2,1) - currentRec(1,1);
t   = currentRec(:,1);
vel = cumtrapz(acc)*dt*386;
dis = cumtrapz(vel)*dt;


figure(3)
subplot(221), plot(t,acc), title(['Acc. ',recName(1:end-4)]), grid on
subplot(222), plot(t,vel), title(['Vel. ',recName(1:end-4)]), grid on
subplot(223), plot(t,dis), title(['Dis. ',recName(1:end-4)]), grid on
subplot(224), plot(T,Spectra(i).Sa), title(['SA ',recName(1:end-4)]), grid on


% Get predominant T
for i = 1:length(filenames)
    [val,ind] = max(Spectra(i).Sd); T_peak(i) = T(ind);
end

%% Instantaneous power spectra


IP = 
[
    
]
