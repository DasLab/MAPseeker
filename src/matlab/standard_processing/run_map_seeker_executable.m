function  run_map_seeker_executable( library_file, primer_file, inpath, align_all );
%  run_map_seeker_executable( library_file, primer_file, inpath, align_all );

%%%%%%%%%%%%%%%%%%%%
% this is hard-wired. Should make the executable figure it out!
n = 8; 

if ~exist( 'align_all' ) align_all = 0; end;
  
% look for MAPseeker executable
MAPseeker_EXE = [dirname( which( mfilename ) ), '/../../cmake/apps/MAPseeker' ]
if ~exist( MAPseeker_EXE, 'file' );  fprintf( 'Could not find compiled executable MAPseeker! Not running MAPseeker \n' ); return; end;
if ( align_all ) MAPseeker_EXE = [ MAPseeker_EXE, ' --align_all']; end;

%%%%%%%%%%%%%%%%%%%%
library_file = which( library_file ); % absolute path
primer_file = which( primer_file ); % absolute path

%%%%%%%%%%%%%%%%%%%%
% go into working directory
PWD = pwd();
cd( inpath )

fastqs = dir( '*fastq' );
if length( fastqs ) == 0; fprintf( 'Could not find FASTQ files! Not running MAPseeker \n' ); return; end;
if length( fastqs ) > 2; 
  fprintf( '%s\n,More than two fastq files -- not sure what to do! Not running MAPseeker \n',pwd()); return; 
end

 command = sprintf( 'time %s -1 %s  -2 %s  -l %s  -p %s -n %d', MAPseeker_EXE, fastqs(1).name, fastqs(2).name, library_file, primer_file, n );
%command = sprintf( 'time %s -1 %s  -2 %s  -l %s  -p %s -n %d', MAPseeker_EXE, fastqs(1).name, fastqs(2).name, library_file, primer_file);
system( command );


chdir( PWD );

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outstring = dirname( instring );
dircols = split_string( instring, '/' ); % will only work in unix!
outstring = join_string( dircols(1:end-1), '/');
if instring(1) == '/'; outstring = ['/',outstring]; end;