function [Q_out, Q_out_err, R, B, F, F_fit, A] = cohcoa( r, rfilename );
% [Q_out, R, B, F, F_fit, A] = cohcoa( r );
%
%  Iterative fitting of two-point correlation function
%   for MOHCA-seq data. Using general 'MOHCA-X' framework
%   where two-point map is anything beyond boring outer product
%   of 1D stop & 1D cleavage functions ['plaid' background].
%  [Iteration required due to complications in estimating
%    reverse transcription attenuation]
%
% INPUT:
%  r = rdat object or name of rdat file
%
% OUTPUT:
%  Q_out     = two-point correlation function
%  Q_out_err = estimated error on two-point correlation function
%  R         = 1D stop probability
%  B         = 1D cleavage probability
%  F         = Data (after normalizing to total)
%  F_fit     = Fitted data
%  A         = Attenuation matrix. F_fit = [(R * B) + Q] .* A.
%
% (C) Das lab, Stanford, 2013
%

if ~exist( 'rfilename' ) rfilename = ''; end;
if ischar( r ) & ~isstruct( r );  
  rfilename = r;
  r = read_rdat_file( r ); 
end

seqpos = r.seqpos;
ligpos = str2num(char(get_tag( r, 'lig_pos' )));

rho = 2.5; % surprisingly little dependence on rho
NUM_CYCLES = 40; % number of iteration cycles.
FULL_LENGTH_LIGATION_CORRECTION = 5; % surprisingly little dependence on this (except overall scaling).
OVERALL_SCALING = 0.5; % overall counts.
INCREMENT_PER_CYCLE = 0.1; % how much to update on each iteration. [max is 1.0; keep low for smooth convergence]
QFUDGE = 1.0; % 1.0 means no fudge. Keep this at 1.0.

SIGNAL_TO_NOISE_FILTER_CUTOFF = 1.5; % relative error should be better than this number

USE_OUTLIER_FILTER_FOR_PLAID = 1; % in estimating background normalization, don't fit everything (allow outliers)
PERCENTILE_CUT = 0.1; % in estimating background normalization for each row, what fraction of values to ignore as outliers
UNDERSHOOT_PLAID = 1; % can have a big effect... ignore high deviations -- force background R*B to be lower than signal.

REFIT_R = 1; % If 0, keep constant based on reference row. Better to update!
SPARSIFY = 1; % Explicitly keep only strongest hits in estimating Q. Not necessary
SPARSITY_HITS_PER_RES = 5; % This (times N) is number of strong hits to keep in Q, if sparsifying

BLANK_FLANK = 5; % suppress Q to zero at this many residues at 5' and 3' ends.
set(gcf, 'PaperPositionMode','auto','color','white');
clf;

D = r.reactivity;
D_err = r.reactivity_error;

F = D/sum(sum(D))/OVERALL_SCALING;
F_err = D_err/sum(sum(D))/OVERALL_SCALING;

N = size( D, 2 );
F = F(1:N,1:N);
F_err = F_err(1:N,1:N);

% this sets overall scale of 'reactivity' R, which is stopping probability here.
F(1,:) = F(1,:) * FULL_LENGTH_LIGATION_CORRECTION;
F_err(1,:) = F_err(1,:) * FULL_LENGTH_LIGATION_CORRECTION;

[ F_correct, F_correct_err ] = determine_corrected_reactivity( F, 1.0);
image_scaling = 30/mean( mean( F_correct )); % for plotting

% get rid of NaNs too
ref_row = N - 1; % kind of arbitrary. Need a row where there won't be any contact map hits.
R = max( F_correct( 1:N, ref_row), 0 );

% Tighten fit range if desired.
fit_range = [1:N];
%fit_range = [10:N-10];
F = F( fit_range, fit_range );
F_correct = F_correct( fit_range, fit_range );
N = length( fit_range );
R = R( fit_range );

% initial conditions
B = sum( F, 1 );
%plot( B ); ylim([0 0.1]);pause
Bgrid = repmat( B, N, 1 );

R_init = R;
Q = zeros( N, N );
[A,A_err] = get_Q_over_R_attenuation_matrix( R, B, Q, 0*Q, rho );
Q_out = zeros(N,N);
Q_out_err = zeros(N,N);

seqsep = figure_out_seqsep( F ); % typically 5 for miseq; 14 for hiseq.

