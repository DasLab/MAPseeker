function [ D, D_err, RNA_info, primer_info, D_raw, D_ref, D_ref_err, RNA_info_ref ] = quick_look_MAPseeker( library_file, primer_file, inpath, full_length_correction_factor, combine_mode_RNA, combine_mode_primer );
%
% [ D, D_err, RNA_info, primer_info, D_raw, D_ref, D_ref_err, RNA_info_ref ] = quick_look_MAPseeker( library_file, primer_file, inpath, full_length_correction_factor, combine_mode_RNA, combine_mode_primer] );
%
%     Reads in MAPseeker output and prints useful graphs & results for your
%      notebook.
%
%    Tip:
%     Include the words 'no mod' in primers that correspond to no modification controls; script
%      will then do background subtraction. [If more than one 'no mod', e.g. several versions of the library,
%      correspondence of which no mod goes with which mod experiment is based on similarity of primer names.]
%
%     Include the word 'REFERENCE' and a reference sequence segment (e.g., 'GAGUA') in the header for
%      one of the reference RNAs and it will be used to determine full_length_correction_factor (ligation bias)
%      and to normalize data at end! (Script will automatically look for Das lab P4P6 double hairpin sequence also...)
%
%
% Input:
%
% library_file = [default: 'RNA_sequences.fasta'] all probed RNA sequences in 
%                  FASTA format. Can include structures in dot/paren notation 
%                  after each sequence (as output by Vienna's RNAfold). ('RNAstructures.fasta')
% primer_file  = [default: 'primers.fasta'] DNA sequences of reverse 
%                  transcription primers in FASTA format
% inpath       = [default: './' (current directory)] where to find
%                  MAPseeker output files: stats_ID1.txt, stats_ID2.txt, ...
%
% Optional:
% full_length_correction_factor
%     =  amount by which value of counts at site 0 is underestimated. Correction for 
%        empirically observed ~50% ssDNA ligation efficiency by circLigase
%        to 'full-length' complementary DNA created by SSIII.
%        [Default is 1.0]
% combine_mode_RNA = [default 1]. If 0, no combine. If this is 1, combine data for RNAs that have the same 
%                   names, as specified in the library_file. If this is 2, combine data 
%                   for RNAs that share any 'tags' (segments of the library_file names, separated by tabs);
%                   this is useful if, for example, RNAs are double mutants and you want to project
%                   to single mutants.
% combine_mode_primer = [default 1]. If 0, no combine If this is 1, combine data for primers that have the same 
%                   names, as specified in the primer_file. In the primer name, the text before the
%                   first tab is ignored; the text after that is assumed to be a description of the library
%                   probed or modifier and is used to determine which primers should be combined.
%
% Outputs:
%
% D           = final data after attenuation correction, background subtraction (if one of the primers is 'no mod'), and
%                 normalization (if one of the RNAs is defined as a 'REFERENCE'). Does not include 'site 0' -- first index
%                 corresponds to a stop at site 1 (just before full extension of RNA).
% D_err       = error that goes with final data
%
% RNA_info    = object with names & sequences (and structures, if given) in RNA library.
% primer_info = object with names & sequences of primers
% D_raw       = matrix of raw counts. (Note that first column is total reads of fully extended cDNA, 'site 0')
% D_ref       = final data for a REFERENCE hairpin
% D_ref_err   = error for final data for a REFERENCE hairpin
%
%
% (C) R. Das, 2012-2013

VERSION_NUM_STRING = '1.2';

%if nargin < 1; help( mfilename ); return; end;

if ~exist( 'library_file') | length( library_file ) == 0;  library_file = 'RNA_structures.fasta'; end;
if ~exist( library_file );  library_file = 'RNA_sequences.fasta'; end    
if ~exist( 'primer_file') | length( primer_file ) == 0; primer_file = 'primers.fasta';end;
if ~exist( 'inpath') | length( inpath ) == 0; inpath = './';end;
if ~exist( 'combine_mode_RNA' ) combine_mode_RNA = 1; end;
if ~exist( 'combine_mode_primer' ) combine_mode_primer = 1; end;
PRINT_STUFF = 1;

output_text_file_name = 'MAPseeker_results.txt';
fid = fopen( output_text_file_name, 'w' );

% save directory name at top of file!
print_it( fid, [pwd(),'\n\n'] ); 

output_tag = strrep( strrep( inpath, '.','' ), '/', '' ); % could be blank

RNA_info = fastaread_structures( library_file );
primer_info = fastaread( primer_file );
N_primers = length( primer_info );

% load the data
for i = 1:N_primers;  
  stats_file = sprintf( '%s/stats_ID%d.txt', inpath,i);
  print_it( fid,  sprintf('Looking for MAPseeker output file: %s\n', stats_file ) );
  if ~exist( stats_file );  print_it( fid, sprintf(  ['Could not find ',stats_file,'!\n']) ); return;end;

  % New: transpose D_raw matrix to make CE and Illumina data sets have similar format!
  D_raw{i} = load( stats_file )'; 
end
Nidx = size( D_raw{1}, 2 );

if ( combine_mode_RNA > 0 | combine_mode_primer > 0 )
  [D_raw, primer_info] = combine_by_tag_primer( D_raw, primer_info, combine_mode_primer, fid );
  [D_raw, RNA_info]    = combine_by_tag(        D_raw, RNA_info,    combine_mode_RNA );
  %output_tag = [output_tag, '_combineRNA',num2str(combine_mode_RNA),'_combinePRIMER',num2str(combine_mode_primer)];
end

N_res  = size( D_raw{1}, 1);
N_RNA  = size( D_raw{1}, 2);
N_primers = length( primer_info );
print_it( fid, sprintf(  '\n' ) );
if N_RNA  ~= length( RNA_info );
  print_it( fid, sprintf(  ['Number of lines in data files ',num2str(N_RNA),' does not match number of sequences in library ', library_file,' ', num2str(length(RNA_info)), '!\n'] ) ); 
  return;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall summary of total reads
FigHandle = figure(1);
figure_xsize = 1200;
set(FigHandle, 'Position', [50, 50, figure_xsize, 400], 'name', 'Count Summary');
clf;
for i = 1:N_primers
  num_counts_per_sequence(:,i) = sum(D_raw{i});
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
set( gca, 'xticklabel',primer_tags,'fonts',6 );

for i = 1:N_primers; 
  tag = regexprep(primer_info(i).Header,'\t','   '); 
  print_it( fid, sprintf(  '%9d %s\n', round(num_counts_per_primer( i )), tag ) );
end
  print_it( fid, sprintf(  '%9d %s\n', round(sum(num_counts_per_primer)), 'TOTAL' ) );



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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% output least common sequences and most common sequences.

[dummy,sortidx] = sort( num_counts_total );
N_display = 4;
N_display = min( N_display, N_RNA );

print_it( fid, '\n' );
print_it( fid, sprintf(  'Least common sequences:\n') );
for i= sortidx(1:N_display)'
  print_it( fid, sprintf(  '%s Counts: %8d. ID %6d: %s\n',  RNA_info(i).Sequence, round(num_counts_total(i)), i, RNA_info(i).Header ) );
end

print_it( fid, sprintf(  '\nMost common sequences:\n') );
most_common_sequences = sortidx(end : -1 : end-N_display+1)';
for i = most_common_sequences 
  print_it( fid, sprintf(  '%s Counts: %8d. ID %6d: %s\n', RNA_info(i).Sequence, round(num_counts_total(i)), i, RNA_info(i).Header ) );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure out no mod matchups.
nomod_for_each_primer  = figure_out_nomod_for_each_primer( primer_info, fid );

% look for a reference construct.
[ref_idx, ref_segment] = get_reference_construct_index( RNA_info, fid );
REFERENCE_INCLUDED = (ref_idx > 0 );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% apply attenuation correction...
AUTOFIT_ATTENUATION = 0;
if ~exist( 'full_length_correction_factor') | length( full_length_correction_factor ) == 0;  % if not inputted, try this.
  full_length_correction_factor = 1.0; % default. 
  if REFERENCE_INCLUDED
    full_length_correction_factor = full_length_correction_factor_from_each_primer( D_raw, nomod_for_each_primer, ref_segment, ref_idx, RNA_info, primer_info, fid );
    AUTOFIT_ATTENUATION = 1;
  end
end;

[ D_correct, D_correct_err ] = determine_corrected_reactivity( D_raw, full_length_correction_factor );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% background subtraction
D_final = D_correct;
D_final_err = D_correct_err;
BACKGD_SUB = sum(  nomod_for_each_primer ) > 0;
if BACKGD_SUB  
  for i = 1:N_primers
    j = nomod_for_each_primer(i);
    [D_final{i}, D_final_err{i}] = subtract_data( D_correct{i}, D_correct{j}, D_correct_err{i}, D_correct_err{j} );
  end
end


figure_ysize = min( N_RNA*150, 800);
%pause;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make 2D gray of all counts
FigHandle = figure(4);
set(FigHandle, 'Position', [250,250,600,figure_ysize], 'name', 'Counts (normalized per primer)');
clf;
make_image_plot( D_raw, RNA_info, primer_info, most_common_sequences , 'raw counts');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make 2D gray of all reactivies, corrected
FigHandle = figure(5);
set(FigHandle, 'Position', [300,300,600,figure_ysize], 'name', 'Reactivity');
clf;
make_image_plot( D_correct, RNA_info, primer_info, most_common_sequences, 'correct', 1000 );

final_image_scalefactor = 1000;
if REFERENCE_INCLUDED
  [D_final, D_final_err] = apply_reference_normalization( D_final, D_final_err, ref_idx, ref_segment, RNA_info, fid );
  final_image_scalefactor = 20;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make 2D gray of all reactivies, background subtracted
if BACKGD_SUB
  FigHandle = figure(6);
  set(FigHandle, 'Position', [350,350,600,figure_ysize],'name','Final');
  clf;
  make_image_plot( D_final, RNA_info, primer_info, most_common_sequences, 'final', final_image_scalefactor );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Make 1D plots of most common sequences
FigHandle = figure(2);
set(FigHandle, 'Position', [150,150,600,figure_ysize], 'name', 'Counts [Most Common RNAs]');
make_stair_plots( D_raw, most_common_sequences, RNA_info, primer_info, colorcode );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Make 1D plots of most common sequences, apply correction
FigHandle = figure(3);
set(FigHandle, 'Position', [200,200,600,figure_ysize],'name','Reactivity [Most Common RNAs]');
make_stair_plots( D_correct, most_common_sequences, RNA_info, primer_info, colorcode, D_correct_err );
figure(4); figure(5); if BACKGD_SUB; figure(6);end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove first position in D_final & D_final_err
for i = 1:length(D_final)
  D{i}     = D_final{i}(2:end,:);
  D_err{i} = D_final_err{i}(2:end,:);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% extract data for reference RNA (if available) into separate variable.
D_ref = {};  D_ref_err = {}; RNA_info_ref = [];
if REFERENCE_INCLUDED; 
  [D, D_err, D_ref, D_ref_err, RNA_info, RNA_info_ref ] = separate_out_reference( D, D_err, RNA_info, ref_idx );
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output signal-to-noise ratio (statistics)
if REFERENCE_INCLUDED; print_it( fid, sprintf(  '\nFollowing is for reference:\n') ); output_signal_to_noise_ratio( D_ref, D_ref_err , fid); end;
print_it( fid, sprintf(  '\nSignal-to-noise metrics:\n') );
output_signal_to_noise_ratio( D, D_err, fid );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% output RDAT
print_it( fid, sprintf(  '\nAbout to create RDAT files ... may take a while...\n' ) );
dirnames = split_string( pwd, '/' );
dirname = dirnames{end};
rdat_filename = [ dirname, '.rdat' ];
name = dirname; % maybe this should be input.
comments = { ['Output of MAPseeker v',VERSION_NUM_STRING] };

annotations = {};
annotations = [annotations, 'processing:overmodificationCorrectionExact'];
annotations = [annotations, ['processing:ligationBiasCorrection:',num2str(full_length_correction_factor,'%8.3f')] ];
if BACKGD_SUB; annotations = [annotations, 'processing:backgroundSubtraction']; end;
if REFERENCE_INCLUDED; annotations = [ annotations, ['processing:normalization:',ref_segment] ]; end;

MAPseeker_to_rdat( rdat_filename, name, D, D_err, primer_info, RNA_info, comments, annotations );
if REFERENCE_INCLUDED
  rdat_filename = [ dirname, '_REFERENCE.rdat' ];
  name = RNA_info_ref(1).Header;
  MAPseeker_to_rdat( rdat_filename, name, D_ref, D_ref_err, primer_info, RNA_info_ref, comments, annotations );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
print_it( fid, sprintf( '\n') );
if BACKGD_SUB;  print_it( fid, sprintf(  'Applied background subtraction.\n') );
else print_it( fid, sprintf(  'Did NOT apply background subtraction.\n') ); end;
if REFERENCE_INCLUDED;  print_it( fid, sprintf(  'Normalized based on reference.\n') );
else print_it( fid, sprintf(  'Did not normalize based on reference -- absolute reactivities outputted.\n') ); end;
if AUTOFIT_ATTENUATION;  print_it( fid, sprintf(  'Autofitted ligation bias for attenuation correction.\n') ); end;

if PRINT_STUFF; 
  for k = 1:5;    print_fig( k, output_tag, fid ); end;
  if  BACKGD_SUB; print_fig( 6, output_tag, fid ); end;
end
print_it( fid, sprintf('\nCreated: %s\n\n', output_text_file_name) );
fclose( fid );


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

clf;

N_RNA = size( D{1}, 2 );
N_res = size( D{1}, 1 ); % this is actually the number of residues + 1 (first value is at zero).
N_primers = length( primer_info );

% if there are lots of sequences with one length, and one with a longer length, ignore the latter.
sequence_lengths = [];
for k = 1:N_RNA;  sequence_lengths(k) = length( RNA_info(k).Sequence ); end;
sequence_lengths = sort( sequence_lengths );
L = sequence_lengths( round( 0.9*N_RNA ) );

STRUCTURES_DEFINED = ( length( RNA_info(1).Structure ) > 0 );
N_plots = N_primers + STRUCTURES_DEFINED;

imagex = zeros( N_RNA, (L * N_plots) );
plot_titles = {};
xticks = [];
xticklabels = [];

subplot(1,1,1);
% just use lower half if there aren't that many RNAs..
%if (N_RNA < 20); subplot(2,2,4); end;

boundaries = [];
if STRUCTURES_DEFINED

  scalefactor_structure = 40;
  for k = 1:N_RNA
    structure = RNA_info( k ).Structure;
    imagex( k, 1) = scalefactor_structure;
    imagex( k, strfind( structure, '.' )+1 ) = scalefactor_structure;
  end

  plot_title = 'Predicted Structure';
  if exist( 'title_tag' ); plot_title = sprintf('%s\n%30s',plot_title,title_tag ); end;

  plot_titles = [ plot_titles, plot_title ];
  xticks      = [ xticks,      [0:20:L-20] ];
  xticklabels = [ xticklabels, [0:20:L-20] ];  
end

for i = 1:N_primers

  offset = (i+STRUCTURES_DEFINED-1)*L;
  minresidx = 1 + offset; 
  maxresidx = L + offset;
  Dplot = D{i};
  if ~exist( 'scalefactor' )
    meanval = mean(mean(Dplot(2:end-1, :)));
    if meanval > 0;
      scalefactor_to_use = 20/meanval;
    else
      scalefactor_to_use = 1.0;
    end
  else
    scalefactor_to_use = scalefactor;
  end
  imagex( :, [minresidx:maxresidx] ) = Dplot(1:L,:)' * scalefactor_to_use;

  plot_title = primer_info(i).Header;
  title_cols = split_string( plot_title, '\t' ); if length( title_cols ) > 3; title_cols = title_cols(1:3);end;
  if exist( 'title_tag', 'var' ); title_cols = [title_cols, title_tag ];end;
  plot_title = join_string( title_cols, '\n' );
  plot_titles = [ plot_titles, plot_title ];

  xticks      = [ xticks,      [0:20:L-20] + offset];
  xticklabels = [ xticklabels, [0:20:L-20] ];
  
  boundaries = [boundaries, maxresidx ];
  
end
image( [0:(L*N_plots)-1], [1:N_RNA], imagex );
set( gca,'tickdir','out','xtick',xticks,'xticklabel',xticklabels,'fontw','bold','fonts',6);
make_lines( boundaries, 'b', 0.25 );

for i = 1:N_plots
  hold on; 
  %plot( (i*N_res - 1 + 0.5) * [1 1], [0 N_RNA+0.5], 'k','linew',2);
  h = text( (i - 1) * L, 0.5, plot_titles{i} );
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
  plot( L*N_plots - 20, idx, 'ro','markersize',5,'markerfacecolor','r','clipping','off');
  %h = text( N_res*N_plots - 15, idx,  regexprep( RNA_info( idx ).Header, '\t','\n' ) );
  %set(h,'clipping','off','verticalalign','middle','fontweight','bold','fontsize',7,'interpreter','none');
end

colormap( 1 - gray(100))
set(gcf, 'PaperPositionMode','auto','color','white');

xlabel( basename(pwd),'interpreter','none' );
%print( '-dpdf',sprintf( 'EteRNA_PlayerProjects_RawData%02d.pdf',j) );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function make_lines( line_pos, colorcode, linewidth );

ylim = get(gca,'ylim');
hold on
for i = 1:length( line_pos );
  hold on
  plot( 0.5+line_pos(i)*[1 1], [ylim(1) ylim(2)],'-','color',colorcode,'linewidth',linewidth); 
end
hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ref_idx,ref_segment] = get_reference_construct_index( RNA_info, fid );

