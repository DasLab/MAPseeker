function info = fastaread_structures( filename );

fid = fopen( filename );
count = 0;
info.Header = '';
info.Sequence = '';
info.Structure = '';

seq_defined = 0; struct_defined = 0;

while ~feof( fid )

  line = fgetl( fid );

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
	if seq_defined & ~struct_defined
	  L = length( info(count).Sequence );
      if length( line ) < L
        fprintf( '\nLength of structure line (%d) is less than length of sequence line (%d) for the following!\n%s\n%s\n%s\n', ...
                length(line), length( info(count).Sequence ), info(count).Header, info(count).Sequence,line );
        structure = '';
        for i = 1:length(L); structure = [structure,'.']; end;
        info(count).Structure = structure;
      else
        info( count ).Structure = line(1:L);
      end
	  struct_defined = 1;
	end
      end
    end
  end
  
end   

fclose( fid );