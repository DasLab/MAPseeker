function [D_combine, primer_info_combine ] = combine_by_tag_primer( D, primer_info, COMBINE_MODE )
%
% [D_combine, primer_info_combine ] = combine_by_tag( D, primer_info, COMBINE_MODE )
%
% D             = cell of Q arrays with raw sequencing counts, where Q is the number of primers.
% primer_info   = M structs with fields 'Header' and 'Sequence', as output by fastaread
% COMBINE_MODE = 1: combine counts for primers with the same Header tag, after the first tab. 
%
% (C) R. Das, 2013

if ~exist( 'COMBINE_MODE' ) COMBINE_MODE = 1; end;

if COMBINE_MODE == 0;
  D_combine = D;
  primer_info_combine = primer_info; 
  return;
end

N_primer_in_D = length( D );
N_primer = length( primer_info );
if ( N_primer_in_D ~= N_primer ) 
  fprintf( 'Disagreement between number of primers in primer_info [%d] and in D [%d]\n', N_primer, N_primer_in_D );
  return;
end  

% save mapping.
tags = {};
index_for_tag = []; 
for j = 1:N_primer
  
  complete_tag = primer_info(j).Header;
  
  tag = remove_text_before_first_tab( complete_tag );
  
  found_tag = 0;
  if length( tag) > 0; % could be that user didn't specify enough info to combine primers. 
    found_tag = strcmp( tag, tags );
  end
  
  if sum( found_tag ) == 0
    N_tags_combine = length( tags ) + 1;
    tags{ N_tags_combine } = tag;
    primer_info_combine( N_tags_combine ) = primer_info(j);
    index_for_tag(j) = N_tags_combine;
  else
    index_for_tag(j) = found_tag(1);    
  end

    
end

D_combine = {};
for i = 1:N_tags_combine

  D_new = D{1}*0;

  for j = (find( index_for_tag == i) )
    D_new = D_new + D{j};
  end

  D_combine{i} = D_new;
end

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tag = remove_text_before_first_tab( tag_in )

tag = '';
cols = split_string( tag_in, sprintf('\t') );

if length( cols ) < 2; return; end;

tag = join_string( cols(2:end), sprintf('\t') );
tag = strrep( tag, 'nomod','no mod' );