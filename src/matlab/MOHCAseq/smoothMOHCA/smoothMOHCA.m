function [D_smooth, D_smooth_error, seqpos, ligpos, r] = smoothMOHCA( rdat_file, MODE, pdb, SQUARIFY, image_options );
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
%%%                 5. 'repsub' processing, no 'mod correct'
%%% SQUARIFY     = option to crop data so that rdat and plots display as square with identical axis limits; default 1 (on) 
%%% image_options = string of cells, e.g., {'smooth'}:
%%%                   no_smooth    = do not apply 2D smooth in image.
%%%                   no_filter    = do not filter points with signal/noise < 1
%%%                   no_autoscale = for plotting, do not scale automatically.
%%%                   filter_SN1.5 = filter points with signal/noise < 1.5
%%%                   filter_SN2   = filter points with signal/noise < 2
%%%                   filter_RNAse = filter 'vertical' striations caused by RNAse cleavage
%%%                   crossZ       = apply a 2-dimensional Z-score-based correction to the data 
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

% Basic setup.
clf;
set(gcf, 'PaperPositionMode','auto','color','white');
if ~exist( 'MODE', 'var' ); MODE = 1; end;
if ~exist( 'image_options' ) image_options = {'smooth','filter_SN1'}; end;
if ~iscell( image_options ); assert( ischar( image_options ) ); image_options = { image_options }; end;
if ischar( rdat_file ) & exist( rdat_file, 'dir' )==7; rdat_file = get_rdats_in_directory( rdat_file ); end;                % rdat_file = {'~/.../RNA.RAW.1.rdat','...'}
if ~iscell( rdat_file ) rdat_file = { rdat_file }; end;
D_sim_a = [];
dist_matrix = []; rad_res = []; hit_res = [];
if exist( 'pdb', 'var' ); [D_sim_a, rad_res, hit_res, dist_matrix, pdbstruct] = get_simulated_data( pdb ); end
if ~exist( 'SQUARIFY' ); SQUARIFY = 1; end
m_tag = get_mode_tag( MODE );

% Show all data sets, applying specified analysis
for i = 1:length( rdat_file )
  [store_D_smooth(:,:,i), seqpos, ligpos, r{i}, store_D_smooth_error(:,:,i), r_name ] = get_D_smooth( rdat_file{i}, MODE ); % r_name = '~/.../RNA.RAW.1.rdat'
  out_dir = dirname( r_name );                                                                                              % out_dir = '~/.../'

  if SQUARIFY
      [r{i}, out_file_temp] = squarifier( r{i}, store_D_smooth(:,:,i), store_D_smooth_error(:,:,i), r_name, MODE );         % out_file_temp = '~/.../RNA.RAW.1.method.SQR.rdat'
      
      % set variables to squarified data
      all_D_smooth(:,:,i) = r{i}.reactivity;
      all_D_smooth_error(:,:,i) = r{i}.reactivity_error;
      ligpos = get_ligpos(r{i});
      seqpos = r{i}.seqpos;

      % save squarified rdat
      output_rdat_to_file( out_file_temp, r{i} );
  else
      all_D_smooth(:,:,i) = store_D_smooth(:,:,i);
      all_D_smooth_error(:,:,i) = store_D_smooth_error(:,:,i);      
  end
  
  if i > 1;
      cat_name = [cat_name, r_name];
  else
      cat_name = {r_name};
  end
  
  % Append analysis mode to cat_name (for title of plot)
  fig_name = {r_name, ['Applied ', m_tag, ' analysis']};

  make_plot( squeeze( all_D_smooth(:,:,i) ), ...
       squeeze( all_D_smooth_error(:,:,i) ), ...
       seqpos, ligpos, r{i}.sequence, r{i}.offset, fig_name, out_dir, dist_matrix, rad_res, hit_res, ...
       MODE, image_options, SQUARIFY );

  drawnow;
end


% If more than one RDAT was input, get a weighted average of the datasets 
if length( rdat_file ) > 1
  [D_smooth, D_smooth_error ] = get_weighted_average( all_D_smooth, all_D_smooth_error );
