function outfilename = get_iterfit_filename( rfilename );

outfilename = strrep( rfilename, '.rdat', '.ITERFITX.rdat' );
rdat_name = basename( outfilename );
outfilename = strrep( outfilename, rdat_name, ['ITERFIX/',rdat_name] );
