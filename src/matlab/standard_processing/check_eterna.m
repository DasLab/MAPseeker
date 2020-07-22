function [is_eterna,ID,design_name,project_name,tag_cols] = check_eterna( RNA_tag, tag_cols );
%  [is_eterna,design_name,project_name,tag_cols] = check_eterna( RNA_tag, tag_cols );
%
% Input:
%   RNA_tag  = (string) Header line from FASTA (e.g. Header string in RNA_Info
%                object)
%   tag_cols = (cell of strings) input tag cols 
%
% Output
%   is_eterna    = (0 or 1) Identified as Eterna or not.
%   ID           = (string) Eterna ID number
%   design_name  = (string) Eterna design name
%   project_name = (string) Eterna project name
%   tag_cols     = (cell of strings) output tag cols 
%
% (C) Das lab, Stanford University, 2020
if ~exist( 'tag_cols','var') tag_cols = {}; end;

RNA_tag_cols = split_string( RNA_tag, '\t' );
is_eterna = 0;
ID = '';
project_name = '';
design_name = '';

if length( RNA_tag_cols ) == 3 & is_ID( RNA_tag_cols{1} ) % came from an eterna run?
    ID = RNA_tag_cols{1};
    if ID(1) == ' '; ID = ID(2:end); end; % space in FASTA file.
    design_name = RNA_tag_cols{3};
    project_name = RNA_tag_cols{2};
    is_eterna = 1;
else
    tag_cols = [tag_cols, RNA_tag_cols]; % crap, may not work. Anyway...
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ok = is_ID( tag );

tag = strrep( tag, 'WTF',''); % weird problem in some eterna IDs.
tag_cols = split_string( tag, '-' );
tag = tag_cols{1};

ok = 0;
if ~isempty( str2num( tag ) ) ok = 1; end;
  