N_RNA = length( RNA_info );
ref_idx = 0;
ref_segment = ''; % must be repeated exactly twice in sequence!
for i = 1:N_RNA; 
  if ~isempty( strfind( RNA_info(i).Header, 'REFERENCE' ) )
    ref_idx = i;
    cols = split_string( RNA_info(i).Header, sprintf('\t') );
    for m = 1:length( cols )
      if length( strfind( RNA_info(i).Sequence, cols{m} ) ) == 2; 
	ref_segment = cols{m};
	break;    
      end
    end
    if length( ref_segment ) == 0; 
      print_it( fid, sprintf(  'Found REFERENCE tag in RNA sequences, but could not find a sequence segment like GAGUA that is then repeated exactly twice in the sequence!!\n') );
      error(  'Found REFERENCE tag in RNA sequences, but could not find a sequence segment like GAGUA that is then repeated exactly twice in the sequence!!\n')
    end
  end
end

if ref_idx > 0; return; end;

P4P6_double_ref_sequence = 'GGCCAAAGGCGUCGAGUAGACGCCAACAACGGAAUUGCGGGAAAGGGGUCAACAGCCGUUCAGUACCAAGUCUCAGGGGAAACUUUGAGAUGGCCUUGCAAAGGGUAUGGUAAUAAGCUGACGGACAUGGUCCUAACCACGCAGCCAAGUCCUAAGUCAACAGAUCUUCUGUUGAUAUGGAUGCAGUUCAAAACCAAACCGUCAGCGAGUAGCUGACAAAAAGAAACAACAACAACAAC';
for i = 1:N_RNA;
  if strcmp( RNA_info(i).Sequence, P4P6_double_ref_sequence ) 
    ref_idx = i;
    ref_segment = 'GAGUA';
    break;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nomod_for_each_primer = figure_out_nomod_for_each_primer( primer_info, fid );

