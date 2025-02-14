function [Q_out, Q_out_err, R, B, F, F_fit, A] = cohcoa_classic( r, rfilename, NUM_CYCLES );
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
set( gcf,'position', [100 100 1000 600]);

rho = 2.5; % rho = factor to correct ?OH cleavage to ?OH RT-stopping damage; surprisingly little dependence on rho from 1-5
if ~exist( 'NUM_CYCLES' ); NUM_CYCLES = 40; end; % number of iteration cycles.
FULL_LENGTH_LIGATION_CORRECTION = 4; % surprisingly little dependence on this (except overall scaling).
OVERALL_SCALING = 2; % overall counts.
INCREMENT_PER_CYCLE = 0.1; % how much to update on each iteration. [max is 1.0; keep low for smooth convergence]
QFUDGE = 1.0; % 1.0 means no fudge. Keep this at 1.0.

SIGNAL_TO_NOISE_FILTER_CUTOFF = 1.5; % relative error should be better than this number

USE_OUTLIER_FILTER_FOR_PLAID = 1; % in estimating background normalization, don't fit everything (allow outliers)
PERCENTILE_CUT = 0.1; % in estimating background normalization for each row, what fraction of values to ignore as outliers
UNDERSHOOT_PLAID = 1; % can have a big effect... ignore high deviations -- force background R*B to be lower than signal.

REFIT_R = 1; % If 0, keep constant based on reference row. Better to update!
SPARSIFY = 0; % Explicitly keep only strongest hits in estimating Q. Not necessary
SPARSITY_HITS_PER_RES = 20; % This (times N) is number of strong hits to keep in Q, if sparsifying

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
image_scaling = 30/mean( mean( F)); % for plotting

[ F_correct, F_correct_err ] = determine_corrected_reactivity( F, 1.0);

% get rid of NaNs too
ref_row = N - 1; % kind of arbitrary. Need a row where there won't be any contact map hits.
R = max( F_correct( 1:N, ref_row), 0 );

% Tighten fit range if desired.
fit_range = [1:N];
%fit_range = [10:N-10];
F = F( fit_range, fit_range );
N = length( fit_range );
R = R( fit_range );

% initial conditions
B = 0 * R; 
R_init = R;
Q = zeros( N, N );
[A,A_err] = get_attenuation_matrix( R, B, Q, 0*Q, rho );
Q_out = zeros(N,N);
Q_out_err = zeros(N,N);

seqsep = figure_out_seqsep( F ); % typically 5 for miseq; 14 for hiseq.

