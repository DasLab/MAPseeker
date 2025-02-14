function [ D, D_err, RNA_info, primer_info, D_raw, D_ref, D_ref_err, RNA_info_ref, prjc_clvg, prjc_mdf, prjc_clvg_err, prjc_mdf_err ] = quick_look_MAPseeker( library_file, primer_file, inpath, full_length_correction_factor, more_options )
%
% [ D, D_err, RNA_info, primer_info, D_raw, D_ref, D_ref_err, RNA_info_ref, prjc_clvg, prjc_mdf  ] = ...
%               QUICK_LOOK_MAPSEEKER( library_file, primer_file, inpath, full_length_correction_factor, more_options );
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
%                  after each sequence (as output by Vienna's RNAfold). ('RNA_structures.fasta')
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
%        [Default is 0.5]
% more_options
%     = {'combine_RNA_by_tag','no_combine_primer', ...}
%          'force_run'          = rerun MAPseeker even if output files from prior
%                                  run (stats_id*.txt) are present
%          'combine_RNA_by_tag' =  If specified, combine data
%                   for RNAs that share any 'tags' (segments of the library_file names, separated by tabs);
%                   this is useful if, for example, RNAs are double mutants and you want to project
%                   to single mutants.
%          'combine_RNA_by_name' = Combine data for RNAs that have the same
%                   names, as specified in the library_file.
%          'no_combine_primer' = Turn off default behavior to combine data for primers that have the same
%                   names, as specified in the primer_file. In the primer name, the text before the
%                   first tab is ignored; the text after that is assumed to be a description of the library
%                   probed or modifier and is used to determine which primers should be combined.
%          'noSHAPEscores'   = turn off output of SHAPE scores into RDAT.
%          'no_output_fig'   = turn off output of figures.
%          'no_output_rdat'  = turn off output of RDAT files.
%          'output_raw_rdat' = save raw counts into a RAW.rdat file.
%          'no_stair_plots'  = turn off stair plots
%          'strict_stats'    = use strict_stats* ffiles (not stats_* files).
%          'no_norm'         = no boxplot or reference-based normalization
%          'no_backgd_sub'   = no background subtraction
%          'skip_reference'  = don't look at reference even if its specified in
%                                     RNA_sequences.fasta
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
% prjc_clvg   = 1D projection of cleavage
% prjc_mdf    = 1D projection of modification
%
%
% (C) R. Das, 2012-2013

VERSION_NUM_STRING = '1.3';

%if nargin < 1; help( mfilename ); return; end;
if ~exist( 'inpath','var') || isempty( inpath ); inpath = './';end;

if exist( 'primer_file','var' ) & ~exist( primer_file, 'file' ) & ~exist( [inpath,primer_file],'file' ); 
    fprintf( '\n\nCould not find input primer file: %s\n\n', primer_file ); 
    return;
end
if ~exist( 'primer_file','var') || isempty( primer_file ); primer_file = [inpath,'/primers.fasta'];end;
if ~exist( primer_file,'file' ) & exist( './primers.fasta','file' ); primer_file = './primers.fasta'; end

if exist( 'library_file','var' ) & ~exist( library_file, 'file' ) & ~exist( [inpath,library_file],'file' ); 
    fprintf( '\n\nCould not find input library file: %s\n\n', library_file ); 
    return;
end
if ~exist( 'library_file','var') || isempty( library_file );  library_file = [inpath,'/RNA_structures.fasta']; end;
if ~exist( library_file,'file' ) & exist( ['./RNA_structures.fasta'],'file' ); library_file = './RNA_structures.fasta'; end
if ~exist( library_file,'file' ) & exist( [inpath,'/RNA_sequences.fasta'],'file' ); library_file = [inpath,'/RNA_sequences.fasta']; end
if ~exist( library_file,'file')  & exist( './RNA_sequences.fasta','file' ); library_file = './RNA_sequences.fasta'; end
if ~exist( library_file,'file' ) & ~exist( './MOHCA.fasta' ); 
    fprintf( '\n\nCould not find RNA_sequences.fasta, RNA_structures.fasta, or MOHCA.fasta\n\n' ); 
    return;
end

FULL_LENGTH_CORRECTION_FACTOR_SPECIFIED = 0;
if ~exist( 'full_length_correction_factor','var') || isempty( full_length_correction_factor );  % if not inputted, try this.
    full_length_correction_factor = 0.5; % default.
else
    FULL_LENGTH_CORRECTION_FACTOR_SPECIFIED = 1;
end
if ~exist( 'more_options','var' ) more_options = {}; end;
PRINT_STUFF = isempty( find( strcmp( more_options, 'no_output_fig' ) ) );
FORCE_RUN = ~isempty( find( strcmp( more_options, 'force_run' ) ) );

output_text_file_name = 'MAPseeker_results.txt';
fid = fopen( output_text_file_name, 'w' );

% save directory name at top of file!
print_it( fid, [pwd(),'\n\n'] );

output_tag = strrep( strrep( inpath, '.','' ), '/', '' ); % could be blank

if ~exist( library_file, 'file' ) && exist( 'MOHCA.fasta','file' );
    get_frag_library;
end

RNA_info = fastaread_structures( library_file );
primer_info = fastaread( primer_file );
N_primers = length( primer_info );

% check if this is MOHCA run.
MOHCA_flag = isMOHCA( RNA_info );

% load the data

% run MAPseeker executable if we can't find the file...
stats_prefix = 'stats';
STRICT_STATS = ~isempty( find( strcmp( more_options, 'strict_stats' ) ) );
if STRICT_STATS; stats_prefix = 'strict_stats'; end;

stats_file = sprintf( './%s_ID%d.txt', stats_prefix, 1);
if ~exist( stats_file, 'file' ) || FORCE_RUN
    align_all = MOHCA_flag;
    library_file_just_sequences = library_file;
    if exist( 'RNA_sequences.fasta','file' ); library_file_just_sequences = 'RNA_sequences.fasta'; end;
    if exist( [inpath,'/RNA_sequences.fasta'],'file' ); library_file_just_sequences = [inpath,'/RNA_sequences.fasta']; end;
    run_map_seeker_executable( library_file_just_sequences, primer_file, inpath, align_all );
end
if exist( 'MAPseeker_executable.log' )
  % read in this log file and put to output...
  print_it( fid, 'Output of MAPseeker_executable.log:\n' );
  fid2 = fopen( 'MAPseeker_executable.log' );
  while ~feof( fid2 );    print_it( fid, [fgetl( fid2 ),'\n'] );    end
  print_it( fid, '\n' );
  fclose( fid2 );
end

for i = 1:N_primers;
    stats_file = sprintf( '%s_ID%d.txt', stats_prefix, i);
    print_it( fid,  sprintf('Looking for MAPseeker output file: %s\n', stats_file ) );
    if ~exist( stats_file, 'file' );  print_it( fid, sprintf(  ['Could not find ',stats_file,'!\n']) ); return;end;
    
    % New: transpose D_raw matrix to make CE and Illumina data sets have similar format!
    D_raw{i} = load( stats_file )';
end
Nidx = size( D_raw{1}, 2 );

combine_mode_RNA = 0;
combine_mode_primer = 1;
if ~isempty( find( strcmp( more_options, 'no_combine_primer' ) ) );   combine_mode_primer = 0; end
if ~isempty( find( strcmp( more_options, 'combine_RNA_by_tag' ) ) );  combine_mode_RNA = 1; end
if ~isempty( find( strcmp( more_options, 'combine_RNA_by_name' ) ) ); combine_mode_RNA = 2; end

if ( combine_mode_RNA > 0 || combine_mode_primer > 0 )
    [D_raw, primer_info] = combine_by_tag_primer( D_raw, primer_info, combine_mode_primer, fid );
    [D_raw, RNA_info]    = combine_by_tag(        D_raw, RNA_info,    combine_mode_RNA );
    %output_tag = [output_tag, '_combineRNA',num2str(combine_mode_RNA),'_combinePRIMER',num2str(combine_mode_primer)];
end

N_res  = size( D_raw{1}, 1);
N_RNA  = size( D_raw{1}, 2);
N_primers = length( primer_info );
print_it( fid, '\n' );
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
set( gca, 'xticklabel',primer_tags,'fontsize',6 );
set( gca, 'XTick', 1:length(primer_tags) );

for i = 1:N_primers;
    tag = regexprep(primer_info(i).Header,'\t','   ');
    print_it( fid, sprintf(  '%9d %s\n', round(num_counts_per_primer( i )), tag ) );
end
print_it( fid, sprintf(  '%9d %s\n', round(sum(num_counts_per_primer)), 'TOTAL' ) );


ylabel( sprintf( 'Distributions of %9d counts over primers',round(total_counts)));
xticklabel_rotate;
set(gcf, 'PaperPositionMode','auto','color','white');
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

[~,sortidx] = sort( num_counts_total );
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

if any(contains(more_options,'skip_reference')) && REFERENCE_INCLUDED
    for i = 1:N_primers;   D_raw{i}(:,ref_idx) = 0; end
    REFERENCE_INCLUDED = 0;
end;

if REFERENCE_INCLUDED && ( sum(num_counts_per_sequence( ref_idx, : )) < 5);
    REFERENCE_INCLUDED = 0;
    print_it( fid, 'Not enough counts in reference sequence --> WILL NOT USE!!\n' );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% apply attenuation correction...
AUTOFIT_ATTENUATION = 0;
if REFERENCE_INCLUDED && ~FULL_LENGTH_CORRECTION_FACTOR_SPECIFIED
    full_length_correction_factor = full_length_correction_factor_from_each_primer( D_raw, nomod_for_each_primer, ref_segment, ref_idx, RNA_info, primer_info, fid );
    AUTOFIT_ATTENUATION = 1;
end

[ D_correct, D_correct_err ] = determine_corrected_reactivity( D_raw, full_length_correction_factor );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% background subtraction
D_final = D_correct;
D_final_err = D_correct_err;
BACKGD_SUB = sum(  nomod_for_each_primer ) > 0 && isempty(find( strcmp( more_options, 'no_backgd_sub' ) ));
if BACKGD_SUB
    for i = 1:N_primers
        j = nomod_for_each_primer(i);
        [D_final{i}, D_final_err{i}] = subtract_data( D_correct{i}, D_correct{j}, D_correct_err{i}, D_correct_err{j} );
    end
end


figure_ysize = min( N_RNA*150, 800);
drawnow;
%pause;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make 2D gray of all counts
FigHandle = figure(4);
set(FigHandle, 'Position', [250,250,800,figure_ysize], 'name', 'Counts (normalized per primer)');
clf;
make_image_plot( D_raw, RNA_info, primer_info, most_common_sequences , 'raw counts');
drawnow;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make 2D gray of all reactivities, corrected
FigHandle = figure(5);
set(FigHandle, 'Position', [300,300,800,figure_ysize], 'name', 'Reactivity');
clf;
make_image_plot( D_correct, RNA_info, primer_info, most_common_sequences, 'correct', 1000 );
drawnow;

BOXPLOT_NORMALIZATION = 0;
NORM = isempty( find( strcmp( more_options, 'no_norm' ) ) );
if NORM
    if REFERENCE_INCLUDED
        [D_final, D_final_err] = apply_reference_normalization( D_final, D_final_err, ref_idx, ref_segment, RNA_info, primer_info, fid );
    else
        [D_final, D_final_err] = apply_boxplot_normalization( D_final, D_final_err, fid );
        BOXPLOT_NORMALIZATION = 1;
    end
    final_image_scalefactor = 20;
else
    for i = 1:length(D_final)
        meanfactor(i) = mean(D_final{i}(:));
    end
    final_image_scalefactor = 5/mean(meanfactor);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make 2D gray of all reactivities, background subtracted
if BACKGD_SUB
    FigHandle = figure(6);
    set(FigHandle, 'Position', [350,350,800,figure_ysize],'name','Final');
    clf;
    make_image_plot( D_final, RNA_info, primer_info, most_common_sequences, 'final', final_image_scalefactor );
end


MAKE_STAIR_PLOTS = isempty( find( strcmp( more_options, 'no_stair_plots' ) ) );

if MAKE_STAIR_PLOTS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Make 1D plots of most common sequences
    FigHandle = figure(2);
    set(FigHandle, 'Position', [150,150,600,figure_ysize], 'name', 'Counts [Most Common RNAs]');
    make_stair_plots( D_raw, most_common_sequences, RNA_info, primer_info, colorcode );
    drawnow;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Make 1D plots of most common sequences, apply correction
    FigHandle = figure(3);
    set(FigHandle, 'Position', [200,200,600,figure_ysize],'name','Reactivity [Most Common RNAs]');
    make_stair_plots( D_correct, most_common_sequences, RNA_info, primer_info, colorcode, D_correct_err );
    drawnow;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove first position in D_final & D_final_err
for i = 1:length(D_final)
    D{i}     = D_final{i}(2:end,:);
    D_err{i} = D_final_err{i}(2:end,:);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% extract data for reference RNA (if available) into separate variable.
D_ref = {};  D_ref_err = {}; RNA_info_ref = [];
D_raw_err = cell_sqrt( D_raw );
if REFERENCE_INCLUDED;
    [D_raw, D_raw_err, D_raw_ref, D_raw_ref_err ]         = separate_out_reference( D_raw, D_raw_err, RNA_info, ref_idx );
    [D,     D_err,     D_ref,     D_ref_err, RNA_info, RNA_info_ref ] = separate_out_reference( D, D_err, RNA_info, ref_idx );
end
[D,D_err]         = truncate_based_on_zeros( D    , D_err);
[D_ref,D_ref_err] = truncate_based_on_zeros( D_ref, D_ref_err);
if REFERENCE_INCLUDED;
    [D_raw,D_raw_err]         = truncate_based_on_zeros( D_raw    , D_raw_err);
    [D_raw_ref,D_raw_ref_err] = truncate_based_on_zeros( D_raw_ref, D_raw_ref_err);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output signal-to-noise ratio (statistics)
if REFERENCE_INCLUDED; print_it( fid, sprintf(  '\nFollowing is for reference:\n') ); output_signal_to_noise_ratio( D_ref, D_ref_err , fid); end;
print_it( fid, sprintf(  '\nSignal-to-noise metrics:\n') );
output_signal_to_noise_ratio( D, D_err, fid );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1D Projection output for MOHCA & modify-and-map
if MOHCA_flag;
    figure(7);
    print_it( fid, '\n\n');
    [clvg_rates, mdf_rates, prjc_clvg, prjc_mdf, prjc_clvg_err, prjc_mdf_err] = determine_cleavage_modification_percentage (D_raw, primer_info, full_length_correction_factor, [], colorcode);
    print_it( fid, sprintf('\n Cleavage Rates metrics:\n'));
    print_it( fid, sprintf('\t\t\tPercentage Uncleaved\t\tMean Cleavage Events per RNA\n'));
    for i = 1:size(clvg_rates,2);
        print_it( fid, sprintf(['primer ',num2str(i),':\t\t',num2str(clvg_rates(1,i)),'\t\t\t',num2str(clvg_rates(2,i)),'\n']));
    end;
    print_it( fid, sprintf('\n Modification Rates metrics:\n'));
    print_it( fid, sprintf('\t\t\tMean Modification Events per RNA\n'));
    for i = 1:length(mdf_rates);
        print_it( fid, sprintf(['primer ',num2str(i),':\t\t',num2str(mdf_rates(i)),'\n']));
    end;
else
    prjc_clvg = [];
    prjc_mdf = [];
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% output RDAT
OUTPUT_RDAT = isempty( find( strcmp( more_options, 'no_output_rdat' ) ) );
OUTPUT_RAW = ~isempty( find( strcmp( more_options, 'output_raw_rdat' ) ) ) || MOHCA_flag;

if OUTPUT_RDAT
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
    if REFERENCE_INCLUDED;    annotations = [ annotations, ['processing:normalization:',ref_segment] ];
    elseif BOXPLOT_NORMALIZATION;  annotations = [ annotations, 'processing:normalization:boxplot' ];
    end
    
    if REFERENCE_INCLUDED
        ref_name = RNA_info_ref(1).Header;
        if OUTPUT_RAW
            rdat_raw_filename_reference = [ dirname, '_REFERENCE.RAW.rdat' ];
            MAPseeker_to_rdat_by_primer( rdat_raw_filename_reference, ref_name, D_raw_ref, D_raw_ref_err, primer_info, RNA_info_ref, comments, annotations, 1 );
        end
        rdat_filename_reference = [ dirname, '_REFERENCE.rdat' ];
        MAPseeker_to_rdat_by_primer( rdat_filename_reference, ref_name, D_ref, D_ref_err, primer_info, RNA_info_ref, comments, annotations );
    end
    
    if OUTPUT_RAW
        rdat_raw_filename = [ dirname, '.RAW.rdat' ];
        MAPseeker_to_rdat_by_primer( rdat_raw_filename, name, D_raw, D_raw_err, primer_info, RNA_info, comments, annotations, 1 );
        % Problem! Annotations taken from annotations for reactivity-analyzed RDATs, so include 'processing:normalization:boxplot' 
    end

    MAPseeker_to_rdat_by_primer( rdat_filename, name, D, D_err, primer_info, RNA_info, comments, annotations );
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
putSHAPEscores = isempty( find( strcmp( more_options, 'noSHAPEscores' ) ) );
if (exist( 'put_SHAPEscore_into_RDAT') == 2) && ( size( D{1},2) > 1 && check_eterna(RNA_info(1).Header) ) && putSHAPEscores && OUTPUT_RDAT
    print_it( fid, 'Found put_SHAPEscore_into_RDAT, and this looks like a cloud lab run.\n' );
    rdat_filename_with_scores =  strrep( rdat_filename, '.rdat','_WITH_SCORES.rdat' );
    print_it( fid, sprintf('Creating: %s\n', rdat_filename_with_scores) );
    figure(7);
    r = MAPseeker_to_rdat( rdat_filename, name, D, D_err, primer_info, RNA_info, comments, annotations );
    put_SHAPEscore_into_RDAT( r, rdat_filename_with_scores );
end

%r

% if exist( 'print_out_rdat') == 2
%   figure(8);
%   print_it( fid, 'Found print_out_rdat ... creating postscript files.\n' );
%   print_out_rdat( r );
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
print_it( fid, '\n' );
if BACKGD_SUB;  
    print_it( fid, sprintf(  'Applied background subtraction.\n') );
else
    print_it( fid, sprintf(  'Did NOT apply background subtraction.\n') ); 
end;
if REFERENCE_INCLUDED;  
    print_it( fid, sprintf(  'Normalized based on reference.\n') );
elseif BOXPLOT_NORMALIZATION; 
    print_it( fid, sprintf(  'Did not normalize based on reference -- used boxplot_normalize on each primer.\n') ); 
end;
if AUTOFIT_ATTENUATION;  print_it( fid, sprintf(  'Autofitted ligation bias for attenuation correction.\n') ); end;

print_it( fid, '\n' );
if PRINT_STUFF;
    if exist( 'print_save_figure','file' );
        print_save_figure(figure(1), 'Figure1_CountSummary', '', 1);
        print_save_figure(figure(2), 'Figure2_StairCounts', '', 1);
        print_save_figure(figure(3), 'Figure3_StairReactivity', '', 1);
        print_save_figure(figure(4), 'Figure4_2DCounts', '', 1);
        print_save_figure(figure(5), 'Figure5_2DReactivity', '', 1);
        if BACKGD_SUB; print_save_figure(figure(6), 'Figure6_BackgroundSubtracted', '', 1 ); end;
        if MOHCA_flag; print_save_figure(figure(7), 'Figure7_1DProjection', '', 1); end;
    else
        for k = 1:5;
            print_fig( k, output_tag, fid );
        end;
        if  BACKGD_SUB; print_fig( 6, output_tag, fid ); end;
        if  MOHCA_flag; print_fig( 7, output_tag, fid ); end;
    end;
end;
print_it( fid, sprintf('\nCreated: %s\n\n', output_text_file_name) );
fclose( fid );


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function my_bar_graph( x )
% copied from some crazy matlab code on mathworks.com
h = bar( x,'grouped','linew',2);



ch = get(h,'Children'); %get children of the bar group
fvd = get(ch,'Faces'); %get faces data
fvcd = get(ch,'FaceVertexCData'); %get face vertex cdata
if length(fvd ) > 0
    %[zs, izs] = sort(x); %sort the rows ascending by first columns
    for i = 1:length(x)
        row = i;%izs(i);
        fvcd(fvd(row,:)) = i; %adjust the face vertex cdata to be that of the row
    end
    set(ch,'FaceVertexCData',fvcd) %set to new face vertex cdata
end

% actually show numbers over bars.
for i = 1:length(x)
    text( i, x(i),  num2str(round(x(i))), 'horizontalalign','center','verticalalign','bottom');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function make_image_plot( D, RNA_info, primer_info, most_common_sequences, title_tag, scalefactor )

clf;

N_res = size( D{1}, 1 ); % this is actually the number of residues + 1 (first value is at zero).
N_RNA = size( D{1}, 2 );
N_primers = length( primer_info );

% if there are lots of sequences with one length, and one with a longer length, ignore the latter.
sequence_lengths = [];
for k = 1:N_RNA;  sequence_lengths(k) = length( RNA_info(k).Sequence ); end;
sequence_lengths = sort( sequence_lengths );

% following was meant to remove crazy outliers.
%L = sequence_lengths( round( 0.9*N_RNA ) );
m = mean( sequence_lengths );
s = std( sequence_lengths );
if s == 0
    gp = 1:length(sequence_lengths);
else
    gp = find( (sequence_lengths - m) < 5 * s );
end
L = max( sequence_lengths(gp) );

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
    
    plot_title = 'Pred. Struct.';
    if exist( 'title_tag','var' ); plot_title = sprintf('%s\n%s',plot_title,title_tag ); end;
    
    plot_titles = [ plot_titles, plot_title ];
    xticks      = [ xticks,      [0:20:L-20] ];
    xticklabels = [ xticklabels, [0:20:L-20] ];
end

offset_to_conventional = 0;
MOHCA = isMOHCA( RNA_info );
if MOHCA
    offset_to_conventional = str2num( get_tag_from_string( RNA_info( end ).Header, 'offset' ) );
end
if isempty( offset_to_conventional ) offset_to_conventional = 0; end;

for i = 1:N_primers
    
    bound_offset = (i+STRUCTURES_DEFINED-1)*L;
    minresidx = 1 + bound_offset;
    maxresidx = L + bound_offset;
    Dplot = D{i};
    if ~exist( 'scalefactor','var' )
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
    title_cols = split_string( plot_title, '\t' ); if length( title_cols ) > 5; title_cols = title_cols(1:5);end;
    if exist( 'title_tag', 'var' ); title_cols = [title_cols, title_tag ];end;
    plot_title = join_string( title_cols, sprintf('\n') );
    plot_titles = [ plot_titles, plot_title ];
    
    xticks      = [ xticks,      [0:L] + bound_offset];
    xticklabels = [ xticklabels, [0:L] + offset_to_conventional ];
    
    boundaries = [boundaries, maxresidx ];
    
end
image( [0:(L*N_plots)-1], [1:N_RNA], imagex );

gp = find( mod(xticklabels,20) == 0 );
% remove repeated xticks
for i = 1:length(gp)-1
    if xticks(gp(i)) == xticks(gp(i+1));
        gp(i) = NaN;
    end;
end;
gp = gp(~isnan(gp));
set( gca,'tickdir','out','xtick',xticks(gp),'xticklabel',xticklabels(gp),'fontw','bold','fontsize',6);
boundaries = boundaries( 1:end-1);
make_lines( boundaries, 'b', 0.25 );
make_lines( boundaries-1, 'b', 0.25 );

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

if MOHCA
    for i = 1:length( RNA_info )
        lig_pos(i) = str2num( get_tag_from_string( RNA_info(i).Header, 'lig_pos' ) );
    end
    gp = find( mod(lig_pos,20) == 0 );
    set( gca,'ytick',gp,'yticklabel',lig_pos( gp ) );
    set( gca,'xgrid','on','ygrid','on');
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

if MOHCA; axis image; end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function make_lines( line_pos, colorcode, linewidth )

ylim = get(gca,'ylim');
hold on
for i = 1:length( line_pos );
    hold on
    plot( 0.5+line_pos(i)*[1 1], [ylim(1) ylim(2)],'-','color',colorcode,'linewidth',linewidth);
end
hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ref_idx,ref_segment] = get_reference_construct_index( RNA_info, fid )

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
        if isempty( ref_segment );
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
function nomod_for_each_primer = figure_out_nomod_for_each_primer( primer_info, fid )

