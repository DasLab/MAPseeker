function [f, g, Qpred ] = leasqr_Q( params, index_into_params, left_right_idx, epsilon_profile, Q, gamma, lambda, seqpos );
% [f, g, h, Qpred ] = leasqr_Q( params, index_into_params, left_right_idx, epsilon_profile, Q, gamma, lambda, seqpos );
%
%
%
N = length( epsilon_profile );
assert( size(Q,1) == N );

Qpred = zeros( N, N );
for j = 1:N
  for i = 1:j
    ep = [1:i, j:N]; % 'external points'
    gp = find( index_into_params(i,ep) > 0 & index_into_params(j,ep) > 0);
    ep = ep( gp );
    Qpred(i,j) = Qpred(i,j) + sum( params( index_into_params(i,ep) ) .* params( index_into_params(j,ep) ) .* epsilon_profile(ep) );
  end
end

subplot(1,3,1); image( seqpos, seqpos, 30 * Q' ); title( 'Q_{obs}');set(gca,'xtick',[0:20:300],'xgrid','on','ygrid','on');
subplot(1,3,2); image( seqpos, seqpos, 30*Qpred' ); title( 'Q_{fit}');set(gca,'xtick',[0:20:300],'xgrid','on','ygrid','on');
D = unpack_params( params, N, left_right_idx ); 
subplot(1,3,3); image( seqpos, seqpos, 10*D' ); title( 'D_{fit}' );set(gca,'xtick',[0:20:300],'xgrid','on','ygrid','on');
drawnow;

calc_points = find( ~isnan(Q) );
Qpred( isnan(Q) ) = nan;
delQ = Qpred - Q;
f = 0.5 * sum( ( delQ( calc_points ) ).^2 );

g = zeros( length( params ), 1 );
delQ( isnan(Q) ) = 0; % won't contribute to gradient.
if nargout > 1
  for j = 1:N
    for i = 1:j
      count_params = index_into_params(i,j);
      if ( count_params == 0 ) continue; end;
      
      n_idx = [1 : j]; 
      gp = find( index_into_params(n_idx,j) > 0 );
      n_idx = n_idx( gp );
      g( count_params ) = g( count_params ) + ...
	  sum( delQ(i,n_idx) .* params( index_into_params(n_idx,j) ) ) * epsilon_profile(j);
      
      n_idx = [j+1 : N];
      gp = find( index_into_params(n_idx,i) > 0 );
      n_idx = n_idx( gp );
      g( count_params ) = g( count_params ) + ...
	  sum( delQ(j,n_idx) .* params( index_into_params(n_idx,i ) ) ) * epsilon_profile(i);
      
      m_idx = [1 : i ];
      gp = find( index_into_params(m_idx,j) > 0 );
      m_idx = m_idx( gp );
      g( count_params ) = g( count_params ) + ...
	  sum( delQ(m_idx,i)' .* params( index_into_params(m_idx,j) ) ) * epsilon_profile(j);
      
      m_idx = [(i+1):N ];
      gp = find( index_into_params(m_idx,i) > 0 );
      m_idx = m_idx( gp );
      g( count_params ) = g( count_params ) + ...
	  sum( delQ(m_idx,j)' .* params( index_into_params(m_idx,i) ) ) * epsilon_profile(i);
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% L1 norm (sparsity)
f = f + gamma * sum( abs(params ) );
g = g + gamma * sign( params' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% smoothness?
f_smooth = 0;
g_smooth = g * 0;
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
  
  end
end
f = f + lambda * f_smooth;
g = g + lambda * g_smooth;
