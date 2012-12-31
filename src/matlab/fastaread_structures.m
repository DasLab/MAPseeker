function info = fastaread_structures( filename );

fid = fopen( filename );
line = fgetl( fid );
count = 0;

info.Header = '';
info.Sequence = '';
info.Structure = '';

seq_defined = 0; struct_defined = 0;

while ~feof( fid )

  if length( line ) > 1; 
    if line(1) == '>'; 
      count = count+1;
      seq_defined = 0; struct_defined = 0;
      info(count).Header = line(2:end);
    else
      if ~seq_defined
	info(count).Sequence = line;
	seq_defined = 1;
      else
	if ~struct_defined
	  L = length( info(count).Sequence );
	  info( count ).Structure = line(1:L);
	  struct_defined = 1;
	end
      end
    end
  end
  
  line = fgetl( fid );

end   

fclose( fid );