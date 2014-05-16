function [D_un, D_bi, avg_r] = rebalance( unbias_r, bias_r )

% Function to accept oligo-C' (unbiased) and AMPure XP (biased) purified 
% COHCOA-analyzed raw counts from MAPseeker analysis of MOHCA-seq data 
% and combine them.
% 
% INPUTS:
%       unbias_r = rdat or structure array containing raw counts from sequencing of oligo-C' purified sample 
%       bias_r   = rdat or structure array containing raw counts from sequencing of AMPure XP purified sample 
%
% OUTPUTS:
%       avg_r    = rdat containing rebalanced raw counts, to be input to COHCOA analysis
%       
% Clarence Cheng, May 2014
%

%%%%% SHOULD ADD IN PROPER ERROR PROPAGATION THROUGH CALCULATIONS/REBALANCING  


%% Setup
figure(1);     % preload a figure for later plots

% Read in RDAT file to structure arrays
if ischar( unbias_r );  r_un = read_rdat_file(unbias_r); else r_un = unbias_r; end
if ischar( bias_r );    r_bi = read_rdat_file(bias_r);   else r_bi = bias_r;   end

% Get data and other parameters from structure arrays
D_un = r_un.reactivity;
D_un_err = r_un.reactivity_error;
seqpos_un = r_un.seqpos;
ligpos_un = get_ligpos(r_un);

D_bi = r_bi.reactivity;
D_bi_err = r_bi.reactivity_error;
seqpos_bi = r_bi.seqpos;
ligpos_bi = get_ligpos(r_bi);

% Use mohcaplot to plot data
% D_un_filt = prepdata(D_un, D_un_err);
% D_bi_filt = prepdata(D_bi, D_bi_err);
mohcaplot(D_un/10, seqpos_un, ligpos_un, {'Unbiased: oligo-C'' bead purification'; r_un.name}, 15);
mohcaplot(D_bi/10, seqpos_bi, ligpos_bi, {'Biased: AMPure XP bead purification'; r_bi.name}, 15);

if size(D_un) ~= size(D_bi)
    fprintf('Sizes of input datasets must match!\n');
    return;
end


%% Prepare the data
% Collect data at each sequence separation and calculate means, ratios
for seqsep = 1:size(D_un,1)-1
    mat{1}{seqsep} = diag(D_un,seqsep);
    matavg{1}(seqsep) = mean(mat{1}{seqsep});
end
for seqsep = 1:size(D_bi,1)-1
    mat{2}{seqsep} = diag(D_bi,seqsep);
    matavg{2}(seqsep) = mean(mat{2}{seqsep});
end
for seqsep = 1:size(D_un,1)-1
    matrat(seqsep) = matavg{2}(seqsep)/matavg{1}(seqsep);
    matratinv(seqsep) = matavg{1}(seqsep)/matavg{2}(seqsep);
%     matdif(seqsep) = matavg{2}(seqsep)-matavg{1}(seqsep);
end
matavg{1} = matavg{1}(~isnan(matavg{1}));       % remove NaN values (arise from non-square data matrices)
matavg{2} = matavg{2}(~isnan(matavg{2}));
matrat = matrat(~isnan(matrat));
matratinv = matratinv(~isnan(matratinv));
% matdif = matdif(~isnan(matdif));

% Plot averaged signal versus sequence separation
figure(1); hold on; set(gcf, 'PaperPositionMode','auto','color','white');
col = [rand rand rand];
scatter(1:1:length(matrat), matavg{1}, 'MarkerEdgeColor', col);
scatter(1:1:length(matrat), matavg{2}, 'Fill', 'MarkerEdgeColor', col, 'MarkerFaceColor', col);
% plot(1:1:length(matrat), matrat, 'color', 'b');
% plot(1:1:length(matrat), matratinv, 'color', 'g');
% plot(1:1:length(matrat), matdif, 'color', 'r');
set(gca, 'ylim', [-20 150]);
xlabel('Sequence separation');
ylabel('Signal');
title('Signal vs sequence separation');


%% Fit the data and rebalance
% Fit with double exponential (gives the best fit)
seprng = 1:length(matrat);
[fit2exp, gof, stats] = fit( seprng', matrat', 'exp2');
figure; plot(fit2exp, seprng, matrat); xlabel('Sequence separation'); ylabel('Signal ratio (oligo-C''/AMPure)');
% % Sigmoidal (gives poorer fit than double exponential)
% fittyp = fittype( 'A/(B+exp(C*-x))', 'dependent', {'y'}, 'independent', {'x'}, 'coefficients', {'A','B','C'});
% [fit_sigmoidal, gof2, stats2] = fit( seprng', matrat', fittyp );
% figure; plot(fit_sigmoidal, seprng, matrat);

% Multiply each pixel by sigmoidal correction factor
coeffs = coeffvalues(fit2exp);
maxrat = coeffs(1);
fitrat = feval(fit2exp, 1:size(D_bi,1));
D_rebal = D_bi*0;
for i = 1:size(D_bi,1)
    for j = 1:size(D_bi,2)
        sep = abs(i-j);
        if sep >= 1 && sep <= max(seprng)
            D_rebal(i,j) = maxrat / fitrat(sep) * D_bi(i,j);
            D_rebal2(i,j) = maxrat / matrat(sep) * D_bi(i,j);
        end
    end
end

