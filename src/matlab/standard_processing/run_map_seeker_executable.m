function  run_map_seeker_executable( library_file, primer_file, inpath, align_all )
%  run_map_seeker_executable( library_file, primer_file, inpath, align_all );

%%%%%%%%%%%%%%%%%%%%
% this is hard-wired. Should make the executable figure it out!
%n = 8;
% Rhiju Das 2018  --> executable *can* figure it out, and found a use case
% where that's good to do (we accidentally ran a READ1 that was too short).
n = 0; 

if ~exist( 'align_all','var' ) align_all = 0; end;

% look for MAPseeker executable
MAPseeker_EXE = [dirname( which( mfilename ) ), '/../../cmake/apps/MAPseeker' ];
fprintf( '\nMAPseeker_EXE:\n%s\n',MAPseeker_EXE);

if ~exist( MAPseeker_EXE, 'file' );  fprintf( 'Could not find compiled executable MAPseeker! Not running MAPseeker \n' ); return; end;
if align_all; MAPseeker_EXE = [ MAPseeker_EXE, ' --align_all']; end;

%%%%%%%%%%%%%%%%%%%%
%library_file = [pwd(),'/',library_file]; % absolute path
%primer_file  = [pwd(),'/', primer_file ]; % absolute path

%%%%%%%%%%%%%%%%%%%%
% go into working directory
PWD = pwd();
%cd( inpath );

fastqs = dir( [inpath,'/*fastq'] );
if isempty( fastqs ); fprintf( 'Could not find FASTQ files! Not running MAPseeker \n' ); return; end;
if length( fastqs ) > 2;
    error(sprintf( '\n\n%s\n\n More than two fastq files -- not sure what to do! Not running MAPseeker \n',pwd()));
end;


command = sprintf( 'time %s -1 %s  -2 %s  -l %s  -p %s -n %d >> MAPseeker_executable.log 2> MAPseeker_executable.err', MAPseeker_EXE, [inpath,'/',fastqs(1).name], [inpath,'/',fastqs(2).name], library_file, primer_file, n );
fprintf( '\nCommand:\n%s\n\n',command);
system( ['echo "',command,'" > MAPseeker_executable.log'] );
%command = sprintf( 'time %s -1 %s  -2 %s  -l %s  -p %s -n %d', MAPseeker_EXE, fastqs(1).name, fastqs(2).name, library_file, primer_file);
system( command );


chdir( PWD );

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outstring = dirname( instring )

dircols = split_string( instring, '/' ); % will only work in unix!
outstring = join_string( dircols(1:end-1), '/');
if instring(1) == '/'; outstring = ['/',outstring]; end;