function D_symm = symmetrize( D, seqpos, ligpos );
% D_symm = symmetrize( D, seqpos, ligpos );
%
% MOHCA data is only defined for i < j (where i is seqpos, j is ligpos )
%  This symmetrizes to get i > j.
%
% Inputs: 
% D      = data matrix
% seqpos = sequence positions corresponding to first index 
% ligpos = sequence positions corresponding to second index
%
% (C) R. Das, Stanford University, 2013

D_symm = D;

for i = 1:length( seqpos )
  for j = 1:length( ligpos )
    if ( seqpos(i) <= ligpos(j) ) continue; end;
    m = find( seqpos == ligpos(j) );
    if isempty( m ); continue; end;
    n = find( ligpos == seqpos(i) );
    if isempty( n ); continue; end;
    D(i,j)     = D(m,n);
  end
end
