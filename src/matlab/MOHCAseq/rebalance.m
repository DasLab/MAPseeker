function [ r_weight, r_rebal ] = rebalance( r_unbias, r_bias, output_file )
%  [ r_weight, r_rebal ] = rebalance( r_unbias, r_bias, output_file )
%
% Function to accept oligo-C' (unbiased) and AMPure XP (biased) purified 
% COHCOA-analyzed raw counts from MAPseeker analysis of MOHCA-seq data 
% and combine them.
% 
% INPUTS:
%       r_unbias = rdat or structure array containing raw counts from sequencing of oligo-C' purified sample 
%         r_bias = rdat or structure array containing raw counts from sequencing of AMPure XP purified sample 
%    output_file = [optional] filename for RDAT output.
%
% OUTPUTS:
%       r_weight = rdat containing rebalanced raw counts, to be input to COHCOA analysis
%       
% Clarence Cheng, 05-06/2014
%


%% Setup
% Read in RDAT file to structure arrays
if ischar( r_unbias );  r_un = read_rdat_file(r_unbias); else r_un = r_unbias; end
if ischar( r_bias );    r_bi = read_rdat_file(r_bias);   else r_bi = r_bias;   end

% Get data and other parameters from structure arrays
[D_un, D_un_err, seqpos_un, ligpos_un] = get_data( r_un );
[D_bi, D_bi_err, seqpos_bi, ligpos_bi] = get_data( r_bi );

if size(D_un) ~= size(D_bi)
    fprintf('Sizes of input datasets must match!\n');
    return;
end


%% Prepare the data and calculate ratios for rebalancing
% Collect data at each sequence separation and calculate means, ratios
diagavg{1} = get_diagonals( D_un );
diagavg{2} = get_diagonals( D_bi );

% Take ratios directly
for seqsep = 1:size(D_un,1)-1
    diagrat(seqsep) = diagavg{2}(seqsep)/diagavg{1}(seqsep);
end

% Bin, then take ratios
diagavg_bin = {};
limits = [0 50 100 200 size(D_un,1)];   % set boundaries for splitting bin sizes
numBins = [50 25 20 ceil((size(D_un,1)-200)/10)];           % set numbers of bins within each pair of boundaries
for k = 1:2
    for i = 1:length(limits)-1
        binEdges = linspace(limits(i), limits(i+1), numBins(i)+1);  % define bin edges within each pair of boundaries
        [h, whichBin] = histc(1:length(diagavg{k}), binEdges);
        for j = 1:numBins(i)
            flagBinMembers = (whichBin == j);
            binMembers = diagavg{k}(flagBinMembers);                % collect the values in each bin
            binMembers = remove_nans(binMembers);
            diagavg_bin{k}(flagBinMembers) = mean(binMembers);      % set all the values in each bin to the average of the bin
        end
    end
end

for seqsep = 1:size(D_un,1)-1
    diagrat_bin(seqsep) = diagavg_bin{2}(seqsep)/diagavg_bin{1}(seqsep);
end

diagavg{1} = remove_nans(diagavg{1});       % remove NaN values (arise from non-square data matrices)
diagavg{2} = remove_nans(diagavg{2});
diagavg_bin{1} = remove_nans(diagavg_bin{1});
diagavg_bin{2} = remove_nans(diagavg_bin{2});
diagrat = remove_nans(diagrat);
diagrat_bin = remove_nans(diagrat_bin);


%% Rebalance the biased data and combine with unbiased data using a weighted mean
seprng = 1:length(diagrat);
maxrat = max(diagrat_bin);

D_rebal = D_bi*0;
for i = 1:size(D_bi,1)
    for j = 1:size(D_bi,2)
        sep = abs(i-j);
        if sep >= 1 && sep <= max(seprng)

	    % Use values of ratios from binned and averaged diagonal signals.
            D_rebal(i,j) = maxrat / diagrat_bin(sep) * D_bi(i,j);
            D_rebal_err(i,j) = maxrat / diagrat_bin(sep) * D_bi_err(i,j);

        end
    end
end

% Calculate weighted mean of oligo-C' and rebalanced AMPure data
[D_weight, D_weight_err] = get_weighted_mean( D_un, D_rebal, D_un_err, D_rebal_err );

% Create rdats from biased-rebalanced and final-rebalanced data
base_name = strrep(r_bi.name, 'TrueAm', '')
r_rebal = make_rdat_structure( D_rebal, D_rebal_err, r_bi, [base_name, '_Rebalanced'] );
r_weight = make_rdat_structure( D_weight, D_weight_err, r_bi, [base_name, '_CombinedRebalanced'] );


%% Plot everything and output to files
mkdir( 'Rebalance' );

