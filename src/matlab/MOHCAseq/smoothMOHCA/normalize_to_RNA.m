function [D_norm, ref_profile ] = normalize_to_RNA( D, refcol );
% [D_norm, ref_profile ] = normalize_to_RNA( D, refcol );
%
% Inputs:
%  D      = input MOHCA matrix. In D(i,j), i = source, j = cleavage.
%  refcol = cleavage site(s) to use for normalization. Default is 
%           third to last cleavage site.
%
% Outputs:
%  D_norm      = normalized matrix
%  ref_profile = profile used for normalization.
%
% (C) R. Das, 2013
if nargin < 1; help( mfilename ); return; end;

  if ~exist( 'refcol' )  refcol = size( D,2) - 2; end;
refcol;
ref_profile = mean( D(:,refcol), 2 );
  
for i = 1: size( D, 2 )
  %plot( D( [1:i-2],i ) ) 
  norm_range = [5:i-5];
  D_norm(:,i) = D(:,i) * mean( ref_profile(norm_range) / mean( D(norm_range,i) ) );
end