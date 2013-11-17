function [D_fit, Qpred_fit, Q, seqpos ] = q_fit( r, epsilon_file, which_res, pdb)
%  fit_primary_map( r, epsilon_file, which_res, pdb )
%
%  r            = rdat (either filename or actual data object will work) from, e.g., COHCOA-processed MOHCAseq data.
%  epsilon_file = file with nt, fraction at nt modified with source 
%  which_res    = window of residues to fit. (leave as [] to use all)
%  pdb          = filename of pdb 
%  
% Note, not using exact-hessians, by default -- can do so by replacing leasqr_Q_fast with leasqr_Q, and
%  uncommenting options with 'Hessian','user-defined' line.
%
% (C) R. Das, Stanford University, 2013
%

set( figure( 1 ),'position',[ 7         418        1327         385] );
MAX_ITER = 500;
gamma = 0.05;
lambda = 0.1;  % 0.05 -- less smooth
JUST_AT_EPSILON = 0;
SPARSITY_NRES = 0; % found it better to not assume sparse.
MIN_Q_DIAG = 10;
DIAG_SEP = 3;
USE_ERRORS = 0;
DERIV_CHECK = 0; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isstruct( r ) & ischar( r );  r = read_rdat_file( r ); end
if ~exist( 'which_res' ) which_res = []; end;

