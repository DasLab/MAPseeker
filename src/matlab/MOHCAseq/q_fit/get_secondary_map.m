function Q = get_secondary_map( D, epsilon_profile );

N = size( D, 1 );
assert( size( D, 2 ) == N );

D_stop = D;
D_cleave = D;
for i = 1:N % lig pos
  for j = i:N % cleave pos

    % sources
    gp = [1:i, j:N]; %'external' sources only, which will not block RT.
    Q(i,j) = sum( D_stop(i,gp) .* D_cleave(gp,j)' .* epsilon_profile(gp) );
  
  end
end