% Main loop
for q = 1 : NUM_CYCLES

  fprintf( 'Starting iteration: %d of %d\n', q, NUM_CYCLES );
  F_attcorrect = F_correct ./ A;
  F_attcorrect_err = F_correct_err ./ A;
  F_attcorrect_sub = F_attcorrect - (Q ./ Bgrid);
  
  Q = [];
  for j = 1:N
    Q(:,j) = ( F_attcorrect(:,j) - R ) * B(j);
  end
  Q = zero_out( Q, seqsep );

  if REFIT_R; R = estimate_R( F_attcorrect_sub, seqsep ); end;

  Q( [1:BLANK_FLANK], : ) = 0;
  Q( :, [N- BLANK_FLANK:N] ) = 0;
 
  Q_out = Q;
  Q_out_err = sqrt( (F_err./F).^2 + (A_err./A).^2 ) .* (F ./ A);
  
  Q_filter = smooth2d(Q_out,2);
  Q_filter( abs(Q_out./Q_out_err) < SIGNAL_TO_NOISE_FILTER_CUTOFF ) = 0;
    
  % sparsity constraint
  % Assume each residue can hit ~10 other residues.
  if SPARSIFY; 
    Q_out_laidout = reshape( Q_out, 1, N*N);
    [dummy, sortidx ] = sort( Q_out_laidout, 'descend' );
    Q_contact = 0 * Q;
    N_hits = SPARSITY_HITS_PER_RES * N;
    Q_contact( sortidx(1:N_hits) ) = Q( sortidx(1:N_hits) );
    Q = Q_contact;  
  end

  Q = max( Q, 0 ) * QFUDGE;  

  Q = smooth2d(Q);
  Q_err = Q_out_err; % F_err ./ A;

  [A_new,A_err] = get_Q_over_R_attenuation_matrix( R, B, Q, 0*Q, rho );

  A_old = A;
  A = INCREMENT_PER_CYCLE * A_new + (1 - INCREMENT_PER_CYCLE) * A_old;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  colormap( 1 - gray(100));
  subplot(2,2,1); set(gca,'position',[0.05 0.55 0.4 0.4] );

  Q_scaling = figure_out_Q_scaling( Q );
  image( seqpos, ligpos, Q_scaling * Q_out' );
  title( 'Q' );

  subplot(2,2,2);  set(gca,'position',[0.55 0.55 0.4 0.4] );
  image( seqpos, ligpos, Q_scaling * Q_filter' );
  title( sprintf('Q_{filter} (S/N > %3.1f )', SIGNAL_TO_NOISE_FILTER_CUTOFF) );
  %image( Q_scaling * Q_out_err' );
  %title( 'Q_{ERROR}' );

  %image( Q_scaling * -Q_out' );
  %title( '-Q [should be low]' );

  subplot(2,2,3);  set(gca,'position',[0.05 0.05 0.4 0.4] );
  image( seqpos, ligpos, image_scaling * F_correct' );
  title( 'Input data' );

  subplot(2,2,4);  set(gca,'position',[0.55 0.05 0.4 0.4] );
  %plot( seqpos(1:N), [rho * Q( :, [170 190])] ) ; ylim([0 0.2]);
  %plot( seqpos(1:N), [R , R.*A_new( :, [164]),  R.*A_new(:,195)] ) ; ylim([0 0.2]);pause;
  %plot( seqpos(1:N), [ F_attcorrect( :, [164 190]), R] ) ; ylim([0 0.2]); pause;
  F_fit = A_new .* ( zero_out( repmat( R, 1, N), seqsep ) + (Q ./ Bgrid) );
  image( seqpos, ligpos, image_scaling * F_fit'  );
  title( 'Fit: [ plaid + Q ], with attenuation' );

  drawnow;

  %pause;
%  if ( mod(q,10) == 0 ) pause; end;
end

if length(rfilename) > 0;
  outfilename = get_cohcoa_filename( rfilename );
  outdir = dirname( outfilename );
  if ~exist( outdir, 'dir' ); mkdir( outdir ); end;
  
  r.reactivity = Q_scaling * Q_out;
  r.reactivity_error = Q_scaling * Q_out_err;
  r.seqpos = r.seqpos( fit_range );
  r.data_annotations = r.data_annotations( fit_range );
  r.annotations = [r.annotations, sprintf('scaling:%f',Q_scaling) ];
  output_rdat_to_file( outfilename, r );

  print( [outfilename, '.eps'], '-depsc2' );
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function seqsep = figure_out_seqsep( F );
N = size( F, 1 );
seqsep_min = 5;
seqsep_max = 20;
f_near_diag = zeros( 1, seqsep_max );
for i = 1 : (N - seqsep_max)
  f_near_diag = f_near_diag + F( i, i+ [1:seqsep_max]);    
end
clf
cutoff = 0.2 * f_near_diag( end );
seqsep = min( find( f_near_diag > cutoff ) );
seqsep = max( seqsep, seqsep_min );
%plot( f_near_diag );
%pause;

if ( seqsep > seqsep_min ) fprintf( 'WARNING -- minimum insert length looks like %d\n', seqsep_min ); end;

%if seqsep > 10; seqsep = 17; end; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Q = zero_out( Q, seqsep );

N = size( Q, 1 );
for i = 1:N
  for j = 1:min( i+seqsep, N )
    Q(i,j) = 0.0;
  end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function R = estimate_R( F_attcorrect_subcontact, seqsep );
N = size( F_attcorrect_subcontact, 1 );
R = ones(N,1);
for i = 1:N
  %for j = ( i+seqsep: N )
  %plot( F_attcorrect_subcontact(i,: ) ); pause;
  %end
  d = F_attcorrect_subcontact(i, (i+seqsep:N) ) ;
  R(i) = mean(d);
end
