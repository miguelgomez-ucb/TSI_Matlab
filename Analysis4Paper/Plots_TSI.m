%% Call the Summary Table
clear, clc, close all
LatexPlots

%% Load all data
load SummTable_AG
SummTable_AG = SummTable(SummTable.pba <= 100, :); % Filter out some hlvl

load SummTable_OB
SummTable_OB = SummTable(SummTable.pba <= 100, :);

clear SummTable

filter = [99, 99, 99, 99, 99, 99, 99];
SummTable_OB(create_filter(SummTable_OB, filter), :);
show_dots = true;

%% Fragility
close all
% [hazlvl, cf, spd, bridgemodel, drcase, gm, drtype]
ag_cou_nl_sl = [99, 1, 99, 1, 99, 99, 99];
ob_cou_le_sl = [99, 0, 99, 0, 99, 99, 99];

nbins = 12;

% Fragilities using Peak Accelerations
frag_01_data = fit_fragility(SummTable_AG, ag_cou_nl_sl, 'pga', nbins);
fig = figure();
subplot(1,2,1)
plot_fragility(frag_01_data, true, 'b', 'b.')

frag_02_data = fit_fragility(SummTable_OB, ob_cou_le_sl, 'pga', nbins);
plot_fragility(frag_02_data, true, 'k--', 'k.')

frag_03_data = fit_fragility(SummTable_OB, ob_cou_le_sl, 'pba', nbins);
plot_fragility(frag_03_data, true, 'r:', 'r.')
legend('PGA - At Grade', 'PGA- Over Bridge', 'PBA - Over Bridge', 'Location','southeast')
xlabel('IM'), ylabel('$P(DR | IM)$')

% Fragilities using Peak Velocities
subplot(1,2,2)
frag_04_data = fit_fragility(SummTable_AG, ag_cou_nl_sl, 'pgv', nbins);
plot_fragility(frag_04_data, true, 'b', 'b.')

frag_05_data = fit_fragility(SummTable_OB, ob_cou_le_sl, 'pgv', nbins);
plot_fragility(frag_05_data, true, 'k--', 'k.')

frag_06_data = fit_fragility(SummTable_OB, ob_cou_le_sl, 'pbv', nbins);
plot_fragility(frag_06_data, true, 'r:', 'r.')
legend('PGV - At Grade', 'PGV - Over Bridge', 'PBV - Over Bridge', 'Location','southeast')
xlabel('IM'), ylabel('$P(DR | IM)$')

figsize = [800 200];
figpos = [300 300];
fig.Position = [figpos(1) figpos(2) figpos(1)+figsize(1) figpos(2)+figsize(2)];

disp(frag_01_data.beta)
disp(frag_02_data.beta)
disp(frag_03_data.beta)
disp('Something')
disp(frag_04_data.beta)
disp(frag_05_data.beta)
disp(frag_06_data.beta)

%% Functions

function [] = plot_fragility(fragility_data, show_dots, linespecs, dotspecs)
    if nargin < 3
        linespecs = 'r';
        dotspecs = '.r';
    end

    % Function to plot the fragility
    theta = fragility_data.theta;
    beta = fragility_data.beta;
    IM = fragility_data.im;
    COLL = fragility_data.collapse_ratio;
    im_max = fragility_data.im_max;
    % im_max = 100.0;

    % Vector to plot fragility
    xnew = 0:0.01:im_max;
    xmax = min([im_max, 5]);

    plot(xnew, normcdf(log(xnew), log(theta), beta), linespecs, 'LineWidth', 2.0)
    hold on
    
    %plot(1.0, 0.5, 'k*', 'MarkerSize', 10, 'HandleVisibility', 'off')

    if show_dots
        plot(IM, COLL, dotspecs, 'MarkerSize', 15.0, 'HandleVisibility', 'off')
    end
    
    fontsize(14, 'points')
    xlim([0 xmax])

end


function [frag_data, theta, beta, im, collapse_ratio, im_max] = fit_fragility(summ_table, filter, im_name, nbins)
    if nargin < 4
        nbins = 10;
    end

    % Depending on selected IM, get data from summ_table
    switch im_name
        case 'pga'
            col_idx = 5;
            sf = 1/9.81;
        case 'pgv'
            col_idx = 6;
            sf = 1;
        case 'pbd'
            col_idx = 7;
            sf = 1;
        case 'pbv'
            col_idx = 8;
            sf = 1;
        case 'pba'
            col_idx = 9;
            sf = 1/9.81;
        case 'pcha'
            col_idx = 16;
            sf = 1/9.81;
    end

    summ_table_filtered = summ_table(create_filter(summ_table, filter), :);
    
    % Extract relevant columns and sort with respect to im
    not_sorted_data = [table2array(summ_table_filtered(:, col_idx)) * sf, summ_table_filtered.drcase];
    sorted_data = sortrows(not_sorted_data);
    
    im_max = ceil(sorted_data(end, 1));
    im_win = im_max/nbins;

    im = zeros(1, round(im_max/im_win) + 1);
    num_gms = im;
    num_collapse = im;
    
    ii = 0;
    
    for im_vals = 0:im_win:im_max
        ii = ii + 1;
        im_min = im_vals;
        im_max = im_vals + im_win;
        idx = find((sorted_data(:, 1) > im_min).*(sorted_data(:, 1) < im_max));
    
        im(ii) = 0.5 * (im_min + im_max);
        num_collapse(ii) = sum(sorted_data(idx, 2));
        num_gms(ii) = length(idx);
    end
    
    [theta, beta] = fn_mle_pc(im, num_gms, num_collapse);
    collapse_ratio = num_collapse./num_gms;

    frag_data.theta = theta;
    frag_data.beta = beta;
    frag_data.im = im;
    frag_data.collapse_ratio = collapse_ratio;
    frag_data.im_max = im_max;

