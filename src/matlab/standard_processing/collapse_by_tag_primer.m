function [D_collapse, primer_info_collapse ] = collapse_by_tag_primer( D, primer_info, COLLAPSE_MODE )
%
% [D_collapse, primer_info_collapse ] = collapse_by_tag( D, primer_info, COLLAPSE_MODE )
%
% D             = cell of Q arrays with raw sequencing counts, where Q is the number of primers.
% primer_info   = M structs with fields 'Header' and 'Sequence', as output by fastaread
% COLLAPSE_MODE = 1: combine counts for primers with the same Header tag, after the first tab. 
%
% (C) R. Das, 2013
if ~exist( 'COLLAPSE_MODE' ) COLLAPSE_MODE = 1; end;
WEIGHT_BY_ERRORS = 0; % put this in later.

N_primer = length( primer_info );
tags = {};

% save mapping.
index_for_tag = {}; 
for j = 1:N_primer
  
  index_for_tag{j} = [];
  complete_tag = primer_info(j).Header;

  primer_tags = split_string( complete_tag, sprintf('\t') );
  
  for k = 1: length( primer_tags )
    tag = primer_tags{k};

    % silly hack for eterna player projects. Remove "-1", "-2", etc.
    tag = remove_primer_barcode_identifier( tag );
    %tag = remove_ID_number( tag );
    
    if length( tag) == 0; continue; end
    found_tag = strcmp( tag, tags );
  
    if sum( found_tag ) == 0
      tags = [tags, tag ];
      N_tags_collapse = length( tags );
      index_for_tag{j} = [ N_tags_collapse ];
      primer_info_collapse( N_tags_collapse ) = primer_info(j);
    else
      index_for_tag{j} = [index_for_tag{j}, find( found_tag )];
    end
  end
end

D_collapse = {};
for i = 1:length(D)

  N_primer_in_D = size( D{i}, 1 );
  if ( N_primer_in_D ~= N_primer ) 
    fprintf( 'Disagreement between number of primers in primer_info [%d] and in D{%i} [%d]\n', N_primer, i, N_primer_in_D );
    return;
  end  

  N_res  = size( D{i}, 2);
  D_new = zeros( N_tags_collapse, N_res);
  for j = 1:N_primer
    for m = index_for_tag{j}
      D_new( m, : ) = D_new( m, : ) + D{i}(j, :);
    end
  end

  D_collapse{i} = D_new;
end

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tag = remove_primer_barcode_identifier( tag_in )

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