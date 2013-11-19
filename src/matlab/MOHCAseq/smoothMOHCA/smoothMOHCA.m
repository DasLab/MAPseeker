function [D_smooth, D_smooth_error, seqpos, ligpos, r] = smoothMOHCA( rdat_file, pdb, MODE, image_options );
%%% [D_smooth,seqpos, ligpos, r] = smoothMOHCA( rdat_file, pdb, MODE );
%%%
%%% One-shot script to take MOHCA raw data (in rdat format) and any known 
%%%  reference structure, and make a nice summary plot.
%%% 
%%% Inputs
%%%  rdat_file   = rdat or cell of rdats (either filenames or actual data objects will work)
%%%  pdb         = filename of pdb (or pdbstruct object from pdbread)
%%%  MODE        =  0. COHCOA [extraction of two-point correlation function, MOHCA-X style], force run.
%%%                 1. COHCOA [extraction of two-point correlation function, MOHCA-X style], use cached if avail.
%%%                 2. LAHTTE analysis [Likelihood Analysis of Hydroxyl-damage revealed TerTiary contact Estimation -- general model of the data assuming independence of background (random cleavage and RT stoppage) and source location]
%%%                 3. Use Z-score processing of reactivities (note that 
%%%                    this script will apply attenuation correction for you). 
%%%                 4. 'repsub' processing based on subtracting data corresponding
%%%                    to uncleaved RNA.
%%%                 5. 'respub' processing, no 'mod correct'
%%% image_options = string of cells, e.g., {'smooth'}:
%%%                   filter_RNAse = filter 'vertical' striations caused by RNAse cleavage
%%%                   filter_SN1   = filter points with signal/noise < 1
%%%                   filter_SN1.5 = filter points with signal/noise < 1.5
%%%                   filter_SN2   = filter points with signal/noise < 2
%%%                   smooth = apply 2D smooth
%%% Outputs 
%%%  D_smooth    = matrix of output, averaged over all data sets (weighted by 
%%%                 inverse error^2).
%%%  seqpos      = MOHCA stop positions of 5' ends (x-axis)
%%%  ligpos      = MOHCA ligation positions at 3' ends (these are the cleavage 
%%%                 positions + 1, corresponding to the sites actually attacked).
%%%  r           = cell of rdats
%%%
%%% (C) R. Das, C. Cheng, 2013
%%%

if nargin < 1; help( mfilename ); return; end;

% basic setup.
clf;
set(gcf, 'PaperPositionMode','auto','color','white');
if ~exist( 'MODE', 'var' ); MODE = 1; end;
if ~exist( 'image_options' ) image_options = {}; end;
if ~iscell( image_options ); assert( ischar( image_options ) ); image_options = { image_options }; end;
if ischar( rdat_file ) & exist( rdat_file, 'dir' )==7; rdat_file = get_rdats_in_directory( rdat_file ); end;
if ~iscell( rdat_file ) rdat_file = { rdat_file }; end;
D_sim_a = [];
dist_matrix = []; rad_res = []; hit_res = [];
if exist( 'pdb', 'var' );  [D_sim_a, rad_res, hit_res, dist_matrix, pdbstruct] = get_simulated_data( pdb ); end

% show all data sets.
cat_name = '';
for i = 1:length( rdat_file )
  [all_D_smooth(:,:,i), seqpos, ligpos, r{i}, all_D_smooth_error(:,:,i), r_name ] = get_D_smooth( rdat_file{i}, MODE );  
  out_dir = dirname( r_name );
  make_plot( squeeze( all_D_smooth(:,:,i) ), ...
	     squeeze( all_D_smooth_error(:,:,i) ), ...
	     seqpos, ligpos, r{i}.sequence, r{i}.offset, r_name, out_dir, dist_matrix, rad_res, hit_res, ...
	     MODE, image_options );
  if i > 1; cat_name = [cat_name, '\newline' ]; end
  cat_name = [cat_name, r_name];
  drawnow;
end

if ( length( rdat_file )  > 1 )
  [D_smooth, D_smooth_error ] = get_weighted_average( all_D_smooth, all_D_smooth_error );
  make_plot( D_smooth, D_smooth_error, seqpos, ligpos, r{1}.sequence, r{1}.offset, ...
	     cat_name, out_dir, dist_matrix, rad_res, hit_res, ...
	     MODE, image_options);
  output_combined_rdat_file( r{1}, D_smooth, D_smooth_error, seqpos, cat_name, out_dir, MODE );
else
  D_smooth = squeeze(all_D_smooth(:,:,1));
  D_smooth_error = squeeze(all_D_smooth_error(:,:,1));
end

if MODE == 0; fprintf( 'Applied COHCOA (overwrite any previous COHCOA.rdat). \n' ); end;
if MODE == 1; fprintf( 'Used COHCOA. \n' ); end;
if MODE == 2; fprintf( 'Used LAHTTE. \n' ); end;
if MODE == 3; fprintf( 'Used Z-score\n' ); end;
if MODE == 4; fprintf( 'Used repsub. Applied modification correction. \n' ); end
if MODE == 5; fprintf( 'Used repsub. Applied modification correction. \n' ); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function make_plot( D_smooth, D_smooth_error, ...
		    seqpos, ligpos, sequence, offset, name, out_dir, ...
		    dist_matrix, rad_res, hit_res, ...
		    MODE, opts )