N_primer = length( primer_info );
nomod_for_each_primer = zeros( N_primer, 1 );

nomod_primers = [];
nomod_primer_tags = {};
print_it( fid, sprintf( '\n') );
for i = 1:N_primer
  if ~isempty( strfind( lower(primer_info(i).Header), 'no mod' ) );
    nomod_primers = [ nomod_primers, i ];
    nomod_primer_tags = [nomod_primer_tags, primer_info(i).Header ];
    print_it( fid, sprintf(  'Found background measurement (''no mod'') in primer %d [%s]\n',i, primer_info(i).Header) );
  end
end

if length( nomod_primers) == 0; return; end; % no backgrounds found!

print_it( fid, sprintf(  '\n') );
for i = 1:N_primer
  similar_fields = [];
  primer_tag = primer_info(i).Header;
  for m = 1:length( nomod_primer_tags );
    similar_fields( m ) = find_tag_similarity( primer_tag, nomod_primer_tags{m} );
  end
  [dummy, idx] = max( similar_fields );
  nomod_for_each_primer(i) = nomod_primers( idx );
  print_it( fid, sprintf(  'No mod for primer %d is primer %d\n', i,  ...
	   nomod_for_each_primer(i) ...
	   ) );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s = find_tag_similarity( tag1, tag2 )

