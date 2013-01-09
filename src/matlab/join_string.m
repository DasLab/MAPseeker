function l = join_string( cols, delimiter );
if ~exist( 'delimiter') delimiter = ' '; end;

l = cols{1};
for i = 2:length(cols)
  l = [l, delimiter, cols{i} ];
end