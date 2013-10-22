function [D_smooth, D_smooth_error, seqpos, ligpos, r] = smoothMOHCA( rdat_file, pdb, MODE, image_options );
%% [D_smooth,seqpos, ligpos, r] = smoothMOHCA( rdat_file, pdb, USE_Z_SCORE, MOD_CORRECT );
%%
%% One-shot script to take MOHCA raw data (in rdat format) and any known 
%%  reference structure, and make a nice summary plot.
%% 
%% Inputs
%%  rdat_file   = rdat or cell of rdats (either filenames or actual data objects will work)
%%  pdb         = filename of pdb (or pdbstruct object from pdbread)
%%  MODE        = [Default 1] 
%%                 1. iterfit_x [extraction of two-point correlation function, MOHCA-X style]
%%                 2. Use Z-score processing of reactivities (note that 
%%                    this script will apply attenuation correction for you). 
%%                 3. 'repsub' processing based on subtracting data corresponding
%%                    to uncleaved RNA.
%%                 4. 'respub' processing, no 'mod correct'
%%
%% Outputs 
%%  D_smooth    = matrix of output, averaged over all data sets (weighted by 
%%                 inverse error^2).
%%  seqpos      = MOHCA stop positions of 5' ends (x-axis)
%%  ligpos      = MOHCA ligation positions at 3' ends (these are the cleavage 
%%                 positions + 1, corresponding to the sites actually attacked).
%%  r           = cell of rdats
%%
%% (C) R. Das, C. Cheng, 2013
%%

if nargin < 1; help( mfilename ); return; end;

% basic setup.
clf;
set(gcf, 'PaperPositionMode','auto','color','white');
if ~exist( 'MODE', 'var' ); MODE = 1; end;
if ~exist( 'image_options' ) image_options = {}; end;
if ~iscell( image_options ); assert( ischar( image_options ) ); image_options = { image_options }; end;
if ~iscell( rdat_file ) rdat_file = { rdat_file }; end;
D_sim_a = [];
if exist( 'pdb', 'var' );  [D_sim_a, rad_res, hit_res, dist_matrix, pdbstruct] = get_simulated_data( pdb ); end

% show all data sets.
cat_name = '';
for i = 1:length( rdat_file )
  [all_D_smooth(:,:,i), seqpos, ligpos, r{i}, all_D_smooth_error(:,:,i), r_name ] = get_D_smooth( rdat_file{i}, MODE );  
  make_plot( squeeze( all_D_smooth(:,:,i) ), ...
	     squeeze( all_D_smooth_error(:,:,i) ), ...
	     seqpos, ligpos, r{i}.sequence, r{i}.offset, r_name, dist_matrix, rad_res, hit_res, pdb, ...
	     MODE, image_options );
  if i > 1; cat_name = [cat_name, '\newline' ]; end
  cat_name = [cat_name, r_name];
  drawnow;
end

% average across data sets.
if ( length( rdat_file )  > 1 )
  [D_smooth, D_smooth_error ] = get_weighted_average( all_D_smooth, all_D_smooth_error );
  make_plot( D_smooth, D_smooth_error, seqpos, ligpos, r{1}.sequence, r{1}.offset, ...
	     cat_name, dist_matrix, rad_res, hit_res, pdb, ...
	     MODE, image_options);
  output_combined_rdat_file( r{1}, D_smooth, D_smooth_error, seqpos, cat_name );
else
  D_smooth = squeeze(all_D_smooth(:,:,1));
  D_smooth_error = squeeze(all_D_smooth_error(:,:,1));
end

if MODE == 0; fprintf( 'Applied iterfitX (overwrite any previous iterfit.rdat). \n' ); end;
if MODE == 1; fprintf( 'Used iterfitX. \n' ); end;
if MODE == 2; fprintf( 'Used Z-score\n' ); end;
if MODE == 3; fprintf( 'Used repsub. Applied modification correction. \n' ); end
if MODE == 4; fprintf( 'Used repsub. Applied modification correction. \n' ); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function make_plot( D_smooth, D_smooth_error, ...
		    seqpos, ligpos, sequence, offset, name, ...
		    dist_matrix, rad_res, hit_res, pdb, ...
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
colorcode = [1 0 1; 0 0 1];

if ~isempty( dist_matrix );
  dist_matrix = smooth2d( dist_matrix );
  for i = 1:length( contour_levels )
    [c,h]=contour(rad_res, hit_res, tril(dist_matrix), ...
		  contour_levels(i) * [1 1],...
		  'color',colorcode(i,:),...
		  'linewidth',1.5 );
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

legend( legends );
title( strrep( name,'_','\_') );

if ( ~isempty( strfind( name, '\newline' ) ) ) name = 'COMBINED'; end;
epsfilename = [name,'.eps'];
if ( MODE == 2 ) epsfilename = strrep( epsfilename,'.eps','.ZSCORE.eps'); end
if ( MODE == 3 ) epsfilename = strrep( epsfilename,'.eps','.REPSUB.eps'); end
if ( MODE == 4 ) epsfilename = strrep( epsfilename,'.eps','.REPSUB_ALT.eps'); end
fprintf( 'Outputting: %s\n', epsfilename );
print( '-depsc2', epsfilename);

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
function  output_combined_rdat_file( r, D_smooth, D_smooth_error, seqpos, cat_name );

r.reactivity = D_smooth;
r.reactivity_error = D_smooth_error;
r.seqpos = seqpos;
r.comments = [r.comments, cat_name ];
output_rdat_to_file( 'COMBINED.rdat', r );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = check_option( image_options, option_string );
val =  ~isempty( find(strcmp( image_options, option_string )) );