% Plot raw counts in 2D
mohcaplot(D_bi/10, seqpos_bi, ligpos_bi, 'Biased, raw', 15);
mohcaplot(D_rebal/10, seqpos_bi, ligpos_bi, 'Rebalanced w/fit, raw', 15);
mohcaplot(D_rebal2/10, seqpos_bi, ligpos_bi, 'Rebalanced w/ratios, raw', 15);
mohcaplot(D_un/10, seqpos_un, ligpos_un, 'Unbiased, raw', 15);
% D_bi_filt = prepdata(D_bi, D_bi_err);
% D_rebal_filt = prepdata(D_rebal, D_bi_err);
% D_rebal2_filt = prepdata(D_rebal2, D_bi_err);
% D_un_filt = prepdata(D_un, D_un_err);
% mohcaplot(D_bi_filt, seqpos_bi, ligpos_bi, 'Biased: filt', 15);
% mohcaplot(D_rebal_filt, seqpos_bi, ligpos_bi, 'Rebalanced w/fit, filt', 15);
% mohcaplot(D_rebal2_filt, seqpos_bi, ligpos_bi, 'Rebalanced, filt', 15);
% mohcaplot(D_un_filt, seqpos_un, ligpos_un, 'Unbiased: filt', 15);


%% Plot the average signal versus sequence separation after rebalancing
% Collect data at each sequence separation and calculate means, ratios
for seqsep = 1:size(D_rebal,1)-1
    mat{3}{seqsep} = diag(D_rebal,seqsep);
    matavg{3}(seqsep) = mean(mat{3}{seqsep});
    mat{4}{seqsep} = diag(D_rebal2,seqsep);
    matavg{4}(seqsep) = mean(mat{4}{seqsep});
end
matavg{3} = matavg{3}(~isnan(matavg{3}));       % remove NaN values (arise from non-square data matrices)
matavg{4} = matavg{4}(~isnan(matavg{4}));       % remove NaN values (arise from non-square data matrices)

% Plot averaged signal versus sequence separation
figure; hold on;
col = [rand rand rand];
col2 = col*0.2;
scatter(1:1:length(matrat), matavg{3}, 'Fill', 'MarkerEdgeColor', col, 'MarkerFaceColor', col);
scatter(1:1:length(matrat), matavg{4}, 'Fill', 'MarkerEdgeColor', col2, 'MarkerFaceColor', col2);
set(gca, 'ylim', [-20 150]);
xlabel('Sequence separation');
ylabel('Signal');
title('Signal vs sequence separation');


%% Combine unbiased and biased-rebalanced data
% Calculate weighted mean of oligo-C' and rebalanced AMPure data
weight_un = max( 1 ./ D_un_err.^2, 0 );
weight_bi = max( 1 ./ D_bi_err.^2, 0 );
D_weight_sum = D_un .* weight_un + D_rebal .* weight_bi;
D_weight = D_weight_sum ./ (weight_un + weight_bi);
D_weight_err = sqrt( 1 ./ (weight_un + weight_bi) );
D_weight(find(isnan(D_weight))) = 0;

D_weight2_sum = D_un .* weight_un + D_rebal2 .* weight_bi;
D_weight2 = D_weight2_sum ./ (weight_un + weight_bi);
D_weight2_err = sqrt( 1 ./ (weight_un + weight_bi) );
D_weight2(find(isnan(D_weight2))) = 0;

mohcaplot(D_weight/10, seqpos_bi, ligpos_bi, 'Weighted mean of rebalanced (w/fit) and unbiased', 15);
mohcaplot(D_weight2/10, seqpos_bi, ligpos_bi, 'Weighted mean of rebalanced (w/ratios) and unbiased', 15);
% D_weight_filt = prepdata(D_weight, D_weight_err);
% D_weight2_filt = prepdata(D_weight2, D_weight2_err);
% mohcaplot(D_weight_filt/10, seqpos_bi, ligpos_bi, 'Weighted mean of rebalanced (w/fit) and unbiased, filt', 15);
% mohcaplot(D_weight2_filt/10, seqpos_bi, ligpos_bi, 'Weighted mean of rebalanced and unbiased, filt', 15);


%% Analyze the final-rebalanced data using COHCOA
% Create rdats from biased-rebalanced and final-rebalanced data
r_rebal = r_bi;
r_rebal2 = r_bi;
r_weight = r_bi;
r_weight2 = r_bi;
r_rebal.reactivity = D_rebal;
r_rebal2.reactivity = D_rebal2;
r_rebal.reactivity_error = D_bi_err;
r_rebal2.reactivity_error = D_bi_err;
r_weight.reactivity = D_weight;
r_weight.reactivity_error = D_weight_err;
r_weight2.reactivity = D_weight2;
r_weight2.reactivity_error = D_weight2_err;
% r_rebal.name = 'A9D; rebal w/fit';
% r_rebal2.name = 'A9D; rebal w/ratios';
% r_weight.name = 'A9D; rebal w/fit + unbiased';
% r_weight2.name = 'A9D; rebal w/ratios + unbiased';

output_rdat_to_file('r_rebal.rdat', r_rebal);
output_rdat_to_file('r_rebal2.rdat', r_rebal2);
output_rdat_to_file('r_weight.rdat', r_weight);
output_rdat_to_file('r_weight2.rdat', r_weight2);

% Apply COHCOA
%%%%% RECOMMENDED to run these separately; need to fix some minor errors in smoothMOHCA running these rdats
% figure;
% smoothMOHCA(r_un);
% smoothMOHCA(r_bi);
% smoothMOHCA(r_rebal);
% smoothMOHCA(r_rebal2);
% smoothMOHCA(r_weight);
% smoothMOHCA(r_weight2);


