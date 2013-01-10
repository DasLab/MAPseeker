function make_stair_plot( idx, D, RNA_info, colorcode, D_err );

if ~exist( 'D_err' ) | length( D_err ) == 0
  N = length( D );
  for i = 1:N % assume raw counts, and Poisson error.
    D_err{i} = sqrt( D{i} );
  end
end

for i = 1:length( D )
  D{i} = D{i}(idx,:);
  D_err{i} = D_err{i}(idx,:);
end

stair_plot( D, ...
	    RNA_info( idx ).Sequence,...
	    RNA_info( idx ).Structure,...
	    colorcode, D_err, ...
	    regexprep( RNA_info( idx ).Header, '\t','\n') ...
	    );
