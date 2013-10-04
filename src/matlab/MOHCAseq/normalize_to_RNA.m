function [D_norm, ref_profile ] = normalize_to_RNA( D, refcol );

if ~exist( 'refcol' )  refcol = size( D,2) - 2; end;
refcol;
ref_profile = mean( D(:,refcol), 2 );
  
for i = 1: size( D, 2 )
  %plot( D( [1:i-2],i ) ) 
  norm_range = [5:i-5];
  D_norm(:,i) = D(:,i) * mean( ref_profile(norm_range) / mean( D(norm_range,i) ) );
end