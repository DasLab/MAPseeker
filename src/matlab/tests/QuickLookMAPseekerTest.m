%% Standard run
% remove files.
f = dir( './stats*.txt' ); for i = 1:length(f); delete( f(i).name); end;
f = dir( './*.rdat' ); for i = 1:length(f); delete( f(i).name); end;
f = dir( './MAPseeker*' ); for i = 1:length(f); delete( f(i).name); end;
if exist( 'Figures','dir' ) rmdir( 'Figures','s');end;

inpath = '../../../example/MAPseq/';
quick_look_MAPseeker( [],[],'../../../example/MAPseq/');

f = dir( './stats*.txt' ); 
assert( length(f) == 5 );
assert( exist( 'Figures' )>0 );
f = dir( './tests.*.rdat' ); 
assert( length(f) == 2 );


%% quick rerun
f = dir( './stats*.txt' ); for i = 1:length(f); delete( f(i).name); end;
f = dir( './*.rdat' ); for i = 1:length(f); delete( f(i).name); end;
f = dir( './MAPseeker*' ); for i = 1:length(f); delete( f(i).name); end;
if exist( 'Figures','dir' ) rmdir( 'Figures','s');end;

inpath = '../../../example/MAPseq/';
quick_look_MAPseeker( [],[],'../../../example/MAPseq/',[],{'noSHAPEscore','no_output_fig','no_output_rdat','no_stair_plots','no_norm','no_backgd_sub'});

f = dir( './stats*.txt' ); 
assert( length(f) == 5 );
assert( ~exist( 'Figures','dir' ) );
f = dir( './tests.*.rdat' ); 
assert( length(f) == 0 );


f = dir( './stats*.txt' ); for i = 1:length(f); delete( f(i).name); end;
f = dir( './*.rdat' ); for i = 1:length(f); delete( f(i).name); end;
f = dir( './MAPseeker*' ); for i = 1:length(f); delete( f(i).name); end;
if exist( 'Figures','dir' ) rmdir( 'Figures','s');end;

