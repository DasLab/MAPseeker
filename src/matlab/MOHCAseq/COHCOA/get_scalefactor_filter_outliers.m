function scalefactor = get_scalefactor_filter_outliers( ref, data, ...
							     PERCENTILE_CUT, UNDERSHOOT,...
							     ref_err);

if ~exist( 'PERCENTILE_CUT', 'var' ) PERCENTILE_CUT = 0.1; end;
if ~exist( 'UNDERSHOOT','var') UNDERSHOOT = 1; end;
if ~exist( 'ref_err','var') | isempty( ref_err ); ref_err = 0 * ref + 1; end;
%if ~exist( 'PLOT_STUFF' ) PLOT_STUFF = 0; end;

  scalefactor = 1.0;
if length( ref ) == 0; return; end

gp = 1:length(ref);
Ncut = max(ceil( length(ref) * PERCENTILE_CUT ),1);

weights = max( (1./ref_err.^2), 0);
%weights = 0*ref + 1;

niter = 3;
for i = 1:niter

  if ( sum( data(gp) ) == 0 ) gp = [1:length(ref)]; end; 
    
  %scalefactor  = sum( ref(gp).*ref(gp).*weights(gp) ) / sum(data(gp).*ref(gp).*weights(gp) );
  scalefactor  = mean( ref(gp) .* weights(gp)) / mean( data(gp).*weights(gp) );

  dev =  (scalefactor * data  - ref) ;
  if ~UNDERSHOOT; dev = abs(dev); end;

  [dev_sort, sortidx ] = sort( dev, 'descend' );  
  %if length(ref ) > 40;     plot( [scalefactor*data, ref ] ); pause;   end
  gp = sortidx( Ncut:end );
end

%if PLOT_STUFF
%    plot( [scalefactor *data, ref] );
%end
