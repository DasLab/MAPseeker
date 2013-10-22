function l = join_string( cols, delimiter );
% l = join_string( cols, delimiter );
%
%  default delimiter is space.
%

if nargin==0; help( mfilename ); return; end;

if ~exist( 'delimiter') delimiter = ' '; end;

% convert \t and \n to tab and newline...
delimiter = sprintf( delimiter);

l = cols{1};
for i = 2:length(cols)
  l = [l, delimiter, cols{i} ];
end