N_primer = length( primer_info );
nomod_for_each_primer = zeros( N_primer, 1 );

nomod_primers = [];
nomod_primer_tags = {};
print_it( fid, '\n' );
for i = 1:N_primer
    if ~isempty( strfind( lower(primer_info(i).Header), 'no mod' ) );
        nomod_primers = [ nomod_primers, i ];
        nomod_primer_tags = [nomod_primer_tags, primer_info(i).Header ];
        print_it( fid, sprintf(  'Found background measurement (''no mod'') in primer %d [%s]\n',i, primer_info(i).Header) );
    end
end

if isempty( nomod_primers); return; end; % no backgrounds found!

print_it( fid, sprintf(  '\n') );
for i = 1:N_primer
    similar_fields = [];
    primer_tag = primer_info(i).Header;
    for m = 1:length( nomod_primer_tags );
        similar_fields( m ) = find_tag_similarity( primer_tag, nomod_primer_tags{m} );
    end
    [~, idx] = max( similar_fields );
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
function  full_length_correction_factor = full_length_correction_factor_from_each_primer( D, nomod_for_each_primer, ref_segment, ref_idx, RNA_info, primer_info, fid )

FigHandle = figure(7);
figure_xsize = 1200;
set(FigHandle, 'Position', [70, 150, figure_xsize, 400], 'name', 'Ligation Bias Correction Factor');
set(gcf, 'PaperPositionMode','auto','color','white');

