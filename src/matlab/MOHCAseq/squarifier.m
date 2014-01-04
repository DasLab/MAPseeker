function [out_r, out_file_sqr] = squarifier( r, D, D_err, r_name, MODE )

%   [out_r, out_sqr, out_sqr_err, out_filename] = squarify( r, D, D_err )
%   
%   Accepts an rdat file and arrays of data and errors, along with rdat name and smoothMOHCA mode 
%   Finds intersect of seqpos and ligpos = sqrpos
%   Crop data and error arrays to sqrpos dimensions
%   Replace data and error elements of rdat with squarified versions
%   Redefines rdat.seqpos and lig_pos (in rdat.data_annotations) to be sqrpos 
%   Defines output filename to include '.SQR' to indicate squarification
%   Outputs modified rdat and filename; parent scripts will then use for saving, visualization, and further analysis 
%
%   Inputs:
%       r            = rdat structure array
%       D            = data array
%       D_err        = error array
%       r_name       = full path name of rdat file
%       MODE         = smoothMOHCA analysis mode
%   Outputs:
%       out_r        = squarified rdat (rdat.seqpos, rdat.data_annotations>lig_pos = sqrpos; data and error also squarified) 
%     (optional)
%       out_file_sqr = output filename with '.SQR' appended to indicate squarification 
%   
%
%   (C) Clarence Cheng, 2013

if MODE == 0 || MODE == 1
    % Find intersect of seqpos and ligpos
    ligpos = get_ligpos(r);
    seqpos = r.seqpos(1:length(ligpos));        % for COHCOA, data already cropped to 1:length(ligpos) x 1:length(ligpos)
    [sqrpos, seqind, ligind] = intersect(seqpos, ligpos);
else
    % Find intersect of seqpos and ligpos
    ligpos = get_ligpos(r);
    seqpos = r.seqpos;                          % can be more general for other analysis pipelines
    [sqrpos, seqind, ligind] = intersect(seqpos, ligpos);
end

% Crop data and error arrays
D_sqr = D(seqind, ligind);
D_err_sqr = D_err(seqind, ligind);
    
% Redefine fields of rdat file
out_r = r;
out_r.reactivity = D_sqr;
out_r.reactivity_error = D_err_sqr;
out_r.seqpos = sqrpos';
out_r.data_annotations = out_r.data_annotations( ligind );

% Rename output filename
out_dir = [dirname(r_name) 'Analyzed_rdats/'];
if ~exist( out_dir, 'dir' ); mkdir( out_dir ); end;
name = strrep( basename(r_name), '.rdat', ['.', get_mode_tag( MODE ), '.SQR.rdat']);
out_file_sqr = [out_dir name];


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

