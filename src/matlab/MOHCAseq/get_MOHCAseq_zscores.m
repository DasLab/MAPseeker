function [zscores, zscores_err, zscores_mask, zscores_mask_err] = get_MOHCAseq_zscores( data, data_err, thresh )

%%% Function for getting Z-scores and errors of Z-scores for MOHCA-Seq
%%% data, which is organized in cell arrays as output by MAPseeker. 
%%%
%%%  INPUTS
%%%     data:        Cell array of reactivities, output by MAPseeker  
%%%     data_err:    Cell array of errors in reactivities, output by MAPseeker  
%%%     thresh:      Threshold uncertainty for masking reactivities before calculating zscores_mask 
%%%
%%%  OUTPUTS
%%%     zscores:             Z-scores of reactivities from input D (reactivities not masked before Z-score calculation) 
%%%     zscores_err:         Errors of Z-scores of reactivities, propagated from input D_err
%%%     zscores_mask:        Z-scores of masked reactivities from input D (high-uncertainty reactivities masked before Z-score calculation) 
%%%     zscores_mask_err:    Errors of Z-scores of masked reactivities, propagated from input D_err 
%%%
%%% (C) Clarence Cheng, 2013


if ~exist('thresh');
    thresh = 1;
end

[x, y] = size(data);

zscores = data;
zscores_err = data_err;
zscores_mask = data;
zscores_mask_err = data_err;
data2 = data;

for i = 1:x;
    for j = 1:y
        if data_err(i,j) > thresh
            data2(i,j) = 0;
        end
    end
end

for i = 1:x;    
    [a, b, nonzeros] = find(data(i,:));
    ave = mean(nonzeros);
    stdev = std(nonzeros);
    zscorei = data(i,:);
    zscorei_err = data_err(i,:);
    for j = 1:length(b);
        zscorei(b(j)) = (data(i,b(j)) - ave)/stdev;
        zscorei_err(b(j)) = (1/stdev) * data_err(i,b(j));       % propagate errors
    end
    zscores(i,:) = zscorei;
    zscores_err(i,:) = zscorei_err;
    
    [c, d, nonzeros2] = find(data2(i,:));
    ave2 = mean(nonzeros2);
    stdev2 = std(nonzeros2);
    zscorei_mask = data2(i,:);
    zscorei_mask_err = data_err(i,:);
    for j = 1:length(d);
        zscorei_mask(d(j)) = (data2(i,d(j)) - ave2)/stdev2;
        zscorei_mask_err(d(j)) = (1/stdev2) * data_err(i,d(j));
    end
    zscores_mask(i,:) = zscorei_mask;
    zscores_mask_err(i,:) = zscorei_mask_err;
end



