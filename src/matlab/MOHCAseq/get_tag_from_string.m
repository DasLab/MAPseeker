function values = get_tag_from_string( header_string, tag );;
% values = get_tag_from_string( header_string, tag );
%
%  Figure out values of specific annotations from tab-delimited string
%   E.g., with 
%
%    x = 'sequence:ACGU  offset:89'
%
%    get_tag( x, 'offset' ) will give '89'. You can then use str2num to convert
%     to int.
% for use in parsing data_annotations or annotations cells.
%
%
% (C) R. Das, 2013

if nargin < 1; help( mfilename ); return; end;

values = get_tag( split_string( header_string, sprintf('\t') ), tag );

