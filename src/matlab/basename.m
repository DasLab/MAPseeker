function b = basename( tag );

remain = tag;

while ~isempty( remain )
  [token, remain ] =strtok( remain, '/' );
end

b = token;