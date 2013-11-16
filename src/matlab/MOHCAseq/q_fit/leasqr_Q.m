function [f, g, h, Qpred ] = leasqr_Q( params, index_into_params, left_right_idx, epsilon_profile, Q, gamma, lambda, seqpos, CALC_HESSIAN );
% [f, g, h, Qpred ] = leasqr_Q( params, index_into_params, left_right_idx, epsilon_profile, Q, gamma, lambda, seqpos );
%
%
%
if ~exist( 'CALC_HESSIAN' ) CALC_HESSIAN = 1; end;

f = 0; g = []; Qpred = [];
Nparams = length( params );
N = length( epsilon_profile );
assert( size(Q,1) == N );

count_obs = 0;
Qpred     = nan * ones( N, N );
for j = 1:N
  for i = 1:j

    if isnan( Q(i,j) ); continue; end;
    
    count_obs = count_obs + 1;
    ep = [1:i, j:N]; % 'external points'
    gp = find( index_into_params(i,ep) > 0 & index_into_params(j,ep) > 0);
    ep = ep( gp );
    
    % second derivative matrix
    %S = sparse( Nparams, Nparams );
    S1 = sparse( index_into_params(i,ep), index_into_params(j,ep), epsilon_profile(ep), Nparams, Nparams );
    S2 = sparse( index_into_params(j,ep), index_into_params(i,ep), epsilon_profile(ep), Nparams, Nparams );
    S = S1 + S2;
    all_S{count_obs} = S;
    
    % first derivative vector
    T = S * params'; 
    all_T(:,count_obs) = T;
    
    % value
    Qpred(i,j) = 0.5 * ( params * S * params' );
    delQ( count_obs ) = Qpred(i,j) - Q(i,j);
  end
end

subplot(1,3,1); image( seqpos, seqpos, 30 * Q' ); title( 'Q_{obs}');set(gca,'xtick',[0:20:300],'xgrid','on','ygrid','on');
subplot(1,3,2); image( seqpos, seqpos, 30*Qpred' ); title( 'Q_{fit}');set(gca,'xtick',[0:20:300],'xgrid','on','ygrid','on');
D = unpack_params( params, N, left_right_idx ); 
subplot(1,3,3); image( seqpos, seqpos, 10*D' ); title( 'D_{fit}' );set(gca,'xtick',[0:20:300],'xgrid','on','ygrid','on');
drawnow;

f = f + 0.5 * sum( delQ.^2 );

g = zeros( Nparams, 1 );
g = g + all_T * delQ';  

h = zeros( Nparams, Nparams );
if CALC_HESSIAN
  h = all_T * all_T';
  for n = 1:count_obs % might be possible to accelerate by vectorizing.
    h = h + delQ(n) * all_S{n};
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% L1 norm (sparsity)
f = f + gamma * sum( abs(params ) );
g = g + gamma * sign( params' );
% no contribution to hessian h

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% smoothness terms -- could probably be more efficient, like above.
f_smooth = 0;
g_smooth = g * 0;
h_smooth = h * 0;
for j = 2:N-1
  for i = 2:j
    count_params = index_into_params(i,j);
    if ( count_params == 0 ) continue; end;
    
    % find neighbors. Note -- now we don't necessarily need to constrain ourselves to epsilon>0 rows or columns!
    count_params_nbr = [ index_into_params(i+1,j), index_into_params(i-1,j), index_into_params(i,j-1), index_into_params(i,j+1)];
    gp = find( count_params_nbr  > 0 );
    count_params_nbr = count_params_nbr( gp );

    f_smooth = f_smooth + 0.5 * sum( ( params( count_params_nbr ) - params( count_params ) ).^2 ); 
    
    g_smooth( count_params )     = g_smooth( count_params )     + sum( params( count_params ) - params( count_params_nbr ) );
    g_smooth( count_params_nbr ) = g_smooth( count_params_nbr ) + ( params(count_params_nbr)' - params( count_params )' );

    if CALC_HESSIAN
      for m = count_params_nbr; 
	idx = [count_params, m ];
	h_smooth( idx, idx ) = h_smooth( idx, idx ) + [ 1 -1; -1 1];
      end
    end
    
  end
end
f = f + lambda * f_smooth;
g = g + lambda * g_smooth;
h = h + lambda * h_smooth;

global global_leasqr_Q_hess;
global_leasqr_Q_hess = h;