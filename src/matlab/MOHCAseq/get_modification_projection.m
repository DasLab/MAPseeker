function [mdf_prjc, mdf_rates] = get_modification_projection( D_sub, full_extension_correction_factor, offset )

if ~exist( 'offset','var' ); offset = 8; end;

[Nmod, Ncleave] = size( D_sub );
D_sub(1,:) = D_sub(1,:)/full_extension_correction_factor;
for i = 1:(Ncleave-offset)
    mdf_prjc(i) = sum( D_sub(i,(i+offset):end) ) / sum( sum( D_sub( 1:i, (i+offset):end) ) );
end
mdf_rates = sum(mdf_prjc);

