function plot_contours( pdb, contour_levels );

if ~exist( 'contour_levels', 'var' ) contour_levels = [15, 30 ]; end;

rad_atoms = {'P','O2''', 'C1''' };
hit_atoms = {'P','C4''', 'C1''' };
count = 0;
for i = 1:length( rad_atoms )
  for j = 1:length( hit_atoms )
    count = count + 1;
    [D_sim_a, rad_res, hit_res, dist_matrix(:,:,count), pdb] = get_simulated_data( pdb, rad_atoms{i}, hit_atoms{j} );
  end
end
dist_matrix = squeeze( min( dist_matrix, [],  3 ) );

colorcode = [1 0.3 1; 0.5 0.5 1];
dist_matrix_smooth = smooth2d( dist_matrix );
hold on
for i = 1:length( contour_levels )
  [c,h]=contour(rad_res, hit_res, tril(dist_matrix_smooth), ...
		contour_levels(i) * [1 1],...
		'color',colorcode(i,:),...
		  'linewidth',0.5 );
end