else
  D_smooth = squeeze(all_D_smooth(:,:,1));
  D_smooth_error = squeeze(all_D_smooth_error(:,:,1));
end


% Append analysis mode to cat_name (for title of plot) 
cat_name = [cat_name, ['Applied ', m_tag, ' analysis']];


% If cross-Z-score specified, calculate a cross-Z-score
r = r{1};
if check_option( image_options, 'crossZ' );
  r.reactivity = D_smooth; r.reactivity_error = D_smooth_error;
  [D_smooth, D_smooth_error ] = crossZscore( r ); fprintf( 'APPLIED CROSS-ZSCORE!\n' );
  cat_name{end} = [cat_name{end}, ' and cross Z-score'];
end


% Plot final data and output final RDAT
make_plot( D_smooth, D_smooth_error, seqpos, ligpos, r.sequence, r.offset, ...
	   cat_name, out_dir, dist_matrix, rad_res, hit_res, ...
	   MODE, image_options, SQUARIFY);
output_combined_rdat_file( r, D_smooth, D_smooth_error, seqpos, cat_name, out_dir, MODE, image_options, SQUARIFY );


% Output the analysis mode used
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
		    MODE, image_options, SQUARIFY )
        
        
D_filter = D_smooth;
if check_option( image_options, 'filter_RNAse' );  D_filter = filter_RNAse_striations( D_filter );end
if size( D_smooth,2) == size( D_smooth_error, 2 );
  if check_option( image_options, 'filter_SN1.5' )  
    D_filter( find( (D_smooth./D_smooth_error) < 1.5 ) ) = 0.0;   
  elseif check_option( image_options, 'filter_SN2' )  
      D_filter( find( (D_smooth./D_smooth_error) < 2 ) ) = 0.0;  
  elseif ~check_option( image_options, 'filter_SN1' )  
      D_filter( find( (D_smooth./D_smooth_error) < 1 ) ) = 0.0;   
  end
end
if ~check_option( image_options, 'no_smooth' )  D_filter = smooth2d( D_filter ); end

% auto scale
if ~check_option( image_options, 'no_autoscale' )
  scalefactor = (1/8)/mean(mean(max(D_filter,0)));
  D_filter = D_filter * scalefactor;
end

