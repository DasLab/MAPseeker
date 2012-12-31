function quick_look_MAPseeker( library_file, primer_file, inpath );
%
% quick_look_MAPseeker( library_file, primer_file, inpath );
%
%
% (C) R. Das, 2012-2013

if ~exist( 'library_file') library_file = 'RNA_structures.fasta';end;
if ~exist( 'primer_file') primer_file = 'primers.fasta';end;
if ~exist( 'inpath') inpath = './';end;

output_tag = strrep( strrep( inpath, '.','' ), '/', '' ); % could be blank

RNA_info = fastaread_structures( library_file );
primer_info = fastaread( primer_file );
N_primers = length( primer_info );

% load the data
for i = 1:N_primers;  
  stats_file = sprintf( '%s/stats_ID%d.txt', inpath,i);
  fprintf( sprintf('Looking for MAPseeker output file: %s\n', stats_file ) )
  if ~exist( stats_file );  fprintf( ['Could not find ',stats_file,'!\n']); return;end;
  D{i} = load( stats_file ); 
end
Nidx = size( D{1}, 1 );

for i = 1:N_primers; primer_tags{i} = primer_info(i).Header; end 

N_res  = size( D{1}, 2);
N_RNA = size(D{1},1);
if N_RNA  ~= length( RNA_info );
  fprintf( ['Number of lines in data files ',num2str(N_RNA),' does not match number of sequences in library ', library_file,' ', num2str(length(RNA_info)), '!\n'] ); 
  return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1) % overall summary of reads
