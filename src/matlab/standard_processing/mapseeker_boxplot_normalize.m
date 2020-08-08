function  [D_norm,D_norm_err,scalefactor] = mapseeker_boxplot_normalize( D, D_err );
%  [D_norm,D_norm_err,scalefactor] = mapseeker_boxplot_normalize( D, D_err );
%
% (C) R. Das, 2012-2020

D_norm = D;
D_norm_err = D;
scalefactor = NaN;

[~, scalefactors] = mapseeker_boxplot_normalize_separate_rows( D );
scalefactors = scalefactors( find( scalefactors ) > 0 );
scalefactor = median( scalefactors  );
if ~isnan( scalefactor ) & scalefactor > 0
    D_norm = D / scalefactor;
    D_norm_err = D_err / scalefactor;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [d_norm, scalefactor] = mapseeker_boxplot_normalize_separate_rows( d_for_scalefactor )
% copy of boxplot_normalize from HiTRACE -- included here for completeness

cap_value = 999;
d_norm = d_for_scalefactor;
scalefactor = zeros(1, size( d_for_scalefactor,2) );
for k = 1:size( d_for_scalefactor, 2 )
    d_OK = d_for_scalefactor(:,k);
    d_OK = d_OK( find( ~isnan( d_OK ) ) );
    d_OK = d_OK( find( d_OK ~= 0 ) );
    dsort = sort( d_OK );
    
    if ( length( dsort ) < 4 ) continue; end
    
    % this attempts to recover the normalization scheme in ShapeFinder, as reported by Deigan et al., 2008.
    q1 = dsort( round( 0.25*length(dsort) ) );
    q3 = dsort( round( 0.75*length(dsort) ) );
    interquartile_range = abs( q3 - q1 );
    
    % test -- based on definition of matlab box().
    outlier_cutoff = min( find( dsort > (q3 + 1.5*interquartile_range ) ) );
    
    %[outlier_cutoff length( dsort ) ]
    if ~isempty( outlier_cutoff )
        actual_cutoff = outlier_cutoff - 1;
        % for smaller RNAs, as described in Deigan et al., 2009.
        if length( dsort ) < 100; actual_cutoff = max( actual_cutoff, round(0.95*length(dsort) ) - 1 ); end;
        cap_value = dsort( actual_cutoff+1 );
        dsort = dsort(1: actual_cutoff );
    end
    
    % Take top 10th percentile of values after removing outliers
    scalefactor(k) = mean(dsort(  round( 0.9 * length(dsort)):end ) );
    
    d_norm(:,k) = d_for_scalefactor(:,k) / scalefactor(k);
end