image( seqpos, ligpos, 80 * D_filter' );

% label x and y axes
gp = find( mod(seqpos,10) == 0 );
set(gca,'xtick',seqpos(gp) )
gp = find( mod(ligpos,10) == 0 );
set(gca,'ytick',ligpos(gp) )
set(gca,'TickDir','out');
set(gca,'xgrid','on','ygrid','on','fonts',15,'fontw','bold');
xlabel( 'Reverse transcription stop position [5'']','fontsize',20,'fontweight','bold' );
ylabel( 'Cleaved and ligated position [3'']','fontsize',20,'fontweight','bold' );
hold on;

% Rotate labels
xticklabel = get(gca,'XTickLabel');
set(gca,'XTickLabel','');
hxLabel=get(gca,'XLabel');
set(hxLabel,'Units','data');
xLabelPosition=get(hxLabel,'Position');
y=xLabelPosition(2) - 7;
XTick=str2num(xticklabel)+1;
y=repmat(y,length(XTick),1);
fs = get(gca,'fonts');
hText=text(XTick,y,xticklabel,'fonts',15,'fontw','bold');
set(hText,'Rotation',90,'HorizontalAlignment','right');
xlab=get(gca,'XLabel');
set(xlab,'Position',get(xlab,'Position') + [0 7 0]);

colormap( jet ); % colormap( 1-gray(100) );
axis image;

%contour_levels = [10, 15, 25, 35];
%colorcode = [0 0 1; 0.3 0.3 1; 0.6 0.6 1; 0.8 0.8 1];
contour_levels = [15,30];
colorcode = [1 0 1; 0.75 0.6 0.9];

% add legends
legends = {};
if ~isempty( dist_matrix );
  dist_matrix = smooth2d( dist_matrix );
  for i = 1:length( contour_levels )
    [c,h]=contour(rad_res, hit_res, tril(dist_matrix), ...
		  contour_levels(i) * [1 1],...
		  'color',colorcode(i,:),...
		  'linewidth', 1 );
    legends{i} = sprintf( '%d Angstrom', contour_levels(i) );
  end
end

% add sequence to axes and diagonal
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


if ( ~isempty( strfind( name, '\newline' ) ) ) name = [out_dir, 'COMBINED']; end;
epsfilename = [name,'.eps'];
epsfilename = strrep( epsfilename, basename( epsfilename ), ['Figures/',basename(epsfilename)] );
if ~exist( dirname( epsfilename ), 'dir' ) mkdir( dirname( epsfilename ) ); end;

epsfilename = strrep( epsfilename, '.eps',['.',get_mode_tag( MODE ),'.eps'] );
if exist( 'export_fig' ) == 2 & system( 'which ghostscript' ) == 0
  if exist( epsfilename, 'file' ); delete( epsfilename ); end;
  epsfilename = strrep( epsfilename, '.eps','.pdf' );
  export_fig( GetFullPath(epsfilename) );
else
  print( '-depsc2', epsfilename);
end

% Add title
% title_name = strrep( name{1},'_','\_' );
% for i = 2:length( name )
%     title_name = [title_name, '\newline', strrep( name{i},'_','\_' ) ];
% end
% title( title_name );

% If multiple datasets analyzed at once, note this in filenames
if length( name ) > 2
    name{1} = [out_dir, 'COMBINED']; end;

% save figures as .eps or .pdf 
  epsfilename = [name{1},'.eps'];
  epsfilename = strrep( epsfilename, basename( epsfilename ), ['Figures/',basename(epsfilename)] );

  if ~exist( dirname( epsfilename ), 'dir' ) mkdir( dirname( epsfilename ) ); end;

  epsfilename = strrep( epsfilename, '.eps',['.',get_mode_tag( MODE ),'.eps'] );

  if SQUARIFY; epsfilename = strrep( epsfilename, '.eps', '.SQR.eps' ); end

  if strfind(name{1}, 'COMBINED')
      if check_option( image_options, 'crossZ' ); epsfilename = strrep( epsfilename, '.eps','.Z.eps' ); end;
  end
  if exist( 'export_fig' ) == 2;
    if exist( epsfilename, 'file' ); delete( epsfilename ); end;
    epsfilename = strrep( epsfilename, '.eps','.pdf' );
    export_fig( GetFullPath(epsfilename) );
  else
    print( '-depsc2', epsfilename);
  end
  fprintf( 'Outputted: %s\n', epsfilename );

% save figures as .fig
  figfilename = [name{1},'.fig'];
  figfilename = strrep( figfilename, basename( figfilename ), ['Figures/',basename(figfilename)] );
  figfilename = strrep( figfilename, '.fig',['.',get_mode_tag( MODE ),'.fig'] );
  if strfind(name{1}, 'COMBINED')
      if check_option( image_options, 'crossZ' ); figfilename = strrep( epsfilename, '.eps','.Z.eps' ); end;
  end

  if SQUARIFY; figfilename = strrep( figfilename, '.fig', '.SQR.fig' ); end

  hgsave(gcf, figfilename);
  fprintf( 'Outputted: %s\n', figfilename );

  
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
function output_combined_rdat_file( r, D_smooth, D_smooth_error, seqpos, cat_name, out_dir, MODE, image_options, SQUARIFY );

r.reactivity = D_smooth;
r.reactivity_error = D_smooth_error;
r.seqpos = seqpos;
for i = 1:length( cat_name )
    r.comments = [r.comments, cat_name{i} ];
end

if exist( [out_dir, 'COMBINED.rdat'], 'file' ) delete( [out_dir, 'COMBINED.rdat'] ); end; % some cleanup

if SQUARIFY;
    out_file = [out_dir,'COMBINED.',get_mode_tag( MODE ),'.SQR.rdat'];
else
    out_file = [out_dir,'COMBINED.',get_mode_tag( MODE ),'.rdat'];
end       

if check_option( image_options, 'crossZ' ); out_file = strrep( out_file, '.rdat','.Z.rdat' ); end;
output_rdat_to_file( out_file, r );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = check_option( image_options, option_string );
val = ~isempty( find( strcmp( image_options, option_string ) ) );


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
