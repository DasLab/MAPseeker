function q_fit( r, epsilon_file, which_res , pdb)
%  fit_primary_map( r, epsilon_file, which_res, pdb )
%
%  r            = rdat (either filename or actual data object will work)
%  epsilon_file = file with nt, fraction at nt modified with source 
%  which_res    = window of residues to fit. (leave as [] to use all)
%  pdb          = filename of pdb 
%  


MAX_ITER = 500;
gamma = 0.05;
%lambda = 0.02; less smooth
lambda = 0.1;  % original
JUST_AT_EPSILON = 0;
%previous sparsity_nres (Saved to disk) was 50.
SPARSITY_NRES = 800;
MIN_Q_DIAG = 10;
DIAG_SEP = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isstruct( r ) & ischar( r );  r = read_rdat_file( r ); end
if ~exist( 'which_res' ) which_res = []; end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% zoom in user-defined subset
ligpos = get_ligpos( r );
Q = r.reactivity( 2:end, 1:end-1);
seqpos = r.seqpos( 2:end );
assert( all( seqpos == ligpos( 1:end-1 )' ) );

clf;
Nrange = [1:length( seqpos ) ];
if ~isempty( which_res )
  Nrange = [];
  for i = 1:length( which_res );    Nrange = [Nrange, find( seqpos == which_res(i) ) ];   end
end

figure(1)
Q = Q(Nrange, Nrange ); 
seqpos = seqpos( Nrange );
N = length( seqpos );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
epsilon = load( epsilon_file );
epsilon_profile = zeros(1,N);
for m = 1:length(epsilon);  epsilon_profile( seqpos == epsilon(m,1) ) = epsilon(m,2); end

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
[f,g,Qpred_new] = leasqr_Q( params, index_into_params, left_right_idx, epsilon_profile, Q, gamma, lambda, seqpos );

% derivative check.
DERIV_CHECK = 0;
if (DERIV_CHECK) do_deriv_check( params, index_into_params, left_right_idx, epsilon_profile, Q, gamma, lambda, seqpos ); end


fprintf( 'Running optimizer...\n' );
%options = optimoptions( 'fmincon','GradObj','on','MaxIter',MAX_ITER,'Algorithm','trust-region-reflective' );
%params_out = fminunc( @(x) leasqr_Q(x,index_into_params, left_right_idx,epsilon_profile, Q ), params, options );

%A = -1*eye( length(params) ); 
%B = min_params; %zeros( length(params), 1 );

lb = min_params;
%ub = 10 * ones( length( params ), 1 );
ub = [];

params_init = max( params, min_params );
%params_init = min_params;

if matlabpool( 'size' ) == 0; matlabpool open 4; end
options = optimoptions( 'fmincon','GradObj','on','UseParallel','always','MaxIter',MAX_ITER,'Algorithm','interior-point','display','iter' );

tic
params_out = fmincon(  @(x) leasqr_Q(x,index_into_params, left_right_idx,epsilon_profile, Q, gamma, lambda, seqpos ), ...
		       params_init, [], [], [],[],lb,ub,[], options );
toc

% plot final fit.
[f,g,Qpred_fit] = leasqr_Q( params_out, index_into_params, left_right_idx, epsilon_profile, Q, gamma, lambda, seqpos );
fprintf( 'Final sqr-dev value: %f  after %d iterations\n', f, MAX_ITER );
D_fit = unpack_params( params_out, N, left_right_idx );


if exist( 'pdb' )
  [D_sim_a, rad_res, hit_res, dist_matrix, pdbstruct] = get_simulated_data( pdb );contour_levels = [15,30];
  colorcode = [1 0.3 1; 0.5 0.5 1];
  dist_matrix_smooth = smooth2d( dist_matrix );
  hold on
  for i = 1:length( contour_levels )
    [c,h]=contour(rad_res, hit_res, tril(dist_matrix_smooth), ...
		  contour_levels(i) * [1 1],...
		  'color',colorcode(i,:),...
		  'linewidth',0.5 );
  end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function do_deriv_check( params, index_into_params, left_right_idx, epsilon_profile, Q, gamma, lambda, seqpos ); 

[f,g,Qpred_new] = leasqr_Q( params, index_into_params, left_right_idx, epsilon_profile, Q, gamma, lambda, seqpos );

for n = 1:17 %length( params )
  params_in = params;
  delta = 0.00001;
  params_in(n) = params_in(n) + delta;
  [fdev,~,~] = leasqr_Q( params_in, index_into_params, left_right_idx, epsilon_profile, Q, gamma, lambda, seqpos );
  fprintf( '%3d %8.3f %8.3f \n ', n, g(n), (fdev - f) / delta );
end
return;
