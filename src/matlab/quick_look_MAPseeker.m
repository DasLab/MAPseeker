function [D, RNA_info, primer_info, D_correct, D_correct_err ] = quick_look_MAPseeker( library_file, primer_file, inpath, full_length_correction_factor, combine_mode );
%
% [D, , RNA_info, primer_info, D_correct, D_correct_err ] = quick_look_MAPseeker( library_file, primer_file, inpath [, full_length_correction_factor, combine_mode] );
%
%      Reads in MAPseeker output and prints useful graphs for your
%      notebook.
%
% library_file = [default: 'RNA_sequences.fasta'] all probed RNA sequences in 
%                  FASTA format. Can include structures in dot/paren notation 
%                  after each sequence (as output by Vienna's RNAfold).
% primer_file  = [default: 'primers.fasta'] DNA sequences of reverse 
%                  transcription primers in FASTA format
% inpath       = [default: './' (current directory)] where to find
%                  MAPseeker output files: stats_ID1.txt, stats_ID2.txt, ...
%
% Optional:
% full_length_correction_factor
%     =  amount to increase value of counts at site 0. Correction for 
%        empirically observed ~50% ssDNA ligation efficiency by circLigase
%        to 'full-length' complementary DNA created by SSIII.
%        [NOTE: Default is 2.0, not 1.0]
% combine_mode = [default 0, no 'collapse']. If this is 1, combine data for RNAs that have the same 
%                   names, as specified in the library_file. If this is 2, combine data 
%                   for RNAs that share any 'tags' (segments of the library_file names, separated by tabs);
%                   this is useful if, for example, RNAs are double mutants and you want to project
%                   to single mutants.
%
% (C) R. Das, 2012-2013

if ~exist( 'library_file') | length( library_file ) == 0;  library_file = 'RNA_structures.fasta'; end;
if ~exist( library_file );  library_file = 'RNA_sequences.fasta'; end    
if ~exist( 'primer_file') | length( primer_file ) == 0; primer_file = 'primers.fasta';end;
if ~exist( 'inpath') | length( inpath ) == 0; inpath = './';end;
if ~exist( 'full_length_correction_factor') | length( full_length_correction_factor ) == 0; full_length_correction_factor = 1.0;end;
if ~exist( 'combine_mode' ) combine_mode = 0;end;
  
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

if combine_mode > 0
  [D, RNA_info] =  collapse_by_tag( D, RNA_info, combine_mode );
  output_tag = [output_tag, '_collapse',num2str(combine_mode),'_'];
end

N_res  = size( D{1}, 2);
N_RNA = size(D{1},1);
if N_RNA  ~= length( RNA_info );
  fprintf( ['Number of lines in data files ',num2str(N_RNA),' does not match number of sequences in library ', library_file,' ', num2str(length(RNA_info)), '!\n'] ); 
  return;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall summary of total reads
FigHandle = figure(1);
figure_xsize = 1000;
set(FigHandle, 'Position', [50, 50, figure_xsize, 400]);
clf;
for i = 1:N_primers
  num_counts_per_sequence(:,i) = sum(D{i}');
end

subplot(1,2,1);
total_counts = sum( sum( num_counts_per_sequence ));
num_counts_per_primer = sum( num_counts_per_sequence, 1);
colorcode = jet( N_primers );
colorcode(:,2) = 0.8 * colorcode(:,2);
my_bar_graph( num_counts_per_primer );
colormap( colorcode );

for i = 1:N_primers; 
  primer_tags{i} = regexprep(primer_info(i).Header,'\t','\n'); 
end 
set( gca, 'xticklabel',primer_tags );

for i = 1:N_primers; 
  tag = regexprep(primer_info(i).Header,'\t','   '); 
  fprintf( '%9d %s\n', round(num_counts_per_primer( i )), tag );
end



ylabel( sprintf( 'Distributions of %9d counts over primers',round(total_counts)));
xticklabel_rotate;
set(gcf, 'PaperPositionMode','auto','color','white');;
h=title( basename(pwd) ); set(h,'interpreter','none','fontsize',7 )

subplot(1,2,2);
num_counts_total = sum(num_counts_per_sequence,2);
mean_counts = mean( num_counts_total );
median_counts = round(median( num_counts_total ));
xmax = max(5*mean_counts,10);
r = [0:10:xmax]; % should adjust this automatically.
h = hist( num_counts_total, r);
plot( r, h,'k','linew',2 ); 
ymax = max( h(2:end-1) );
hold on; 
plot( median_counts* [1 1], [0 ymax],'r'); 
plot( mean_counts  * [1 1], [0 ymax]); 
hold off;
if ( ymax > 0 )
  ylim([0 ymax]);
end
xlim([0 xmax]); 
xlabel( '# counts, summed over all primers, for RNA');
legend( 'frequency',...
	['median: ',num2str(median_counts)],...
	['mean: ',num2str(mean_counts)] );
ylabel( sprintf( 'Distributions of %9d counts over RNAs',round(total_counts)));
set(gcf, 'PaperPositionMode','auto','color','white');
h=title( basename(pwd) ); set(h,'interpreter','none','fontsize',7 )

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% apply attenuation correction...
[ D_correct, D_correct_err ] = determine_corrected_reactivity( D, full_length_correction_factor );

figure_ysize = min( N_RNA*150, 800);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Make 1D plots of most common sequences
FigHandle = figure(2);
set(FigHandle, 'Position', [150,150,600,figure_ysize]);
make_stair_plots( D, most_common_sequences, RNA_info, primer_info, colorcode );
print( '-depsc2',[output_tag,'Figure2.eps'] )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Make 1D plots of most common sequences, apply correction
FigHandle = figure(3);
set(FigHandle, 'Position', [200,200,600,figure_ysize]);
make_stair_plots( D_correct, most_common_sequences, RNA_info, primer_info, colorcode, D_correct_err );
print( '-depsc2',[output_tag,'Figure3.eps'] )

%pause;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make 2D gray of all counts
FigHandle = figure(4);
set(FigHandle, 'Position', [250,250,600,figure_ysize]);
clf;
make_image_plot( D, RNA_info, primer_info, most_common_sequences , 'raw counts');
print( '-depsc2',[output_tag,'Figure4.eps'] )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make 2D gray of all reactivies, corrected
FigHandle = figure(5);
set(FigHandle, 'Position', [300,300,600,figure_ysize]);
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

% actually show numbers over bars.
for i = 1:length(x)
  text( i, x(i),  num2str(round(x(i))), 'horizontalalign','center','verticalalign','bottom');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function make_image_plot( D, RNA_info, primer_info, most_common_sequences, title_tag, scalefactor );
N_RNA = size( D{1}, 1 );
N_res = size( D{1}, 2 ); % this is actually the number of residues + 1 (first value is at zero).
N_primers = length( primer_info );

STRUCTURES_DEFINED = ( length( RNA_info(1).Structure ) > 0 );
N_plots = N_primers + STRUCTURES_DEFINED;

imagex = zeros( N_RNA, (N_res * N_plots) );
plot_titles = {};
xticks = [];
xticklabels = [];

subplot(1,1,1);
% just use lower half if there aren't that many RNAs..
if (N_RNA < 20); subplot(2,1,2); end;

if STRUCTURES_DEFINED

  scalefactor_structure = 40;
  for k = 1:N_RNA
    structure = RNA_info( k ).Structure;
    imagex( k, 1) = scalefactor_structure;
    imagex( k, strfind( structure, '.' )+1 ) = scalefactor_structure;
  end

  plot_title = 'Predicted Structure';
  if exist( 'title_tag' ); plot_title = sprintf('%s\n%s',plot_title,title_tag ); end;

  plot_titles = [ plot_titles, plot_title ];
  xticks      = [ xticks,      [0:20:N_res-20] ];
  xticklabels = [ xticklabels, [0:20:N_res-20] ];  
end

for i = 1:N_primers

  offset = (i+STRUCTURES_DEFINED-1)*N_res;
  minresidx = 1 + offset; 
  maxresidx = N_res + offset;
  Dplot = D{i};
  if ~exist( 'scalefactor' )
    meanval = mean(mean(Dplot(:,2:end-1)));
    if meanval > 0;
      scalefactor_to_use = 20/meanval;
    else
      scalefactor_to_use = 1.0;
    end
  else
    scalefactor_to_use = scalefactor;
  end
  imagex( :, [minresidx:maxresidx] ) = Dplot * scalefactor_to_use;

  plot_title = regexprep(primer_info(i).Header,'\t','\n');
  if exist( 'title_tag' ); plot_title = sprintf('%s\n%s',plot_title,title_tag ); end;
  plot_titles = [ plot_titles, plot_title ];

  xticks      = [ xticks,      [0:20:N_res-20] + offset];
  xticklabels = [ xticklabels, [0:20:N_res-20] ];

end

image( [0:(N_res*N_plots)-1], [1:N_RNA], imagex );
set( gca,'tickdir','out','xtick',xticks,'xticklabel',xticklabels,'fontw','bold','fonts',8);

for i = 1:N_plots
  hold on; 
  %plot( (i*N_res - 1 + 0.5) * [1 1], [0 N_RNA+0.5], 'k','linew',2);
  h = text( (i - 1) * N_res, 0.5, plot_titles{i} );
  set(h,'fontw','bold','fontsize',9,'interpreter','none','verticalalign','bottom','horizontalalign','left');
end
hold off
box off

if (N_RNA < 220 );  %totally arbitrary cut
  for j = 1:N_RNA; RNA_labels{j} = regexprep( RNA_info(j).Header, '\t',' '); end;    
  set( gca,'ytick',[1:N_RNA],'yticklabel',RNA_labels);
end

N_display = length( most_common_sequences );
for j = 1:N_display
  idx = most_common_sequences(j);
  hold on
  plot( N_res*N_plots - 20, idx, 'ro','markersize',5,'markerfacecolor','r','clipping','off');
  h = text( N_res*N_plots - 15, idx,  regexprep( RNA_info( idx ).Header, '\t','\n' ) );
  set(h,'clipping','off','verticalalign','middle','fontweight','bold','fontsize',7,'interpreter','none');
end

colormap( 1 - gray(100))
set(gcf, 'PaperPositionMode','auto','color','white');

xlabel( basename(pwd),'interpreter','none' );
%print( '-dpdf',sprintf( 'EteRNA_PlayerProjects_RawData%02d.pdf',j) );

