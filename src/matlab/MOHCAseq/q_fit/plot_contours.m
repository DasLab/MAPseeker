function plot_contours( pdb );

[D_sim_a, rad_res, hit_res, dist_matrix, pdbstruct] = get_simulated_data( pdb );contour_levels = [15,30];
colorcode = [1 0.3 1; 0.5 0.5 1];
dist_matrix_smooth = smooth2d( dist_matrix );
hold on
for i = 1:length( contour_levels )
  [c,h]=contour(rad_res, hit_res, tril(dist_matrix_smooth), ...
		contour_levels(i) * [1 1],...
		'color',colorcode(i,:),...
		  'linewidth',0.5 );
end