N_primer = length( primer_info );
all_factors = NaN * ones( N_primer, 1 );

print_it( fid, '\n' );
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
function  [D_norm, D_norm_err] = apply_reference_normalization( D, D_err, ref_idx, ref_segment, RNA_info, primer_info, fid )

sequence = RNA_info(ref_idx).Sequence;
gp = strfind( sequence, ref_segment ); % double reference

D_norm = D;
D_norm_err = D_err;

print_it( fid, '\n' );
for i = 1:length( D )
    D_ref = D{i}(:, ref_idx)';
    D_ref_err = D_err{i}(:, ref_idx)';
    
    % note that this is offset by one.
    ref_pos_in =  [ gp(1) + [1:length(ref_segment)], gp(2) + [1:length(ref_segment)] ];
    
    % special -- check if this is DMS or CMCT
    ref_pos = ref_pos_in;
    if ~isempty( strfind( primer_info(i).Header, 'DMS' ) )
        ref_pos = [];
        for m = ref_pos_in; if( sequence(m-1) == 'A' || sequence(m-1) == 'C' ) ref_pos = [ref_pos, m ]; end; end;
    end
    if ~isempty( strfind( primer_info(i).Header, 'CMCT' ) )
        ref_pos = [];
        for m = ref_pos_in; if( sequence(m-1) == 'U' ) ref_pos = [ref_pos, m ]; end; end;
    end
    
    % weight by statistical error.
    weights = 1./D_ref_err.^2;
    scalefactor = sum( D_ref(ref_pos) .* weights(ref_pos) )/sum( weights( ref_pos ) );
    if scalefactor > 0
        print_it( fid, sprintf(  'Mean reactivity at reference positions %s for primer %d: %8.4f\n', make_tag_with_dashes( ref_pos ), i,  scalefactor ) );
        D_norm{i} = D{i} / scalefactor;
        D_norm_err{i} = D_err{i} / scalefactor;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [D_norm, D_norm_err] = apply_boxplot_normalization( D, D_err, fid )

