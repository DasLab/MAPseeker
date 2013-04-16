function  SN_ratio = estimate_signal_to_noise_ratio( signal, noise );
%   SN_ratio = estimate_signal_to_noise_ratio( signal, noise );

if nargin==0; help( mfilename ); return; end;

all_ratio = 0;
for i = 1:size( signal, 2 )
  S = mean( signal(2:end-1,i) );
  N = mean( noise( 2:end-1,i) );
  if ( N > 0 ) all_ratio(i) = S/N; end;
end

SN_ratio = mean( all_ratio );