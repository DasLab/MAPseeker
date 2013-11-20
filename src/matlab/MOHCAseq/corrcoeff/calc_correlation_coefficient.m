function [c,chi2] = calc_correlation_coefficient( r, Qpred, seqpos_Q, D_out );
% [c,chi2] = calc_correlation_coefficient( r, Qpred, seqpos_Q, D_out );
%
% Inputs:
%  r        = rdat object
%  Qpred    = predicted secondary contact map (from get_Qpred )
%  seqpos_Q = sequence positions that go with Qpred 
%  D_out    = [optional] predicted primary contact map, linear combination with Qpred will be fit to data.

if ~exist( 'D_out', 'var' )
  D_out = 0 * Qpred;
end
D = r.reactivity;

SEQSEP = 4;
%SEQSEP = 7;

N = size( r.reactivity,2);
ligpos = str2num( char(get_tag( r, 'lig_pos' )) );
seqpos = r.seqpos;

data2d = max(r.reactivity,0);
data2d = smooth2d(data2d);
err2d = r.reactivity_error;

data = [];
data_err = [];
pred = [];
for i = 1:N
  for j = (i+SEQSEP):N
    i_Q = find( seqpos(i) == seqpos_Q );
    j_Q = find( ligpos(j) == seqpos_Q );
    if ~isempty( i_Q ) & ~isempty( j_Q ) & r.reactivity(i,j) > 0 & Qpred(i_Q,j_Q)>0
      data     = [ data; data2d(i,j) ];
      data_err = [ data_err; err2d(i,j)]; 
      pred     = [ pred; Qpred(i_Q,j_Q), D_out(i_Q,j_Q) ]; 
    end
  end
end

X = lsqnonneg( pred, data );
fit = pred * X;

chi2 = mean((fit - data ).^2 ./data_err.^2 )

%plot( [data, fit] );
c = corrcoef( [data,fit] );
c = c(1,2)

scalefactor = 10/mean(mean(max(r.reactivity',0)));
image( seqpos, ligpos, r.reactivity' * scalefactor );

fit2d = scalefactor * ( Qpred * X(1) + D_out * X(2) );
fit2d = smooth2d( fit2d );

hold on
contour_levels = [80,40];
colorcode = [1 0 1; 0 0 1];
for i = 1:length( contour_levels )
  contour(seqpos_Q, seqpos_Q, fit2d', ...
	  contour_levels(i) * [1 1],...
	  'color',colorcode(i,:),...
	  'linewidth',0.5 );
end


colormap( 1 - gray(100))