% split at spaces and tabs:
cols1 = split_string( strrep( tag1, sprintf('\t'),' ') );
cols2 = split_string( strrep( tag2, sprintf('\t'),' ') );

s = 0;
for i = 1:length( cols1 )
  s = s + sum( strcmp( cols1{i}, cols2 ) );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  full_length_correction_factor = full_length_correction_factor_from_each_primer( D, nomod_for_each_primer, ref_segment, ref_idx, RNA_info, primer_info, fid );

FigHandle = figure(7);
figure_xsize = 1200;
set(FigHandle, 'Position', [70, 150, figure_xsize, 400], 'name', 'Ligation Bias Correction Factor');
set(gcf, 'PaperPositionMode','auto','color','white');

N_primer = length( primer_info );
all_factors = NaN * ones( N_primer, 1 );

print_it( fid, sprintf(  '\n' ) );
for i = 1:N_primer
  j = nomod_for_each_primer(i);
  if ( i ~= j )
    signal = D{i}(:, ref_idx);
    if ( j > 0 )
      background = D{j}(:, ref_idx);
    else
      background = 0 * signal;
      print_it( fid, sprintf(  'Could not figure out no mod! Specify ''no mod'' in a tab-delimited field for at least one primer in primers.fasta!\n' ) );
    end
    all_factors(i) = estimate_full_length_correction_factor( signal, background, RNA_info(ref_idx).Sequence, ref_segment);
    print_it( fid, sprintf(  'Estimated full length correction factor from primer %d: %8.3f   [%30s]\n', i, all_factors(i), strrep( primer_info(i).Header, '\t',' ') ) );
  end  