D_filter = D_smooth;
if check_option( opts, 'filter_RNAse' );  D_filter = filter_RNAse_striations( D_filter );end
if size( D_smooth,2) == size( D_smooth_error, 2 );
  if check_option( opts, 'filter_SN1' )  D_filter( find( (D_smooth./D_smooth_error) < 1 ) ) = 0.0;   end
  if check_option( opts, 'filter_SN1.5' )  D_filter( find( (D_smooth./D_smooth_error) < 1.5 ) ) = 0.0;   end
  if check_option( opts, 'filter_SN2' )  D_filter( find( (D_smooth./D_smooth_error) < 2 ) ) = 0.0;   end
end
if check_option( opts, 'smooth' )  D_filter = smooth2d( D_filter ); end

image( seqpos, ligpos, 80 * D_filter' );

gp = find( mod(seqpos,10) == 0 );
set(gca,'xtick',seqpos(gp) )
gp = find( mod(ligpos,10) == 0 );
set(gca,'ytick',ligpos(gp) )
set(gca,'xgrid','on','ygrid','on','fonts',12,'fontw','bold');
xlabel( 'Stop pos [5'']' ); ylabel( 'Lig pos [3'']');
hold on;

colormap( 1 - gray(100));
axis image;

%contour_levels = [10, 15, 25, 35];
%colorcode = [0 0 1; 0.3 0.3 1; 0.6 0.6 1; 0.8 0.8 1];
contour_levels = [15,30];
colorcode = [1 0.5 1; 0.5 0.5 1];

legends = {};
if ~isempty( dist_matrix );
  dist_matrix = smooth2d( dist_matrix );
  for i = 1:length( contour_levels )
    [c,h]=contour(rad_res, hit_res, tril(dist_matrix), ...
		  contour_levels(i) * [1 1],...
		  'color',colorcode(i,:),...
		  'linewidth',0.5 );
    legends{i} = sprintf( '%d Angstrom', contour_levels(i) );
  end
end

%plot( ligpos([1 end]), ligpos( [1 end] ),'color',[0.5 0.5 0.5],'linew',1.5 );

for i = seqpos
  text( i, max(ligpos)+0.5, sequence( i - offset ),'horizontalalign','center','verticalalign','top','fontsize',6 );
end
for j = ligpos'
  text( min(seqpos)-0.5, j, sequence(j - offset ),'horizontalalign','right','verticalalign','middle','fontsize',6 );
end
for j = ligpos'
  text( j, j, sequence(j - offset ),'fontsize',6,'horizontalalign','center','verticalalign','middle' );
end
hold off;

axis( [min(seqpos)-0.5 max(seqpos)+0.5 min(ligpos)-0.5 max(ligpos)+0.5 ]);

if length( legends ) > 0; legend( legends ); end;
title( strrep( name,'_','\_') );

if ( ~isempty( strfind( name, '\newline' ) ) ) name = [out_dir, 'COMBINED']; end;
epsfilename = [name,'.eps'];
epsfilename = strrep( epsfilename, basename( epsfilename ), ['Figures/',basename(epsfilename)] );
if ~exist( dirname( epsfilename ), 'dir' ) mkdir( dirname( epsfilename ) ); end;

epsfilename = strrep( epsfilename, '.eps',['.',get_mode_tag( MODE ),'.eps'] );
if exist( 'export_fig' ) == 2;
  if exist( epsfilename, 'file' ); delete( epsfilename ); end;
  epsfilename = strrep( epsfilename, '.eps','.pdf' );
  export_fig( GetFullPath(epsfilename) );
else
  print( '-depsc2', epsfilename);
end
fprintf( 'Outputted: %s\n', epsfilename );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [D_smooth, D_smooth_error ] = get_weighted_average( all_D_smooth, all_D_smooth_error );

D_smooth_sum = 0*squeeze( all_D_smooth(:,:,1) ); 
weight_sum   = 0 * D_smooth_sum;
for i = 1:size( all_D_smooth, 3 )
  weight_matrix = max( 1 ./ squeeze( all_D_smooth_error(:,:,i) ).^2, 0 );  
  D_smooth_sum = D_smooth_sum + squeeze(all_D_smooth(:,:,i)) .* weight_matrix;
  weight_sum   = weight_sum   + weight_matrix;
end
D_smooth = D_smooth_sum ./ weight_sum;
D_smooth_error = sqrt(1 ./ weight_sum);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output_combined_rdat_file( r, D_smooth, D_smooth_error, seqpos, cat_name, out_dir, MODE );

r.reactivity = D_smooth;
r.reactivity_error = D_smooth_error;
r.seqpos = seqpos;
r.comments = [r.comments, cat_name ];

if exist( [out_dir, 'COMBINED.rdat'], 'file' ) delete( [out_dir, 'COMBINED.rdat'] ); end; % some cleanup

out_file = [out_dir,'COMBINED.',get_mode_tag( MODE ),'.rdat'];
output_rdat_to_file( out_file, r );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = check_option( opts, option_string );
val = ~isempty( find( strcmp( opts, option_string ) ) );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rdat_files = get_rdats_in_directory( rdat_dir ); 

rdats_in_dir = dir( [rdat_dir,'/*.RAW.*.rdat'] );
rdat_files = {};
for i = 1:length( rdats_in_dir ); 
  if isempty(strfind(rdats_in_dir(i).name,'COMB')) 
    rdat_files = [rdat_files, [rdat_dir,'/',rdats_in_dir(i).name ] ]; end
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mode_tag = get_mode_tag( MODE );

mode_tag = '';
switch MODE
 case {0,1}
  mode_tag = 'COHCOA';
 case 2
  mode_tag = 'LATTE';
 case 3
  mode_tag = 'ZSCORE';
 case 4
  mode_tag = 'REPSUB';
 case 5
  mode_tag = 'REPSUB_ALT';
end

if length(mode_tag) == 0;
  error( ['unrecognized mode: ', MODE] );
end
