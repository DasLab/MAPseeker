function info = fastaread_structures( filename )

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
            if ~struct_defined && seq_defined % in case no structure defined from previous sequence.
                %assert( count > 0 );
                %structure = '';
                %for i = 1:L; structure = [structure,'.']; end;
                %info(count).Structure = structure;
            end
            count = count+1;
            seq_defined = 0; struct_defined = 0;
            info(count).Header = line(2:end);
        else
            if ~seq_defined
                info(count).Sequence = line;
                seq_defined = 1;
                L = length( info(count).Sequence );
            else
                if seq_defined
                    if ~isempty( strfind( line, '.' ) ) || ~isempty( strfind( line, '(' ) )  || ~isempty( strfind( line, ')' ) )
                        if ~struct_defined; info( count ).Structure = ''; end;
                        if ( length( info(count).Structure ) + length( line ) ) < L
                            info(count).Structure = [ info( count ).Structure, line ];
                        else
                            info( count ).Structure = [ info( count ).Structure, line(1:L) ];
                        end
                        struct_defined = 1;
                    else
                        info( count ).Sequence = [ info( count ).Sequence, line ];
                        L = length( info(count).Sequence );
                    end
                end
            end
        end
    end
    
end

fclose( fid );