end

gp = find( ~isnan( all_factors ) );
full_length_correction_factor = mean( all_factors(gp) );

print_it( fid, sprintf(  'Estimated full length correction factor [AVERAGE]: %8.3f\n', full_length_correction_factor ) );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [D_norm, D_norm_err] = apply_reference_normalization( D, D_err, ref_idx, ref_segment, RNA_info, fid );

sequence = RNA_info(ref_idx).Sequence;
gp = strfind( sequence, ref_segment ); % double reference

D_norm = D;
D_norm_err = D_err;

print_it( fid, sprintf(  '\n' ) );
for i = 1:length( D )
  D_ref = D{i}(:, ref_idx)'; 
  D_ref_err = D_err{i}(:, ref_idx)'; 

  ref_pos =  [ gp(1) + [1:length(ref_segment)], gp(2) + [1:length(ref_segment)] ];
  scalefactor = mean( D_ref( ref_pos ) );
  if scalefactor > 0
    print_it( fid, sprintf(  'Mean reactivity at reference positions for primer %d: %8.4f\n', i,  scalefactor ) );
    D_norm{i} = D{i} / scalefactor;
    D_norm_err{i} = D_err{i} / scalefactor;
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function print_fig( k, output_tag, fid );
figure(k);
figure_name = [output_tag,'Figure',num2str(k),'.eps'];
print( '-depsc2',figure_name ); 
print_it( fid, sprintf(  'Created: %s\n', figure_name ) );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [D, D_err, D_ref, D_ref_err, RNA_info, RNA_info_ref ] = separate_out_reference( D, D_err, RNA_info, ref_idx );

