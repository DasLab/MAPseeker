function cols = split_string( l, delimiter );
%
%  cols = split_string( l, delimiter );
%

if ~exist( 'delimiter') delimiter = ' '; end;
delimiter = sprintf( delimiter ); % in case its \t or \n

remain = l;
cols = {};
while length( remain ) > 0
  [token, remain] = strtok(remain, delimiter);
  cols = [cols, token];
end


