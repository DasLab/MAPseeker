function [D_sparse,D_cutoff] = sparsify( D, SPARSITY_HITS_PER_RES );    

if ~exist( 'SPARSITY_HITS_PER_RES','var') SPARSITY_HITS_PER_RES = 20; end;
N = size( D, 1 );

D_laidout = reshape( D, 1, N*N);
[dummy, sortidx ] = sort( D_laidout, 'descend' );
D_sparse = 0 * D;
N_hits = SPARSITY_HITS_PER_RES * N;
if ( N_hits  >length( D_laidout ) ) 
  N_hits = length( D_laidout ); 
  fprintf( 'No sparsity filter! SPARSITY_HITS_PER_RES too large\n' )
end;
D_sparse( sortidx(1:N_hits) ) = D( sortidx(1:N_hits) );
D_cutoff = D(sortidx(N_hits));
