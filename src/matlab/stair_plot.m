function stair_plot( D, sequence, structure, colorcode, D_err, tag, seqpos );
% stair_plot( D, sequence, structure, colorcode, D_err, tag, seqpos );
%
% (C) R. Das, 2012-2013

if ~iscell( D );  D = { D }; end
if exist( 'D_err' ) && length( D_err ) > 0 && ~iscell( D_err );  D_err = { D_err }; end

N = length( D );
if ~exist( 'D_err' ) | length( D_err ) == 0
  for i = 1:N % assume raw counts, and Poisson error.
    D_err{i} = sqrt( D{i} );
  end
end

Nres = length( D{1} );
if ~exist( 'seqpos' );  seqpos = [0:Nres-1]; end
ymax = 0;
total_count = 0;

% plot values as staircase
for i = 1:N; 
  stairs( seqpos-0.5,  D{i}, 'color',colorcode(i,:), 'linew',2 ); hold on; 
  ymax = max( ymax,  max( D{i}( :, 4:end) ) );
  total_count = total_count + sum( D{i} );
end

% plot error bars
for i = 1:N; 
  for j = 1:Nres; 
    val = D{i}(j);
    val_err = D_err{i}(j);
    plot( (seqpos(j))*[1 1], val + val_err*[1 -1], 'color',colorcode(i,:) );
  end
end

% make a line along x-axis
plot( [min(seqpos)-0.5 max(seqpos)+0.5],  [0 0], 'k' ); hold on; 

if exist( 'tag' ) 
%  ylabel( tag );
  title( tag );
else
  ylabel(  [ , '   Counts: ',num2str(total_count)] );
end
set(gca,'xaxisloc','top','xgrid','on','fontw','bold');

ymax = ymax*1.2;
if ymax>0; ylim([0 ymax]); end;
xlim( [-0.5 Nres+1] );
    
for j = 1:(Nres-1); 
  if ( j > length( sequence ) ); continue; end;
  seqchar = sprintf('%s', sequence(j) );
  if ( length( structure ) > 0 ) 
    seqchar = sprintf( '%s\n%s', seqchar,structure(j) );
  end
  h = text( j, 0, seqchar);
  set(h,'HorizontalAlignment','center','VerticalAlignment','top','fontw','bold');
end
hold off;
