function Q_scaling = figure_out_Q_scaling( Q )

N = size(Q,1);

for i = 1:N; 
  Q_nodiag( [1:i-5],i) = Q([1:i-5],i); 
end;
Q_nodiag( :, N-5:N ) = 0.0;
Q_nodiag( 1, 1:5   ) = 0.0;
Q_nodiag = triu( Q_nodiag );

Q_scaling = 20 * 0.2 / mean( mean( max(Q_nodiag,0) ) );
