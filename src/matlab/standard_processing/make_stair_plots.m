function  make_stair_plots( D, most_common_sequences, RNA_info, primer_info, colorcode, D_err );
%  make_stair_plots( D, most_common_sequences, RNA_info, primer_info, colorcode, D_err );

clf;
set(gcf, 'PaperPositionMode','auto','color','white');
N_display = length( most_common_sequences );

if ~exist( 'D_err') D_err = {}; end;

for j = 1:N_display;
  subplot(N_display,1,j);
  idx = most_common_sequences(j);
  make_stair_plot( idx, D, RNA_info, colorcode, D_err );
end

% make legend
N = length( D );
N_primers = length( primer_info );
if (N_primers ~= N ); fprintf( ['Mismatch in primer numbers: ',num2str(N), ' vs. ', N_primers,'\n']); return; end;

for i = 1:N_primers; 
  tag_cols = split_string( primer_info(i).Header,'\t' );
  if ( length( tag_cols ) > 3 ) tag_cols = tag_cols(1:3);end;
  primer_tags{i} = join_string( tag_cols );
end
subplot(N_display,1,1);
h =  legend( primer_tags );
set(h,'interpreter','none','fontsize',9);

if (N_display > 1 )
  subplot(N_display,1,N_display);
  h=legend( basename(pwd) ); set(h,'interpreter','none','fontsize',6 )
end