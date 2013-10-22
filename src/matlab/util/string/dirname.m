function d = dirname( tag );

remain = tag;
d = '';
while ~isempty( remain )
  [token, remain ] =strtok( remain, '/' );
  if ~isempty(remain) d = [d,token,'/']; end
end
