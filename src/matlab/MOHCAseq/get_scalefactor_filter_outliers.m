function scalefactor = get_scalefactor_filter_outliers( ref, data, PERCENTILE_CUT, UNDERSHOOT );

if ~exist( 'PERCENTILE_CUT', 'var' ) PERCENTILE_CUT = 0.1; end;
if ~exist( 'UNDERSHOOT','var') UNDERSHOOT = 1; end;

scalefactor = 1.0;
if length( ref ) == 0; return; end

gp = 1:length(ref);
Ncut = max(ceil( length(ref) * PERCENTILE_CUT ),1);

niter = 3;
for i = 1:niter
  scalefactor  = mean(ref(gp))/mean(data(gp));
  dev =  (scalefactor * data  - ref) ;
  if ~UNDERSHOOT; dev = abs(dev); end;

  [dev_sort, sortidx ] = sort( dev, 'descend' );  
  %if length(ref ) > 40;     plot( [scalefactor*data, ref ] ); pause;   end
  gp = sortidx( Ncut:end );
end
