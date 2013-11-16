function outfilename = get_cohcoa_filename( rfilename );

cleanup_iterfit( rfilename );

outfilename = strrep( rfilename, '.rdat', '.COHCOA.rdat' );
rdat_name = basename( outfilename );
outfilename = strrep( outfilename, rdat_name, ['COHCOA/',rdat_name] );




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cleanup_iterfit( rfilename )
% COHCOA used to be called iterfit.
% a little cleanup...
if exist( [dirname( rfilename ),'/ITERFIX'],'dir' );
  system( ['mv ', dirname( rfilename ),'/ITERFIX','  ',dirname( rfilename ),'/COHCOA'] );
end
  
outfilename = strrep( rfilename, '.rdat', '.ITERFITX.rdat' );
outfilename = [dirname( rfilename ),'/COHCOA/',basename(outfilename)];
if exist( outfilename,'file' )
  system( ['mv ', outfilename,' ',strrep( outfilename, 'ITERFITX','COHCOA' ) ] );
end  