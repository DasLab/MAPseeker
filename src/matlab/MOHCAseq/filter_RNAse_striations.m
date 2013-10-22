function D_filter = filter_RNAse_striations( D );
%
%
N = size( D, 1 );
assert( size( D, 2 ) == size( D, 1 ) );
D_pos = max(D,0);
D_new = 0*D;
for i = 2 : (N-6)
  j = [ (i+6) : N ];
  D_new( i,j ) =  D_pos(i,j) - 0.5 * (D_pos(i-1,j) + D_pos(i+1,j));
  D_new( i,:) = smooth( D_new(i,:),20);
end
D_filter = D - max(D_new,0);