no_ref_idx = setdiff( [ 1 : size( D{1}, 2) ], ref_idx )';
for i = 1:length(D)
  D_ref{i}     = D{i}(:, ref_idx);
  D_ref_err{i} = D_err{i}(:, ref_idx);
  D{i}         = D{i}(:, no_ref_idx);
  D_err{i}     = D_err{i}(:, no_ref_idx);    
end

RNA_info_ref = RNA_info( ref_idx );
RNA_info     = RNA_info( no_ref_idx );

[D,D_err]         = truncate_based_on_zeros( D    , D_err);
[D_ref,D_ref_err] = truncate_based_on_zeros( D_ref, D_ref_err);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [D,D_err]         = truncate_based_on_zeros( D    , D_err);
maxidx = 1;
for i = 1:length( D )
  total_reactivity = sum( D{i}, 2 );
  maxidx_reactivity = max( find( abs( total_reactivity ) > 0 ) );
  if ~isempty( maxidx_reactivity) maxidx = max( [maxidx, maxidx_reactivity] ); end;
end
for i = 1:length( D )
  D{i}     = D{i}    (1:maxidx,:);
  D_err{i} = D_err{i}(1:maxidx,:);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output_signal_to_noise_ratio( D, D_err, fid );

for i = 1:length(D)
  SN_ratio = estimate_signal_to_noise_ratio( D{i}, D_err{i} );
  print_it( fid, sprintf(  'Signal-to-noise ratio for primer %d:  %8.3f [%s]\n', i, SN_ratio, classify_signal_to_noise_ratio( SN_ratio ) ) );
end

