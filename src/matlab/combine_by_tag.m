function [D_combine, RNA_info_combine ] = combine_by_tag( D, RNA_info, COMBINE_MODE )
%
% [D_combine, RNA_info_combine ] = combine_by_tag( D, RNA_info, COMBINE_MODE )
%
% D             = cell of M x N arrays with raw sequencing counts, where M is number of RNAs, and N is number of residues.
% RNA_info      = M structs with fields 'Header' and 'Sequence', as output by fastaread
% COMBINE_MODE = 1: combine counts for RNAs with the same Header tag, 
%                 2: combine counts for RNAs with the same subtags (delimited by tabs)
%
% Note: Header tags of the form "71323-1 [tab] blah blah blah" will be converted to
%                               "71323 [tab] blah blah blah", before collapsing.
%
% (C) R. Das, 2013
if ~exist( 'COMBINE_MODE' ) COMBINE_MODE = 1; end;
WEIGHT_BY_ERRORS = 0; % put this in later.

N_RNA = length( RNA_info );
tags = {};
% save mapping.
index_for_tag = {}; 
for j = 1:N_RNA
  
  index_for_tag{j} = [];

  complete_tag = RNA_info(j).Header;

  if COMBINE_MODE == 2
    RNA_tags = split_string( complete_tag, sprintf('\t') );
  else
    RNA_tags = {complete_tag};
  end
  
  for k = 1: length( RNA_tags )
    tag = RNA_tags{k};

    % silly hack for eterna player projects. Remove "-1", "-2", etc.
    tag = remove_RNA_barcode_identifier( tag );
    %tag = remove_ID_number( tag );
    
    if length( tag) == 0; continue; end
    found_tag = strcmp( tag, tags );
  
    if sum( found_tag ) == 0
      tags = [tags, tag ];
      N_tags_combine = length( tags );
      index_for_tag{j} = [ N_tags_combine ];
      RNA_info_combine( N_tags_combine ) = RNA_info(j);
    else
      index_for_tag{j} = [index_for_tag{j}, find( found_tag )];
    end
  end
end

D_combine = {};
for i = 1:length(D)

  N_RNA_in_D = size( D{i}, 1 );
  if ( N_RNA_in_D ~= N_RNA ) 
    fprintf( 'Disagreement between number of RNAs in RNA_info [%d] and in D{%i} [%d]\n', N_RNA, i, N_RNA_in_D );
    return;
  end  

  N_res  = size( D{i}, 2);
  D_new = zeros( N_tags_combine, N_res);
  for j = 1:N_RNA
    for m = index_for_tag{j}
      D_new( m, : ) = D_new( m, : ) + D{i}(j, :);
    end
  end

  D_combine{i} = D_new;
end

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tag = remove_RNA_barcode_identifier( tag_in )

tag = tag_in;

cols = split_string( tag, sprintf('\t') );
if length( cols ) < 2; return; end;

subcols = split_string( cols{1}, '-' );
if length( subcols ) < 2; return; end

[x,is_a_number] = str2num( subcols{end} );
if ( is_a_number )
  cols{1} = join_string( subcols(1:end-1), '-' );
  tag = join_string( cols, sprintf('\t') );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tag = remove_ID_number( tag )
cols = split_string( tag, sprintf('\t') );
tag = join_string( cols(2:end) );