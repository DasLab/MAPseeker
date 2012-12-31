function make_stair_plot( idx, D, RNA_info, colorcode, D_err );

N = length( D );
if ~exist( 'D_err' )
  for i = 1:N % assume raw counts, and Poisson error.
    D_err{i} = sqrt( D{i} );
  end
end

Nres = size( D{1},2);
ymax = 0;
total_count = 0;
for i = 1:N; 
  stairs( [0:Nres-1]-0.5,  D{i}(idx,:), 'color',colorcode(i,:), 'linew',2 ); hold on; 
  for j = 1:Nres; 
    val = D{i}(idx,j);
    val_err = D_err{i}(idx,j);
    plot( (j-1)*[1 1], val + val_err*[1 -1], 'color',colorcode(i,:) );
  end

  ymax = max( ymax,  max( D{i}( idx, 4:end) ) );
  total_count = total_count + sum( D{1}(idx,:) );
end

title(  [ regexprep( RNA_info( idx ).Header, '\t','   '), '   Counts: ',num2str(total_count)] );

set(gca,'xaxisloc','top','xgrid','on','fontw','bold');

ymax = ymax*1.2;
if ymax>0; ylim([0 ymax]); end;
xlim( [-0.5 Nres+1] );
    
for j = 1:(Nres-1); 
  if ( j > length( RNA_info(idx ).Sequence ) ); continue; end;
  seqchar = sprintf('%s', RNA_info( idx ).Sequence(j));
  if ( length( RNA_info( idx ).Structure) > 0 ) 
    seqchar = sprintf( '%s\n%s', seqchar,RNA_info( idx ).Structure(j) );
  end
  h = text( j, 0, seqchar);
  set(h,'HorizontalAlignment','center','VerticalAlignment','top','fontw','bold');
end
hold off;