clf;
for i = 1:N_primers
  num_counts_per_sequence(:,i) = sum(D{i}');
end

subplot(1,2,1);
total_counts = sum( sum( num_counts_per_sequence ));
num_counts_per_primer = sum( num_counts_per_sequence, 1);
colorcode = jet( N_primers );
my_bar_graph( num_counts_per_primer );
colormap( colorcode );
set( gca, 'xticklabel',primer_tags );
title( sprintf( 'Distributions of %9d counts over primers',round(total_counts)));
xticklabel_rotate;
set(gcf, 'PaperPositionMode','auto','color','white');;

subplot(1,2,2);
num_counts_total = sum(num_counts_per_sequence,2);
med = median( num_counts_total );
xmax = max(10*med,10);
r = [0:10:xmax]; % should adjust this automatically.
h = hist( num_counts_total, r);
plot( r, h,'k','linew',2 ); 
mean_counts = mean( num_counts_total );
median_counts = median( num_counts_total );
ymax = max( h(2:end-1) );
hold on; 
plot( median_counts* [1 1], [0 ymax],'r'); 
plot( mean_counts  * [1 1], [0 ymax]); 
hold off;
ylim([0 ymax]);
xlim([0 xmax]); 
xlabel( '# counts, summed over all primers, for RNA');
legend( 'frequency','median','mean');
title( sprintf( 'Distributions of %9d counts over RNAs',round(total_counts)));
set(gcf, 'PaperPositionMode','auto','color','white');
print( '-depsc2',[output_tag,'Figure1.eps'] )


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% output least common sequences and most common sequences.

[dummy,sortidx] = sort( num_counts_total );
N_display = 4;
N_display = min( N_display, N_RNA );

fprintf( 'Least common sequences:\n');
for i= sortidx(1:N_display)'
  fprintf( '%s Counts: %8d. ID %6d: %s\n',  RNA_info(i).Sequence, round(num_counts_total(i)), i, RNA_info(i).Header );
end

fprintf( '\nMost common sequences:\n')
most_common_sequences = sortidx(end : -1 : end-N_display+1)';
for i = most_common_sequences 
  fprintf( '%s Counts: %8d. ID %6d: %s\n', RNA_info(i).Sequence, round(num_counts_total(i)), i, RNA_info(i).Header );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(2)
clf
set(gcf, 'PaperPositionMode','auto','color','white');
for j = 1:N_display;
  subplot(N_display,1,j);
  idx = most_common_sequences(j);
  make_stair_plot( idx, D, RNA_info, colorcode );
end
print( '-depsc2',[output_tag,'Figure2.eps'] )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(3)  
% apply attenuation correction...
[ D_correct, D_correct_err ] = determine_corrected_reactivity( D );
clf
set(gcf, 'PaperPositionMode','auto','color','white');
for j = 1:N_display;
  subplot(N_display,1,j);
  idx = sortidx(N_RNA - j + 1);
  make_stair_plot( idx, D_correct, RNA_info, colorcode, D_correct_err );
end

print( '-depsc2',[output_tag,'Figure3.eps'] )

%pause;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% gray plots of all counts
figure(4)
clf;
make_image_plot( D, RNA_info, primer_info, most_common_sequences , 'raw counts');
print( '-depsc2',[output_tag,'Figure4.eps'] )

figure(5)
clf;
make_image_plot( D_correct, RNA_info, primer_info, most_common_sequences, 'correct', 1000 );
print( '-depsc2',[output_tag,'Figure5.eps'] )

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function my_bar_graph( x );
% copied from some crazy matlab code on mathworks.com
h = bar( x,'grouped','linew',2);

ch = get(h,'Children'); %get children of the bar group
fvd = get(ch,'Faces'); %get faces data
fvcd = get(ch,'FaceVertexCData'); %get face vertex cdata
%[zs, izs] = sort(x); %sort the rows ascending by first columns
for i = 1:length(x)
  row = i;%izs(i);
  fvcd(fvd(row,:)) = i; %adjust the face vertex cdata to be that of the row
end
set(ch,'FaceVertexCData',fvcd) %set to new face vertex cdata

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function make_image_plot( D, RNA_info, primer_info, most_common_sequences, title_tag, scalefactor );
N_RNA = size( D{1}, 1 );
N_res  = size( D{1}, 2 );
N_primers = length( primer_info );

STRUCTURES_DEFINED = ( length( RNA_info(1).Structure ) > 0 );
N_plots = N_primers + STRUCTURES_DEFINED;

if STRUCTURES_DEFINED
  subplot( 1,N_plots, 1 );
  imagex = zeros( N_RNA, N_res);
  for k = 1:N_RNA
    structure = RNA_info( k ).Structure;
    imagex( k, 1) = 1;
    imagex( k, strfind( structure, '.' )+1 ) = 1;
  end
  image( [0:N_res], [1:N_RNA], imagex* 30 );

  plot_title = 'Predicted Structure';
  if exist( 'title_tag' ); plot_title = sprintf('%s\n%s',plot_title,title_tag ); end;
  h = title( plot_title ); 
  set(h,'fontw','bold','fontsize',12,'interpreter','none');

end

for i = 1:N_primers
  subplot( 1,N_plots, i+STRUCTURES_DEFINED );
  Dplot = D{i};
  if ~exist( 'scalefactor' )
    meanval = mean(mean(Dplot(:,2:end-1)));
    if meanval <= 0; continue; end;
    scalefactor1 = 20/meanval;
  else
    scalefactor1 = scalefactor;
  end
  image( [0:N_res], 1:N_RNA, Dplot * scalefactor1 );  
  
  plot_title = regexprep(primer_info(i).Header,'\t','\n');
  if exist( 'title_tag' ); plot_title = sprintf('%s\n%s',plot_title,title_tag ); end;
  h = title( plot_title );
  set(h,'fontw','bold','fontsize',12,'interpreter','none');

  set( gca,'yticklabel',[],'tickdir','out');
  if (i + STRUCTURES_DEFINED ) > 0;
    set(gca,'yticklabel',[]);
  end
end

N_display = length( most_common_sequences );
for j = 1:N_display
  idx = most_common_sequences(j);
  hold on
  plot( N_res, idx, 'ro','markersize',5,'markerfacecolor','r','clipping','off');
  h = text( N_res, idx,  regexprep( RNA_info( idx ).Header, '\t','\n' ) );
  set(h,'clipping','off','verticalalign','middle','fontweight','bold','fontsize',7,'interpreter','none');
end

colormap( 1 - gray(100))
set(gcf, 'PaperPositionMode','auto','color','white');

%print( '-dpdf',sprintf( 'EteRNA_PlayerProjects_RawData%02d.pdf',j) );