% Main loop
for q = 1 : NUM_CYCLES

  fprintf( 'Starting iteration: %d of %d\n', q, NUM_CYCLES );
  F_attcorrect = F ./ A;
  F_attcorrect_err = F_err ./ A;
  F_attcorrect_subcontact = max( F_attcorrect - Q, 0);
  
  % Let's create plaid 'background' matrix
  [ R, B, F_plaid ] = estimate_plaid_background( F_attcorrect_subcontact, B, R, R_init, seqsep, USE_OUTLIER_FILTER_FOR_PLAID, UNDERSHOOT_PLAID, PERCENTILE_CUT, REFIT_R );
    
  Q = F_attcorrect - F_plaid;
  Q_out = Q;
  Q_out_err = sqrt( (F_err./F).^2 + (A_err./A).^2 ) .* (F ./ A);
  
  Q_filter = smooth2d(Q_out,2);
  Q_filter( abs(Q_out./Q_out_err) < SIGNAL_TO_NOISE_FILTER_CUTOFF ) = 0;

  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % smooth & threshold [for attenuation correction]
  %Q = smooth2d( Q, 2 );
  
  % sparsity constraint
  % Assume each residue can hit ~10 other residues.
  if SPARSIFY; 
    Q_out_laidout = reshape( Q_out, 1, N*N);
    [dummy, sortidx ] = sort( Q_out_laidout, 'descend' );
    Q_contact = 0 * Q;
    N_hits = SPARSITY_HITS_PER_RES * N;
    Q_contact( sortidx(1:N_hits) ) = Q( sortidx(1:N_hits) );    % take N strongest hits
    Q = Q_contact;  
  end

  Q( [1:BLANK_FLANK], : ) = 0;      % set flanks to 0
  Q( :, [N- BLANK_FLANK:N] ) = 0;
    
  Q = max( Q, 0 ) * QFUDGE;  
  Q_err = Q_out_err; % F_err ./ A;

  [A_new, A_err] = get_attenuation_matrix( R, B, Q, Q_err, rho );

  A_old = A;
  A = INCREMENT_PER_CYCLE * A_new + (1 - INCREMENT_PER_CYCLE) * A_old;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  colormap( 1 - gray(100));
  subplot(2,3,1); set(gca,'position',[0.05 0.55 0.3 0.4] );

  Q_scaling = figure_out_Q_scaling( Q );
  image( seqpos, ligpos, Q_scaling * Q_out' ); axis image;
  title( 'Q' );

  subplot(2,3,4);  set(gca,'position',[0.05 0.05 0.3 0.4] );
  image( image_scaling * ( F_plaid)' );   title( 'F_{plaid}'); axis image
  %image( seqpos, ligpos, -Q_scaling * Q_filter' ); axis image;
  %title( sprintf('Q_{filter} (S/N > %3.1f )', SIGNAL_TO_NOISE_FILTER_CUTOFF) );
  %image( Q_scaling * Q_out_err' );
  %title( 'Q_{ERROR}' );

  %image( Q_scaling * -Q_out' );
  %title( '-Q [should be low]' );
  
  subplot(2,3,2);  set(gca,'position',[0.35 0.55 0.3 0.4] ); 
  image( seqpos, ligpos, image_scaling * F' ); axis image;
  title( 'Input data' );

  subplot(2,3,5);  set(gca,'position',[0.35 0.05 0.3 0.4] );
  F_fit = A_old .* ( F_plaid + Q );
  image( seqpos, ligpos, image_scaling * F_fit'  ); axis image;
  title( 'Fit: [ plaid + Q ], with attenuation' );

  subplot(2,3,3);  set(gca,'position',[0.70 0.55 0.3 0.4] );
  F_reactivity = determine_corrected_reactivity( F );
  reactivity_scaling = 2 * figure_out_Q_scaling( F_reactivity );
  image( seqpos, ligpos, reactivity_scaling * F_reactivity'); axis image;
  title( 'Data, conventional attenuation correction' );

  subplot(2,3,6);  set(gca,'position',[0.70 0.05 0.3 0.4] );  
  image( reactivity_scaling * ( (F ./ A_old) ./ repmat( B, 1, N )' )' );  axis image;
  title( 'Data, COHCOA attenuation corrected');

  drawnow;

  %pause;
%  if ( mod(q,10) == 0 ) pause; end;
end

if length(rfilename) > 0;
  outfilename = get_cohcoa_filename( rfilename );
  outdir = dirname( outfilename );
  if ~exist( ['./',outdir], 'dir' ); mkdir( outdir ); end;
  
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Try to fit a 2D ditribution to product of two 1D distributions.
function [ R, B, F_plaid ] = estimate_plaid_background( F_attcorrect_subcontact, B, R, R_init, ...
						  seqsep, USE_OUTLIER_FILTER_FOR_PLAID,...
						  UNDERSHOOT_PLAID, PERCENTILE_CUT, REFIT_R );


N = size( F_attcorrect_subcontact, 1 );

niter = 1;
for n = 1 : niter
  for i = 1:N
    normbins = [2: max( i-seqsep, 3 )];
    %normbins = [2: i-5];
    if USE_OUTLIER_FILTER_FOR_PLAID
      B(i) = get_scalefactor_filter_outliers( F_attcorrect_subcontact(normbins,i), ...
					      R( normbins), ...
					      PERCENTILE_CUT, UNDERSHOOT_PLAID );
    else
      B(i) = mean( F_attcorrect_subcontact(normbins,i) ) / mean(R( normbins ));
    end
  end
  B = get_rid_of_infinities( B );  
  
  if REFIT_R
    R_new = 0 * R;
    for i = 1:N
      %normbins = [(i+3):(N)];
      normbins = [(i+seqsep):(N)];  % why so sensitive to i+3 vs. i+5?
      if USE_OUTLIER_FILTER_FOR_PLAID
	R_new(i) = get_scalefactor_filter_outliers( F_attcorrect_subcontact(i,normbins)', ...
						    B( normbins ), ...
						    PERCENTILE_CUT, UNDERSHOOT_PLAID );
      else
	R_new(i) = mean(F_attcorrect_subcontact(i,normbins)) / mean(B( normbins ));
      end     	
    end
    R = get_rid_of_infinities( R );  
    R = max( R_new, 0);
    R( (N-seqsep) : N ) = R(N - seqsep - 1); % clean up -- R at end is not defined.
    
    % degeneracy in product -- R*B. Set scaling so that R matches R_init.	    
    normbins = [ seqsep : (N-seqsep - 1)];
    alpha = mean( R_init( normbins) ) / mean( R(normbins) );
    R = R * alpha;
    B = B / alpha;
    R(1) = 1.0;
    
  end
end

F_plaid = R * B';
for i = 1:N;  F_plaid( [ max(i-seqsep,1) : end], i ) = 0.0;  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if data are zero in a row or column
%  can get spurious infinities.
%
% reset those values to mean of non-infinite values
%
function B = get_rid_of_infinities( B );  
B( find( isinf(B)) ) = mean( B( find( ~isinf( B ) ) ) );