set(gcf, 'PaperPositionMode','auto','color','white');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% zoom in user-defined subset
ligpos = get_ligpos( r );
Q     = r.reactivity( 2:end, 1:end-1);
Q_err = r.reactivity_error( 2:end, 1:end-1);
seqpos = r.seqpos( 2:end );
assert( all( seqpos == ligpos( 1:end-1 )' ) );

% rescale Q_err
if USE_ERRORS
  Q_err( find( isnan( Q_err ) | isinf( Q_err )) ) = 0.0;
  Q_err = Q_err / mean( mean( Q_err ) );
else
  Q_err = 0 * Q_err + 1; % uniform weights
end

clf;
Nrange = [1:length( seqpos ) ];
if ~isempty( which_res )
  Nrange = [];
  for i = 1:length( which_res );    Nrange = [Nrange, find( seqpos == which_res(i) ) ];   end
end

figure(1)
Q = Q(Nrange, Nrange ); 
Q_err = Q_err(Nrange, Nrange );
seqpos = seqpos( Nrange );
N = length( seqpos );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
epsilon_profile = zeros(1,N);
if length( epsilon_file ) > 1
  epsilon = load( epsilon_file );
  for m = 1:length(epsilon);  epsilon_profile( seqpos == epsilon(m,1) ) = epsilon(m,2); end
else
  epsilon_nt = epsilon_file;
  epsilon_profile( strfind( upper(r.sequence( seqpos - r.offset )), epsilon_nt ) ) = 0.01;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize  [OK to zero out]
D = max(Q,0);
for i = 1:N;  for j = 1:i; D(i,j) = D(j,i); end; end;
for i = 1:N;  for j = [max(i-DIAG_SEP,1) : min(i+DIAG_SEP,N)]; D(i,j) = MIN_Q_DIAG; end; end;

figure(1);
subplot( 1,3,1 );
image( 30 * Q' );

subplot( 1,3,2);
Qpred = get_secondary_map( D, epsilon_profile );;
gp = find( Q > 0 );
scalefactor = mean( Q(gp) ) / mean( Qpred(gp));
D = sqrt( scalefactor ) * D; % note scaling.
Qpred = get_secondary_map( D, epsilon_profile );;

image( 30 * Qpred' );


subplot( 1,3,3);
image( 10 * D' );
%drawnow;

% used for sparsity.
D_cutoff  = -1;
if SPARSITY_NRES; [~,D_cutoff]  = sparsify( D, SPARSITY_NRES ); end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% setup for optimization -- need to 'pack' the variables (relevant members of fitted 
% primary contact map) into a vector format
index_into_params = zeros(N,N);
left_idx = []; right_idx = []; params = []; min_params = [];
count_params = 0;
for j = 1:N
  for i = 1:j % hits diagonal
    % epsilon is non-zero where there are sources, e.g. at A's.
    if ( JUST_AT_EPSILON & epsilon_profile(i) == 0 & epsilon_profile(j) == 0 )  continue; end;
    if ( D(i,j) < D_cutoff & ~isnan(Q(i,j)) ) continue; end;
    count_params = count_params + 1;
    left_idx( count_params ) = i; % source position
    right_idx( count_params )= j; % cleavage position
    index_into_params(i,j) = count_params;
    index_into_params(j,i) = count_params;
    params( count_params ) = D(i,j);
    min_params( count_params ) = 0;
  end
end
left_right_idx = [ left_idx; right_idx ];

% strong diagonal.
for j = 1:N 
  for i = max(j-DIAG_SEP,1): min(j+DIAG_SEP,N)
    if ( index_into_params(i,j)>0 ) min_params( index_into_params(i,j) ) = MIN_Q_DIAG; end;
  end
end
params = max( params, min_params );
fprintf( 'Number of fitting parameters: %d\n',length( params ));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do the fit -- this will draw graphics.
[f, g, h] = leasqr_Q_fast( params, index_into_params, left_right_idx, epsilon_profile, Q, Q_err, gamma, lambda, seqpos );

fprintf( 'Running optimizer...\n' );
%A = -1*eye( length(params) ); B = min_params; %zeros( length(params), 1 );
lb = min_params; %ub = 10 * ones( length( params ), 1 );
ub = [];
params_init = max( params, min_params );
%params_init = min_params; % setting to zero

if matlabpool( 'size' ) == 0; matlabpool open 4; end
%options = optimoptions( 'fmincon','GradObj','on','UseParallel','always','MaxIter',MAX_ITER,'Algorithm','interior-point','display','iter' );
%options = optimoptions( 'fmincon','GradObj','on','UseParallel','always','MaxIter',MAX_ITER,'Algorithm','trust-region-reflective','display','iter','Hessian','user-supplied' );
%options = optimoptions( 'fmincon','GradObj','on','UseParallel','always','MaxIter',MAX_ITER,'Algorithm','interior-point','display','iter','Hessian','user-supplied','HessFcn','leasqr_q_hess' ); CALC_HESSIAN = 1;
options = optimoptions( 'fmincon','GradObj','on','UseParallel','always','MaxIter',MAX_ITER,'Algorithm','interior-point','display','iter','Hessian','lbfgs' ); CALC_HESSIAN = 0;
options = optimoptions( 'fmincon','GradObj','on','UseParallel','never','MaxIter',MAX_ITER,'Algorithm','interior-point','display','iter','Hessian','lbfgs' ); CALC_HESSIAN = 0;
%options = optimoptions( 'fmincon','GradObj','on','UseParallel','always','MaxIter',MAX_ITER,'Algorithm','interior-point','display','iter','Hessian',{'lbfgs',20} ); CALC_HESSIAN = 0;
%options = optimoptions( 'fmincon','GradObj','on','UseParallel','always','MaxIter',MAX_ITER,'Algorithm','sqp','display','iter' ); CALC_HESSIAN = 0;
%options = optimoptions( 'fmincon','GradObj','on','UseParallel','always','MaxIter',MAX_ITER,'Algorithm','trust-region-reflective','display','iter' ); CALC_HESSIAN = 0;
%options = optimoptions( 'fmincon','GradObj','on','UseParallel','always','MaxIter',MAX_ITER,'Algorithm','active-set','display','iter' ); CALC_HESSIAN = 0;

% derivative check.
if DERIV_CHECK; do_deriv_check( params, index_into_params, left_right_idx, epsilon_profile, Q, Q_err, gamma, lambda, seqpos, CALC_HESSIAN );  return; end;

tic
params_out = fmincon(  @(x) leasqr_Q_fast(x,index_into_params, left_right_idx,epsilon_profile, Q, Q_err, gamma, lambda, seqpos, CALC_HESSIAN ), ...
		       params_init, [], [], [],[],lb,ub,[], options );
toc

% plot final fit.
[f,g,Qpred_fit] = leasqr_Q_fast( params_out, index_into_params, left_right_idx, epsilon_profile, Q, Q_err, gamma, lambda, seqpos, CALC_HESSIAN );
fprintf( 'Final sqr-dev value: %f  after %d iterations\n', f, MAX_ITER );
D_fit = unpack_params( params_out, N, left_right_idx );


if exist( 'pdb' ); plot_contours( pdb ); end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function do_deriv_check( params, index_into_params, left_right_idx, epsilon_profile, Q, Q_err, gamma, lambda, seqpos, CALC_HESSIAN ); 

[f,g,h] = leasqr_Q_fast( params, index_into_params, left_right_idx, epsilon_profile, Q, Q_err, gamma, lambda, seqpos, CALC_HESSIAN );
if ~CALC_HESSIAN; h = h*0; end;

for n = 1:length( params )
  params_in = params;
  delta = 0.00001;
  params_in(n) = params_in(n) + delta;
  [fdev, gdev] = leasqr_Q_fast( params_in, index_into_params, left_right_idx, epsilon_profile, Q, Q_err, gamma, lambda, seqpos, CALC_HESSIAN );

  fprintf( '%3d %8.3f %8.3f \n', n, g(n), (fdev - f) / delta );

  h_numerical(:,n) = (gdev - g)/delta;
end

clf
subplot(1,2,1); image( -h * 128 ); title( '-h (analytic)');
subplot(1,2,2); image( -h_numerical * 128 ); title( '-h (numerical)' );

return;