D_norm = D;
D_norm_err = D_err;

for i = 1:length( D )
    [D_norm{i},D_norm_err{i},scalefactor] = mapseeker_boxplot_normalize( D{i}, D_err{i} );
    print_it( fid, sprintf(  'Boxplot-based normalization: following reactivity is rescaled to unity for primer %d: %10.6f\n', i,  scalefactor ) );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function print_fig( k, output_tag, fid )
figure(k);
figure_name = [output_tag,'Figure',num2str(k),'.eps'];
print( '-depsc2',figure_name );
print_it( fid, sprintf(  'Created: %s\n', figure_name ) );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [D, D_err, D_ref, D_ref_err, RNA_info, RNA_info_ref ] = separate_out_reference( D, D_err, RNA_info, ref_idx )

no_ref_idx = setdiff( [ 1 : size( D{1}, 2) ], ref_idx )';
for i = 1:length(D)
    D_ref{i}     = D{i}(:, ref_idx);
    D_ref_err{i} = D_err{i}(:, ref_idx);
    D{i}         = D{i}(:, no_ref_idx);
    D_err{i}     = D_err{i}(:, no_ref_idx);
end

RNA_info_ref = RNA_info( ref_idx );
RNA_info     = RNA_info( no_ref_idx );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [D,D_err] = truncate_based_on_zeros( D , D_err)

if isempty( D ); return; end;

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
function output_signal_to_noise_ratio( D, D_err, fid )

for i = 1:length(D)
    SN_ratio = estimate_signal_to_noise_ratio( D{i}, D_err{i} );
    print_it( fid, sprintf(  'Signal-to-noise ratio for primer %d:  %8.3f [%s]\n', i, SN_ratio, classify_signal_to_noise_ratio( SN_ratio ) ) );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sqrtD = cell_sqrt( D )
for i = 1:length( D )
    sqrtD{i} = sqrt( D{i} );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function MOHCA = isMOHCA( RNA_info )
MOHCA = ~isempty( strfind( RNA_info(1).Header, 'MOHCA' ) );
