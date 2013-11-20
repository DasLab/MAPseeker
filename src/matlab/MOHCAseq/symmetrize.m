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

D_symm = D*0 + NaN;

for i = 1:length( seqpos )
  for j = 1:length( ligpos )
    if ( seqpos(i) <= ligpos(j) ) continue; end;
    m = find( seqpos == ligpos(j) );
    n = find( ligpos == seqpos(i) );
    if ~isempty( m ) & ~isempty(n) 
      D_symm(i,j) = D(m,n);
      D_symm(m,n) = D(m,n);
    end
  end
end
