function  SN_ratio = estimate_signal_to_noise_ratio( signal, noise );
%   SN_ratio = estimate_signal_to_noise_ratio( signal, noise );

if nargin==0; help( mfilename ); return; end;

all_ratio = 0;
for i = 1:size( signal, 2 )
  good_points = find( noise(:,i) > 0 );

  if length( good_points ) > 3

    good_points = good_points(2:end-1);
    
    S = mean( signal(good_points,i) );
    N = mean( noise( good_points,i) );  
    if ( N > 0 ) all_ratio(i) = S/N; end;
  
  end

end
SN_ratio = mean( all_ratio );