end


function idx = create_filter(summ_table, filter)
    % This function creates the filter array to summ_table
    % [hazlvl, cf, spd, bridgemodel, drcase, gm, drtype]

    filter_array = ones(1, size(summ_table, 1));

    for ff = 1:length(filter)
        switch ff
            case 1
                % hazlvl
                if filter(ff) ~= 99 
                    filter_array = filter_array .* (summ_table.hazlvl <= filter(ff))';
                end
            case 2
                % cf
                if filter(ff) ~= 99 
                    filter_array = filter_array .* (summ_table.cf == filter(ff))';
                end
            case 3
                % spd
                if filter(ff) ~= 99 
                    filter_array = filter_array .* (summ_table.spd <= filter(ff))';
                end
            case 4
                % bridgemodel
                if filter(ff) ~= 99 
                    filter_array = filter_array .* (summ_table.bridgemodel == filter(ff))';
                end
            case 5
                % drcase
                if filter(ff) ~= 99 
                    filter_array = filter_array .* (summ_table.drcase == filter(ff))';
                end
            case 6
                % gm
                if filter(ff) ~= 99 
                    filter_array = filter_array .* (summ_table.gm == filter(ff))';
                end
            case 7
                % drtype
                if filter(ff) ~= 99 
                    filter_array = filter_array .* (summ_table.drtype == filter(ff))';
                end
        end
    end
    disp(filter_array)
    % Create array of indices that match the filter criteria
    idx = find(filter_array);

end