% Collect data at each sequence separation of rebalanced data and calculate means, ratios
diagavg{3} = get_diagonals( D_rebal );
diagavg{3} = remove_nans(diagavg{3});
diagavg{4} = get_diagonals( D_weight );
diagavg{4} = remove_nans(diagavg{4});

% Plot average signal per diagonal versus sequence separation
figure; hold on;
set(gcf, 'PaperPositionMode','auto','color','white');
scatter(1:1:length(diagavg{1}), diagavg{1}, 'MarkerEdgeColor', 'b');
scatter(1:1:length(diagavg{2}), diagavg{2}, 'Fill', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b');
scatter(1:1:length(diagavg_bin{1}), diagavg_bin{1}, 'MarkerEdgeColor', 'r');
scatter(1:1:length(diagavg_bin{2}), diagavg_bin{2}, 'Fill', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r');
scatter(1:1:length(diagavg{3}), diagavg{3}, 'MarkerEdgeColor', 'k');
scatter(1:1:length(diagavg{4}), diagavg{4}, 'Fill', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k');
set(gca, 'ylim', [-20 300]);
xlabel('Sequence separation');
ylabel('Signal');
title('Signal vs sequence separation');
legend({'Diagonal signal, unbiased','Diagonal signal, biased', ...
        'Binned/averaged diagonal signal, unbiased','Binned/averaged diagonal signal, biased', ...
        'Diagonal signal, rebalanced biased','Diagonal signal, combined rebalanced'});
% print( gcf, '-depsc2', '-loose', '-r300', ['Rebalance/',base_name,'_SignalvsSeqsep']);
% fprintf( ['Created: ', ['Rebalance/',base_name,'_SignalvsSeqsep'], '\n'] );

% Plot ratios of signal versus sequence separation
figure; hold on; set(gcf, 'PaperPositionMode','auto','color','white');
plot(1:1:length(diagrat), diagrat, 'color', 'b');
plot(1:1:length(diagrat_bin), diagrat_bin, 'color', 'r');
xlabel('Sequence separation');
ylabel('Ratio of biased/unbiased signal');
title('Ratio of signal vs sequence separation');
print( gcf, '-depsc2', '-loose', '-r300', ['Rebalance/',base_name,'_RebalanceCurve']);
fprintf( ['Created: ', ['Rebalance/',base_name,'_RebalanceCurve'], '\n'] );

% Plot raw counts in 2D
mohcaplot(D_un/10, seqpos_un, ligpos_un, {'Unbiased: oligo-C´ bead purification'; r_un.name}, 15, '', ['Rebalance/',base_name,'_Unbiased']);
mohcaplot(D_bi/10, seqpos_bi, ligpos_bi, {'Biased: AMPure XP bead purification'; r_bi.name}, 15, '', ['Rebalance/',base_name,'_Biased']);
% mohcaplot(D_rebal/10, seqpos_bi, ligpos_bi, {'Biased: Rebalanced w/ratios of binned and averaged data'; r_rebal.name}, 15);
mohcaplot(D_weight/10, seqpos_bi, ligpos_bi, {'Weighted mean of unbiased and rebalanced biased data'; r_weight.name}, 15, '', ['Rebalance/',base_name,'_CombinedRebalanced']);


%% Output to file
if exist(  'output_file' )
  fprintf( ['Outputting rebalanced data (using ratios of binned and averaged signal) to', output_file,'.\n' ] );
  output_rdat_to_file( output_file, r_weight );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [D, D_err, seqpos, ligpos] = get_data( r )
D = r.reactivity;
D_err = r.reactivity_error;
seqpos = r.seqpos;
ligpos = get_ligpos(r);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function diagavg = get_diagonals( D );
for seqsep = 1:size(D,1)-1
    diagmat{seqsep} = diag(D,seqsep);
    diagavg(seqsep) = mean(diagmat{seqsep});
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function d_noNans = remove_nans( d_Nans )
d_noNans = d_Nans(~isnan(d_Nans));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [D_weight, D_weight_err] = get_weighted_mean( D_un, D_rebal, D_un_err, D_rebal_err );
weight_un = max( 1 ./ D_un_err.^2, 0 );
weight_rebal = max( 1 ./ D_rebal_err.^2, 0 );
D_weight_sum = D_un .* weight_un + D_rebal .* weight_rebal;
D_weight = D_weight_sum ./ (weight_un + weight_rebal);
D_weight_err = sqrt( 1 ./ (weight_un + weight_rebal) );
D_weight(find(isnan(D_weight))) = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function r_new = make_rdat_structure( D, D_err, r, name );
r_new = r;
r_new.reactivity = D;
r_new.reactivity_error = D_err;
r_new.name = name;


