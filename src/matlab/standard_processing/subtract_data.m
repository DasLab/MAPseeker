function [Dout, Dout_err] = subtract_data( D1, D2, D1_err, D2_err );
%
% [Dout, Dout_err] = subtract_data( D1, D2, D1_err, D2_err );
%


if nargin < 4; help( mfilename ); return; end;

Dout = D1 - D2;
Dout_err = sqrt( D1_err .* D1_err   + D2_err .* D2_err );