%%%%%
% 
% % NONLINEAR MODEL
% filter = find((SummTable.bridgemodel == 1.0) .* (SummTable.cf == 1.0));
% NotSortedData = [SummTable(filter,:).pbv, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot NL Model
% plot(...
%     xnew, ynew, 'b-.', 'linewidth', 2.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment'), xlim([0 5])
% 
% % Decoupled
% filter = find((SummTable.bridgemodel == 1.0) .* (SummTable.cf == 0.0));
% NotSortedData = [SummTable(filter,:).pbv, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot NL Model
% plot(...
%     xnew, ynew, 'b-.', 'linewidth', 1.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment'), xlim([0 5])
% %
% 
% % AT GRADE MODEL
% filter = find((SummTable_AG.bridgemodel == 1.0) .* (SummTable_AG.cf == 1.0));
% NotSortedData = [SummTable_AG(filter,:).pgv, SummTable_AG(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot At Grade Model
% fontsize(16, 'points')
% plot(...
%     xnew, ynew, 'k--', 'linewidth', 2.0), grid on, xlabel('PBV or PGV (m/s)'), ylabel('P(Derailment $|$ PBV or PGV)'), xlim([0 5])
% legend('LE - Coupled', 'LE - Decoupled', 'NL - Coupled', 'NL - Decoupled', 'At Grade', 'location', 'southeast')
% %saveas(gcf, 'frag_pbv_pgv.pdf')
% 
% close
% % LINEAR ELASTIC MODEL
% filter = find((SummTable.bridgemodel == 0.0) .* (SummTable.cf == 1.0));
% NotSortedData = [SummTable(filter,:).pba/9.81, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot Nonlinear Model
% plot(...
%     xnew, ynew, 'r', 'LineWidth', 2.0), grid on, xlabel('PBA (g)'), ylabel('Derailment')
% hold on
% 
% % Decoupled
% % LINEAR ELASTIC MODEL
% filter = find((SummTable.bridgemodel == 0.0) .* (SummTable.cf == 0.0));
% NotSortedData = [SummTable(filter,:).pba/9.81, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot Nonlinear Model
% plot(...
%     xnew, ynew, 'r', 'LineWidth', 1.0), grid on, xlabel('PBA (g)'), ylabel('Derailment')
% hold on
% 
% %NONLINEAR MODEL
% filter = find((SummTable.bridgemodel == 1.0) .* (SummTable.cf == 1.0));
% NotSortedData = [SummTable(filter,:).pba/9.81, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot Linear Model
% plot(...
%     xnew, ynew, 'b:', 'LineWidth', 2.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment'), xlim([0 5])
% 
% % Decoupled
% filter = find((SummTable.bridgemodel == 1.0) .* (SummTable.cf == 0.0));
% NotSortedData = [SummTable(filter,:).pba/9.81, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot Linear Model
% plot(...
%     xnew, ynew, 'b:', 'LineWidth', 1.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment'), xlim([0 5])
% 
% % NOW, DO AT GRADE
% filter = find((SummTable_AG.bridgemodel == 1.0) .* (SummTable_AG.cf == 1.0));
% NotSortedData = [SummTable_AG(filter,:).pga/9.81, SummTable_AG(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot Linear Model
% fontsize(16, 'points')
% plot(...
%     xnew, ynew, 'k--', 'LineWidth', 2.0), grid on, xlabel('PBA or PGA (g)'), ylabel('P(Derailment $|$ PBA or PGA)'), xlim([0 5])
% legend('LE - Coupled', 'LE - Decoupled', 'NL - Coupled', 'NL - Decoupled', 'At Grade', 'location', 'southeast')
% % saveas(gcf, 'frag_pba_pga.pdf')
% 
% close
% % LINEAR ELASTIC MODEL
% filter = find((SummTable.bridgemodel == 0.0) .* (SummTable.cf == 1.0));
% NotSortedData = [SummTable(filter,:).pcha/9.81, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot Nonlinear Model
% plot(...
%     xnew, ynew, 'r', 'LineWidth', 2.0), grid on, xlabel('PBA (g)'), ylabel('Derailment')
% hold on
% 
% % Decoupled
% % LINEAR ELASTIC MODEL
% filter = find((SummTable.bridgemodel == 0.0) .* (SummTable.cf == 0.0));
% NotSortedData = [SummTable(filter,:).pcha/9.81, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot Nonlinear Model
% plot(...
%     xnew, ynew, 'r', 'LineWidth', 1.0), grid on, xlabel('PBA (g)'), ylabel('Derailment')
% hold on
% 
% %NONLINEAR MODEL
% filter = find((SummTable.bridgemodel == 1.0) .* (SummTable.cf == 1.0));
% NotSortedData = [SummTable(filter,:).pcha/9.81, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot Linear Model
% plot(...
%     xnew, ynew, 'b:', 'LineWidth', 2.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment'), xlim([0 5])
% 
% % Decoupled
% filter = find((SummTable.bridgemodel == 1.0) .* (SummTable.cf == 0.0));
% NotSortedData = [SummTable(filter,:).pcha/9.81, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot Linear Model
% plot(...
%     xnew, ynew, 'b:', 'LineWidth', 1.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment'), xlim([0 5])
% 
% % NOW, DO AT GRADE
% filter = find((SummTable_AG.bridgemodel == 1.0) .* (SummTable_AG.cf == 1.0));
% NotSortedData = [SummTable_AG(filter,:).pcha/9.81, SummTable_AG(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot Linear Model
% fontsize(16, 'points')
% plot(...
%     xnew, ynew, 'k--', 'LineWidth', 2.0), grid on, xlabel('PCHA (g)'), ylabel('P(Derailment | PCHA)'), xlim([0 1.5])
% legend('LE - Coupled', 'LE - Decoupled', 'NL - Coupled', 'NL - Decoupled', 'At Grade', 'location', 'southeast')
% % saveas(gcf, 'frag_pcha.pdf')
% 
% close
% % LINEAR ELASTIC MODEL
% filter = find((SummTable.bridgemodel == 0.0) .* (SummTable.cf == 1.0));
% NotSortedData = [SummTable(filter,:).pgv, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot LE model
% plot(...
%     xnew, ynew, 'r', 'LineWidth', 2.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment')
% hold on
% 
% % Decoupled case now
% filter = find((SummTable.bridgemodel == 0.0) .* (SummTable.cf == 0.0));
% NotSortedData = [SummTable(filter,:).pgv, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot LE model - decoupled
% plot(...
%     xnew, ynew, 'r', 'LineWidth', 1.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment')
% hold on
% %%%%%
% 
% % NONLINEAR MODEL
% filter = find((SummTable.bridgemodel == 1.0) .* (SummTable.cf == 1.0));
% NotSortedData = [SummTable(filter,:).pgv, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot NL Model
% plot(...
%     xnew, ynew, 'b:', 'linewidth', 2.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment'), xlim([0 5])
% 
% % Decoupled
% filter = find((SummTable.bridgemodel == 1.0) .* (SummTable.cf == 0.0));
% NotSortedData = [SummTable(filter,:).pgv, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot NL Model
% plot(...
%     xnew, ynew, 'b:', 'linewidth', 1.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment'), xlim([0 5])
% %
% 
% % AT GRADE MODEL
% filter = find((SummTable_AG.bridgemodel == 1.0) .* (SummTable_AG.cf == 1.0));
% NotSortedData = [SummTable_AG(filter,:).pgv, SummTable_AG(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot At Grade Model
% fontsize(16, 'points')
% plot(...
%     xnew, ynew, 'k--', 'linewidth', 2.0), grid on, xlabel('PGV (m/s)'), ylabel('P(Derailment | PGV)'), xlim([0 5])
% legend('LE - Coupled', 'LE - Decoupled', 'NL - Coupled', 'NL - Decoupled', 'At Grade', 'location', 'southeast')
% % saveas(gcf, 'frag_pgv.pdf')
% 
% 
% 
% close
% % LINEAR ELASTIC MODEL
% filter = find((SummTable.bridgemodel == 0.0) .* (SummTable.cf == 1.0));
% NotSortedData = [SummTable(filter,:).pga/9.81, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot LE model
% plot(...
%     xnew, ynew, 'r', 'LineWidth', 2.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment')
% hold on
% 
% % Decoupled case now
% filter = find((SummTable.bridgemodel == 0.0) .* (SummTable.cf == 0.0));
% NotSortedData = [SummTable(filter,:).pga/9.81, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot LE model - decoupled
% fontsize(16, 'points')
% plot(...
%     xnew, ynew, 'r', 'LineWidth', 1.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment')
% hold on
% %%%%%
% 
% % NONLINEAR MODEL
% filter = find((SummTable.bridgemodel == 1.0) .* (SummTable.cf == 1.0));
% NotSortedData = [SummTable(filter,:).pga/9.81, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot NL Model
% plot(...
%     xnew, ynew, 'b:', 'linewidth', 2.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment'), xlim([0 5])
% 
% % Decoupled
% filter = find((SummTable.bridgemodel == 1.0) .* (SummTable.cf == 0.0));
% NotSortedData = [SummTable(filter,:).pga/9.81, SummTable(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot NL Model
% plot(...
%     xnew, ynew, 'b:', 'linewidth', 1.0), grid on, xlabel('PBV (m/s)'), ylabel('Derailment'), xlim([0 5])
% %
% 
% % AT GRADE MODEL
% filter = find((SummTable_AG.bridgemodel == 1.0) .* (SummTable_AG.cf == 1.0));
% NotSortedData = [SummTable_AG(filter,:).pga/9.81, SummTable_AG(filter,:).drcase];
% SortedData = sortrows(NotSortedData);
% 
% mdl = fitglm(SortedData(:,1), SortedData(:,2), "Distribution", "binomial");
% xnew = (0:0.01:5)';
% ynew = predict(mdl, xnew);
% 
% % Plot At Grade Model
% fontsize(16, 'points')
% plot(...
%     xnew, ynew, 'k--', 'linewidth', 2.0), grid on, xlabel('PGA (g)'), ylabel('P(Derailment | PGA)'), xlim([0 5])
% legend('LE - Coupled', 'LE - Decoupled', 'NL - Coupled', 'NL - Decoupled', 'At Grade', 'location', 'southeast')
% % saveas(gcf, 'frag_pga.pdf')
% 
% close
% indices1 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == 0.0));  % Linear Elastic, Decoupled
% indices2 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == 1.0));  % Linear Elastic, Coupled
% indices3 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == 0.0));  % Nonlinear, Decoupled
% indices4 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == 1.0));  % Nonlinear, Coupled
% 
% fontsize(16, 'points')
% plot(SummTable(indices1,:).pga/9.81, SummTable(indices1,:).pba/9.81, 'rx', ...
%      SummTable(indices2,:).pga/9.81, SummTable(indices2,:).pba/9.81, 'r.', ...
%      SummTable(indices3,:).pga/9.81, SummTable(indices3,:).pba/9.81, 'bx', ...
%      SummTable(indices4,:).pga/9.81, SummTable(indices4,:).pba/9.81, 'b.','MarkerSize', 10.0)
% 
% xlabel('PGA (g)'), ylabel('PBA (m)'), legend('LE, Decoupled', 'LE, Coupled', 'NL, Decoupled', 'NL, Coupled')
% 
% axis([0, 6, 0, 6])
% grid on
% 
% close
% indices1 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == 0.0));  % Linear Elastic, Decoupled
% indices2 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == 1.0));  % Linear Elastic, Coupled
% indices3 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == 0.0));  % Nonlinear, Decoupled
% indices4 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == 1.0));  % Nonlinear, Coupled
% 
% fontsize(16, 'points')
% plot(SummTable(indices1,:).pbv, SummTable(indices1,:).pbd, 'rx', ...
%      SummTable(indices2,:).pbv, SummTable(indices2,:).pbd, 'r.', ...
%      SummTable(indices3,:).pbv, SummTable(indices3,:).pbd, 'bx', ...
%      SummTable(indices4,:).pbv, SummTable(indices4,:).pbd, 'b.','MarkerSize', 10.0)
% 
% xlabel('PBV (m/s)'), ylabel('PBD (m)'), legend('LE, Decoupled', 'LE, Coupled', 'NL, Decoupled', 'NL, Coupled')
% 
% %axis([0, 3, 0, 3])
% grid on
% 
% close
% 
% indices1 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == 0.0));  % Linear Elastic, Decoupled
% indices2 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == 1.0));  % Linear Elastic, Coupled
% indices3 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == 0.0));  % Nonlinear, Decoupled
% indices4 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == 1.0));  % Nonlinear, Coupled
% 
% fontsize(16, 'points')
% plot(SummTable(indices1,:).pga/9.81, SummTable(indices1,:).pba/9.81, 'rx', ...
%      SummTable(indices2,:).pga/9.81, SummTable(indices2,:).pba/9.81, 'r.', ...
%      SummTable(indices3,:).pga/9.81, SummTable(indices3,:).pba/9.81, 'bx', ...
%      SummTable(indices4,:).pga/9.81, SummTable(indices4,:).pba/9.81, 'b.','MarkerSize', 10.0)
% 
% xlabel('PGA (m/s)'), ylabel('PBA (g)'), legend('LE, Decoupled', 'LE, Coupled', 'NL, Decoupled', 'NL, Coupled', 'location', 'southeast')
% 
% axis([0, 6, 0, 6])
% grid on
% 
% close
% 
% indices1 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == 0.0));  % Linear Elastic, Decoupled
% indices2 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == 1.0));  % Linear Elastic, Coupled
% indices3 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == 0.0));  % Nonlinear, Decoupled
% indices4 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == 1.0));  % Nonlinear, Coupled
% 
% fontsize(16, 'points')
% plot(SummTable(indices1,:).pga/9.81, SummTable(indices1,:).pbd / 6 * 100, 'rx', ...
%      SummTable(indices2,:).pga/9.81, SummTable(indices2,:).pbd / 6 * 100, 'r.', ...
%      SummTable(indices3,:).pga/9.81, SummTable(indices3,:).pbd / 6 * 100, 'bx', ...
%      SummTable(indices4,:).pga/9.81, SummTable(indices4,:).pbd / 6 * 100, 'b.','MarkerSize', 10.0)
% 
% xlabel('PGA (g)'), ylabel('PID (\%)'), legend('LE, Decoupled', 'LE, Coupled', 'NL, Decoupled', 'NL, Coupled')
% 
% 
% axis([0, 10, 0, 10])
% grid on
% 
% 
% close
% indices1 = find((SummTable.bridgemodel == 0.0).*(SummTable.drcase == 0.0));  % Linear Elastic, Decoupled
% indices2 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 0.0));  % Nonlinear, Decoupled
% indices3 = find((SummTable.bridgemodel == 0.0).*(SummTable.drcase == 1.0));  % Linear Elastic, Coupled
% indices4 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 1.0));  % Nonlinear, Coupled
% 
% fontsize(16, 'points')
% plot(SummTable(indices1,:).pbv, SummTable(indices1,:).pcha/9.81, 'r.', ...
%      SummTable(indices2,:).pbv, SummTable(indices2,:).pcha/9.81, 'b.', ...
%      SummTable(indices3,:).pbv, SummTable(indices3,:).pcha/9.81, 'rx', ...
%      SummTable(indices4,:).pbv, SummTable(indices4,:).pcha/9.81, 'bx','MarkerSize', 10.0)
% axis([0 6 0 1.2])
% grid on
% 
% close
% indices1 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == 0.0).*(SummTable.spd > 20.0));  % Linear Elastic, Decoupled
% indices2 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == 0.0).*(SummTable.spd > 20.0));  % Nonlinear, Decoupled
% indices3 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == 1.0).*(SummTable.spd > 20.0));  % Linear Elastic, Coupled
% indices4 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == 1.0).*(SummTable.spd > 20.0));  % Nonlinear, Coupled
% 
% for i = 1:length(indices1)
%     plot([SummTable(indices1(i),:).pbv, SummTable(indices3(i),:).pbv], ...
%          [SummTable(indices2(i),:).pbv, SummTable(indices4(i),:).pbv], ':', ...
%         linewidth=0.5, HandleVisibility='off', Color=[0.2, 0.2, 0.2]), hold on
% end
% 
% fontsize(16, 'points')
% plot(SummTable(indices1,:).pbv, SummTable(indices2,:).pbv, 'rs', ...
%      SummTable(indices3,:).pbv, SummTable(indices4,:).pbv, 'kv', ...
%      [0 10], [0 10], 'k--', 'MarkerSize', 6.0), grid
% axis([0 6 0 6])
% xlabel('PBV (m/s) - Linear Elastic')
% ylabel('PBV (m/s) - Nonlinear')
% legend('Decoupled', 'Coupled', 'location', 'northwest')
% % saveas(gcf, 'pbv_linear_nonlinear.pdf')
% 
% 
% close
% indices1 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == 0.0).*(SummTable.spd > 20.0));  % Linear Elastic, Decoupled
% indices2 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == 0.0).*(SummTable.spd > 20.0));  % Nonlinear, Decoupled
% indices3 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == 1.0).*(SummTable.spd > 20.0));  % Linear Elastic, Coupled
% indices4 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == 1.0).*(SummTable.spd > 20.0));  % Nonlinear, Coupled
% 
% for i = 1:length(indices1)
%     plot([SummTable(indices1(i),:).pba, SummTable(indices3(i),:).pba]/9.81, ...
%          [SummTable(indices2(i),:).pba, SummTable(indices4(i),:).pba]/9.81, ':', ...
%         linewidth=0.5, HandleVisibility='off', Color=[0.2, 0.2, 0.2]), hold on
% end
% 
% fontsize(16, 'points')
% plot(SummTable(indices1,:).pba/9.81, SummTable(indices2,:).pba/9.81, 'rs', ...
%      SummTable(indices3,:).pba/9.81, SummTable(indices4,:).pba/9.81, 'kv', ...
%      [0 10], [0 10], 'k--', 'MarkerSize', 6.0), grid
% axis([0 5 0 5])
% xlabel('PBA (g) - Linear Elastic')
% ylabel('PBA (g) - Nonlinear')
% legend('Decoupled', 'Coupled', 'location', 'northwest')
% % saveas(gcf, 'pba_linear_nonlinear.pdf')
% 
% close all
% cfac = 1.0;
% indices1 = find((SummTable.bridgemodel == 0.0).*(SummTable.drcase == 0.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Linear Elastic, Decoupled
% indices2 = find((SummTable.bridgemodel == 0.0).*(SummTable.drcase == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Nonlinear, Decoupled
% indices3 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 0.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Linear Elastic, Coupled
% indices4 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Nonlinear, Coupled
% 
% indices5 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));
% indices6 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));
% 
% 
% peakrot = 0.836;
% 
% pfit1 = fit(SummTable(indices1,:).pbd/6, SummTable(indices1,:).purot, fittype({'x^2'}));
% pfit2 = fit(SummTable(indices3,:).pbd/6, SummTable(indices3,:).purot, fittype({'x^2'}));
% 
% for i = 1:length(indices6)
%     plot([SummTable(indices5(i),:).pbd, SummTable(indices6(i),:).pbd] / 6, [SummTable(indices5(i),:).purot, SummTable(indices6(i),:).purot]/peakrot, ':', ...
%         linewidth=0.05, HandleVisibility='off', Color=[0.7, 0.7, 0.7]), hold on
% end
% 
% area(0:0.01:6.0, ones(1, length(0:0.01:6.0)),'FaceAlpha', 0.1, 'FaceColor', 'k', 'EdgeColor', 'none', 'HandleVisibility','off')
% plot(SummTable(indices1,:).pbd/6, SummTable(indices1,:).purot/peakrot, 'bs', ...
%      SummTable(indices2,:).pbd/6, SummTable(indices2,:).purot/peakrot, 'rx', ...
%      SummTable(indices3,:).pbd/6, SummTable(indices3,:).purot/peakrot, 'kv', ...
%      SummTable(indices4,:).pbd/6, SummTable(indices4,:).purot/peakrot, 'r*', 'MarkerSize', 6.0)
% 
% fontsize(16, 'points')
% plot(0:0.001:0.012, pfit1(0:0.001:0.012)/peakrot, 'b', ...
%      0:0.001:0.044, pfit2(0:0.001:0.044)/peakrot, 'k--', ...
%      'LineWidth', 2.0);
% 
% axis([0 0.1 0 5.0])
% grid, legend('LE - No Derailment', 'LE - Derailment', 'NL - No Derailment', 'NL - Derailment', Location='northwest')
% xlabel('PDR ($\Delta / h$)'), ylabel('Rotation Ratio')
% % saveas(gcf, 'rr_pdr.pdf')
% 
% close all
% cfac = 0.0;
% indices1 = find((SummTable.bridgemodel == 0.0).*(SummTable.drcase == 0.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Linear Elastic, Decoupled
% indices2 = find((SummTable.bridgemodel == 0.0).*(SummTable.drcase == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Nonlinear, Decoupled
% indices3 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 0.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Linear Elastic, Coupled
% indices4 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Nonlinear, Coupled
% 
% indices5 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));
% indices6 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));
% 
% 
% peakrot = 0.836;
% 
% pfit1 = fit(SummTable(indices1,:).pbv, SummTable(indices1,:).purot, fittype({'x^2'}));
% pfit2 = fit(SummTable(indices3,:).pbv, SummTable(indices3,:).purot, fittype({'x^2'}));
% 
% for i = 1:length(indices6)
%     plot([SummTable(indices5(i),:).pbv, SummTable(indices6(i),:).pbv], ...
%          [SummTable(indices5(i),:).purot, SummTable(indices6(i),:).purot]/peakrot, ':', ...
%         linewidth=0.05, HandleVisibility='off', Color=[0.7, 0.7, 0.7]), hold on
% end
% 
% area(0:0.01:6.0, ones(1, length(0:0.01:6.0)),'FaceAlpha', 0.1, 'FaceColor', 'k', 'EdgeColor', 'none', 'HandleVisibility','off')
% plot(SummTable(indices1,:).pbv, SummTable(indices1,:).purot/peakrot, 'bs', ...
%      SummTable(indices2,:).pbv, SummTable(indices2,:).purot/peakrot, 'rx', ...
%      SummTable(indices3,:).pbv, SummTable(indices3,:).purot/peakrot, 'kv', ...
%      SummTable(indices4,:).pbv, SummTable(indices4,:).purot/peakrot, 'r*', 'MarkerSize', 6.0)
% 
% fontsize(16, 'points')
% plot(0:0.01:2.55, pfit1(0:0.01:2.55)/peakrot, 'b', ...
%      0:0.01:2.65, pfit2(0:0.01:2.65)/peakrot, 'k--', ...
%      'LineWidth', 2.0);
% axis([0 5.0 0 5.0])
% grid, legend('LE - No Derailment', 'LE - Derailment', 'NL - No Derailment', 'NL - Derailment', Location='northwest')
% xlabel('PBV (m/s)'), ylabel('Rotation Ratio')
% % saveas(gcf, 'rr_pbv_model.pdf')
% 
% close all
% cfac = 0.0;  % Only coupled cases
% indices1 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 0.0).*(SummTable.cf == cfac).*(SummTable.spd < 1));  % Linear No derail
% indices2 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 1.0).*(SummTable.cf == cfac).*(SummTable.spd < 1));  % Linear Derail
% indices3 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 0.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Nonlinear No derail
% indices4 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Nonlinear derail
% 
% indices5 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == cfac).*(SummTable.spd < 1));  % Nonlinear, all
% indices6 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Linear, all
% 
% peakrot = 0.836;
% 
% pfit1 = fit(SummTable(indices1,:).pbv, SummTable(indices1,:).purot, fittype({'x^2'}));
% pfit2 = fit(SummTable(indices3,:).pbv, SummTable(indices3,:).purot, fittype({'x^2'}));
% 
% for i = 1:length(indices5)
%     plot([SummTable(indices5(i),:).pbv, SummTable(indices6(i),:).pbv], [SummTable(indices5(i),:).purot, SummTable(indices6(i),:).purot]/peakrot, ':', ...
%         linewidth=0.05, HandleVisibility='off', Color=[0.5, 0.5, 0.5]), hold on
% end
% 
% area(0:0.01:6.0, ones(1, length(0:0.01:6.0)),'FaceAlpha', 0.1, 'FaceColor', 'k', 'EdgeColor', 'none', 'HandleVisibility','off')
% plot(SummTable(indices1,:).pbv, SummTable(indices1,:).purot/peakrot, 'bs', ...
%      SummTable(indices2,:).pbv, SummTable(indices2,:).purot/peakrot, 'rx', ...
%      SummTable(indices3,:).pbv, SummTable(indices3,:).purot/peakrot, 'kv', ...
%      SummTable(indices4,:).pbv, SummTable(indices4,:).purot/peakrot, 'r*', 'MarkerSize', 6.0)
% 
% fontsize(16, 'points')
% plot(0:0.01:2.65, pfit1(0:0.01:2.65)/peakrot, 'b', ...
%      0:0.01:2.65, pfit2(0:0.01:2.65)/peakrot, 'k--', ...
%      'LineWidth', 2.0);
% 
% axis([0 5.0 0 5.0])
% grid, legend('0 km/h - No Derailment', '0 km/h - Derailment', '80 km/h  - No Derailment', '80 km/h  - Derailment', Location='northwest')
% xlabel('PBV (m/s)'), ylabel('Rotation Ratio')
% % saveas(gcf, 'rr_pbv_spd_dec.pdf')
% 
% close all
% cfac = 0.0;  % Only coupled cases
% indices1 = find((SummTable.bridgemodel == 0.0).*(SummTable.drcase == 0.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Linear No derail
% indices2 = find((SummTable.bridgemodel == 0.0).*(SummTable.drcase == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Linear Derail
% indices3 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 0.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Nonlinear No derail
% indices4 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Nonlinear derail
% 
% indices5 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Nonlinear, all
% indices6 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Linear, all
% 
% peakrot = 0.836;
% 
% pfit1 = fit(SummTable(indices1,:).pga/9.81, SummTable(indices1,:).purot, fittype({'x^2'}));
% pfit2 = fit(SummTable(indices3,:).pga/9.81, SummTable(indices3,:).purot, fittype({'x^2'}));
% 
% for i = 1:length(indices6)
%     plot([SummTable(indices5(i),:).pga, SummTable(indices6(i),:).pga]/9.81, [SummTable(indices5(i),:).purot, SummTable(indices6(i),:).purot]/peakrot, ':', ...
%         linewidth=0.05, HandleVisibility='off', Color=[0.5, 0.5, 0.5]), hold on
% end
% 
% area(0:0.01:6.0, ones(1, length(0:0.01:6.0)),'FaceAlpha', 0.1, 'FaceColor', 'k', 'EdgeColor', 'none', 'HandleVisibility','off')
% 
% fontsize(16, 'points')
% plot(SummTable(indices1,:).pga/9.81, SummTable(indices1,:).purot/peakrot, 'bs', ...
%      SummTable(indices2,:).pga/9.81, SummTable(indices2,:).purot/peakrot, 'rx', ...
%      SummTable(indices3,:).pga/9.81, SummTable(indices3,:).purot/peakrot, 'kv', ...
%      SummTable(indices4,:).pga/9.81, SummTable(indices4,:).purot/peakrot, 'r*', 'MarkerSize', 6.0)
% plot(0:0.01:1.25, pfit1(0:0.01:1.25)/peakrot, 'b', ...
%      0:0.01:2.35, pfit2(0:0.01:2.35)/peakrot, 'k--', ...
%      'LineWidth', 2.0);
% 
% axis([0 5.0 0 5.0])
% grid, legend('LE - No Derailment', 'LE - Derailment', 'NL - No Derailment', 'NL - Derailment', Location='northwest')
% xlabel('PGA (g)'), ylabel('Rotation Ratio')
% % saveas(gcf, 'rr_pga_model.pdf')
% 
% close all
% cfac = 1.0;  % Only coupled cases
% indices1 = find((SummTable.bridgemodel == 0.0).*(SummTable.drcase == 0.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Linear No derail
% indices2 = find((SummTable.bridgemodel == 0.0).*(SummTable.drcase == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Linear Derail
% indices3 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 0.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Nonlinear No derail
% indices4 = find((SummTable.bridgemodel == 1.0).*(SummTable.drcase == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Nonlinear derail
% 
% indices5 = find((SummTable.bridgemodel == 0.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Nonlinear, all
% indices6 = find((SummTable.bridgemodel == 1.0).*(SummTable.cf == cfac).*(SummTable.spd > 1));  % Linear, all
% 
% peakrot = 0.836;
% 
% pfit1 = fit(SummTable(indices1,:).pgv, SummTable(indices1,:).purot, fittype({'x^2'}));
% pfit2 = fit(SummTable(indices3,:).pgv, SummTable(indices3,:).purot, fittype({'x^2'}));
% 
% for i = 1:length(indices6)
%     plot([SummTable(indices5(i),:).pgv, SummTable(indices6(i),:).pgv], ...
%         [SummTable(indices5(i),:).purot, SummTable(indices6(i),:).purot]/peakrot, ':', ...
%         linewidth=0.05, HandleVisibility='off', Color=[0.5, 0.5, 0.5]), hold on
% end
% 
% area(0:0.01:6.0, ones(1, length(0:0.01:6.0)),'FaceAlpha', 0.1, 'FaceColor', 'k', 'EdgeColor', 'none', 'HandleVisibility','off')
% 
% plot(SummTable(indices1,:).pgv, SummTable(indices1,:).purot/peakrot, 'bs', ...
%      SummTable(indices2,:).pgv, SummTable(indices2,:).purot/peakrot, 'rx', ...
%      SummTable(indices3,:).pgv, SummTable(indices3,:).purot/peakrot, 'kv', ...
%      SummTable(indices4,:).pgv, SummTable(indices4,:).purot/peakrot, 'r*', 'MarkerSize', 6.0)
% 
% fontsize(16, 'points')
% plot(0:0.01:2.38, pfit1(0:0.01:2.38)/peakrot, 'b', ...
%      0:0.01:2.81, pfit2(0:0.01:2.81)/peakrot, 'k--', ...
%      'LineWidth', 2.0);
% 
% axis([0 5.0 0 5.0])
% grid, legend('LE - No Derailment', 'LE - Derailment', 'NL - No Derailment', 'NL - Derailment', Location='northwest')
% xlabel('PGV (m/s)'), ylabel('Rotation Ratio')
% % saveas(gcf, 'rr_pgv_model.pdf')
% 
% % Coupled/Decoupled 
% close all
% indices1 = find((SummTable.cf == 1.0) .* (SummTable.bridgemodel == 0.0));  % Coupled
% indices2 = find((SummTable.cf == 1.0) .* (SummTable.bridgemodel == 1.0));  % Decoupled
% indices3 = find((SummTable.cf == 0.0) .* (SummTable.bridgemodel == 0.0));  % Coupled
% indices4 = find((SummTable.cf == 0.0) .* (SummTable.bridgemodel == 1.0));  % Decoupled
% 
% 
% reg1 = polyfit(SummTable(indices1,:).pbd/6, SummTable(indices3,:).pbd/6, 1);
% reg2 = polyfit(SummTable(indices2,:).pbd/6, SummTable(indices4,:).pbd/6, 1);
% 
% for i = 1:length(indices6)
%     plot([SummTable(indices1(i),:).pbd/6, SummTable(indices2(i),:).pbd/6], ...
%          [SummTable(indices3(i),:).pbd/6, SummTable(indices4(i),:).pbd/6], ':', ...
%         linewidth=0.05, HandleVisibility='off', Color=[0.7, 0.7, 0.7]), hold on
% end
% 
% xmax = 0.1;
% fontsize(16, 'points')
% plot(SummTable(indices1,:).pbd/6, SummTable(indices3,:).pbd/6, 'rs', ...
%      SummTable(indices2,:).pbd/6, SummTable(indices4,:).pbd/6, 'kv', ...
%      [0, xmax], polyval(reg1, [0,xmax]), 'r--', ...
%      [0, xmax], polyval(reg2, [0,xmax]), 'k--', ...
%      [0, xmax], [0, xmax], 'k--', MarkerSize=6.0), axis([0 xmax 0 xmax]),...
% xlabel('PDR ($\Delta/h$), Coupled'), ylabel('PDR ($\Delta/h$), Decoupled'), grid on,...
% legend('Linear Elastic Bridge', 'Nonlinear Bridge', Location='northwest')
% % saveas(gcf, 'pdr_coupled_model.pdf')
% 
% 
% close all
% indices1 = find((SummTable.cf == 1.0) .* (SummTable.bridgemodel == 0.0));  % Coupled, Linear
% indices2 = find((SummTable.cf == 1.0) .* (SummTable.bridgemodel == 1.0));  % Coupled, Nonlinear
% indices3 = find((SummTable.cf == 0.0) .* (SummTable.bridgemodel == 0.0));  % Decoupled, Linear
% indices4 = find((SummTable.cf == 0.0) .* (SummTable.bridgemodel == 1.0));  % Decoupled, Nonlinear
% 
% 
% reg1 = polyfit(SummTable(indices1,:).pba/9.81, SummTable(indices3,:).pba/9.81, 1);
% reg2 = polyfit(SummTable(indices2,:).pba/9.81, SummTable(indices4,:).pba/9.81, 1);
% 
% for i = 1:length(indices1)
%     plot([SummTable(indices1(i),:).pba, SummTable(indices2(i),:).pba]/9.81, ...
%          [SummTable(indices3(i),:).pba, SummTable(indices4(i),:).pba]/9.81, ':', ...
%         linewidth=0.05, HandleVisibility='off', Color=[0.7, 0.7, 0.7]), hold on
% end
% 
% fontsize(16, 'points')
% plot(SummTable(indices1,:).pba/9.81, SummTable(indices3,:).pba/9.81, 'rs', ...
%      SummTable(indices2,:).pba/9.81, SummTable(indices4,:).pba/9.81, 'kv', ...
%      [0, 5], [0, 5], 'k--', MarkerSize=6.0), axis([0 5.0 0 5.0]), ...
%      xlabel('PBA (g) - Coupled'), ylabel('PBA (g) - Decoupled'), grid on, ...
%      legend('Linear Elastic Bridge', 'Nonlinear Bridge', Location='northwest')
% % saveas(gcf, 'pba_coupled_model.pdf')
% 
% close all
% SummTable = SummTable_OB;
% indices1 = find((SummTable.cf == 1.0) .* (SummTable.bridgemodel == 0.0));  % Coupled
% indices2 = find((SummTable.cf == 1.0) .* (SummTable.bridgemodel == 1.0));  % Decoupled
% indices3 = find((SummTable.cf == 0.0) .* (SummTable.bridgemodel == 0.0));  % Coupled
% indices4 = find((SummTable.cf == 0.0) .* (SummTable.bridgemodel == 1.0));  % Decoupled
% 
% 
% reg1 = polyfit(SummTable(indices1,:).pcha / 9.81, SummTable(indices3,:).pcha / 9.81, 1);
% reg2 = polyfit(SummTable(indices2,:).pcha / 9.81, SummTable(indices4,:).pcha / 9.81, 1);
% 
% for i = 1:length(indices4)
%     plot([SummTable(indices1(i),:).pcha, SummTable(indices2(i),:).pcha]/9.81, ...
%          [SummTable(indices3(i),:).pcha, SummTable(indices4(i),:).pcha]/9.81, ':', ...
%         linewidth=0.05, HandleVisibility='off', Color=[0.5, 0.5, 0.5]), hold on
% end
% 
% fontsize(16, 'points')
% plot(SummTable(indices1,:).pcha / 9.81, SummTable(indices3,:).pcha / 9.81, 'rs', ...
%      SummTable(indices2,:).pcha / 9.81, SummTable(indices4,:).pcha / 9.81, 'kv', ...
%      [0, 1], polyval(reg1, [0,1]), 'r--', ...
%      [0, 1], polyval(reg2, [0,1]), 'k--', ...
%      [0, 1], [0, 1], 'k--', MarkerSize=6.0), axis([0 1 0 1]), ...
%      xlabel('PCHA (g), Coupled'), ylabel('PCHA (g), Decoupled'), grid on, ...
%      legend('Linear Elastic Bridge', 'Nonlinear Bridge', Location='northwest')
% % saveas(gcf, 'pcha_coupled_model.pdf')























