function [clvg_rates, mdf_rates, clvg_prjcs, mdf_prjcs, clvg_prjcs_err, mdf_prjcs_err] = determine_cleavage_modification_percentage (D_raw, primer_info, full_extension_correction_factor, Noffset, colorcode, is_diff)

lgnd = cell(1, length(D_raw));
for i = 1:length(primer_info)
    [tok, rem] = strtok(primer_info(i).Header, char(9));
    tok2 = strtok(rem, char(9));
    lgnd{i} = [tok,'   ',tok2];
end;

if ~exist('full_extension_correction_factor','var') || isempty(full_extension_correction_factor); full_extension_correction_factor = 0.25; end;
if ~exist('Noffset','var') || isempty(Noffset); Noffset = 8; end;
if ~exist('colorcode','var') || isempty(colorcode); colorcode = jet(length(D_raw)); end;
if ~exist('is_diff','var') || isempty(is_diff); is_diff = 0; end;

fprintf('Applied full_extention_correction_factor = ');
if is_diff;
    fprintf('individual a2/a1.\n');
else
    fprintf([num2str(full_extension_correction_factor),'.\n']);
end;
fprintf(['Applied diagonal_cutoff_offset = ', num2str(Noffset),'.\n\n']);

sz_D = min(size(D_raw{1}'));

clvg_prjcs = zeros(length(D_raw), sz_D - 2);
clvg_rates = zeros(2, length(D_raw));
clvg_prjcs_err = zeros(length(D_raw), sz_D - 2);
mdf_prjcs = zeros(length(D_raw), sz_D - 2);
mdf_rates = zeros(1, length(D_raw));
mdf_prjcs_err = zeros(length(D_raw), sz_D - 2);

for i = 1:length(D_raw)
    
    D_sub = D_raw{i}';                                          %mirror by diagonal
    D_sub = D_sub(1:sz_D,1:sz_D);                               %reomove univ region
    D_sub = D_sub(2:end,1:end-1);                               %remove pos 1 (univ only)
    D_sub(end-1,:) = D_sub(end-1,:) + D_sub(end,1:end);         %sum STAR to full-length
    D_sub(end-1,end-1) = D_sub(end-1,end-1) + D_sub(end-1,end);
    D_sub = D_sub(1:end-1,1:end-1);                             %remove last pos (STAR)
    
    % Noffset for diaganol
    for j = 1:size(D_sub,1);
        D_sub(j,max((j-Noffset+1),1):j) = 0;
    end;
    
    count_unclvg = D_sub(end,1);                                %c
    count_clvg = sum(D_sub(end,2:end));                         %a1
    count_clvg_2 = sum(D_sub(1:end-1,1));                       %a2
    count_new_frag = sum(sum(D_sub(1:end-1,:)));                %b
    %if abs(count_clvg-count_clvg_2) > (count_clvg+count_clvg_2)/2/2;
    fprintf([lgnd{i}, ':\t a1 = ',num2str(count_clvg),';\t a2 = ',num2str(count_clvg_2),';\n']);
    fprintf(['\t\t\t\tideal full_extension_correction_factor = ', num2str(count_clvg_2/count_clvg),'.\n']);
    %end;
    if ~is_diff;
        D_sub(:,1) = D_sub(:,1)/full_extension_correction_factor;
    else
        D_sub(:,1) = D_sub(:,1)/ (count_clvg_2/count_clvg);
    end;
    D_err = sqrt(D_sub);
    
    %D_clvg = D_sub([end,1:(end-1)],:);                         %move last pos (full-length) to top
    %D_clvg = D_sub;
    clvg_prjc = sum(D_sub,2);                                   %horizontal projection
    clvg_prjc_err = sum(D_err,2);
    %clvg_prjc(end) = clvg_prjc(end) / full_extension_correction_factor;
    %clvg_prjc = clvg_prjc ./ cumsum(clvg_prjc);                %attenuation correction, divided by cumulative sum
    clvg_prjc = clvg_prjc / sum(D_sub(end,2:end));
    clvg_prjc = [clvg_prjc(1:end-1);0];                         %crop out full-length (100%), last-nucleotode cleavage is 0
    clvg_prjc_err = clvg_prjc_err / sum(D_sub(end,2:end));
    clvg_prjc_err = [clvg_prjc_err(1:end-1);0];
    
    nomod_rate = count_unclvg / (count_unclvg + count_clvg);    %c/(a1+c)
    clvg_rate = count_new_frag / count_clvg;                    %b/c
    clvg_prjcs(i,:) = clvg_prjc;
    clvg_prjcs_err(i,:) = clvg_prjc_err;
    clvg_rates(:,i) = [nomod_rate, clvg_rate];
    
    
    %D_mdf = D_sub;
    [mdf_prjc, mdf_rate, mdf_prjc_err] = get_modification_projection( D_sub', 1, 0 ); %already cutoff and corrected in D_sub
    
%     mdf_prjc = sum(D_sub,1);
%     mdf_prjc(1) = mdf_prjc(1) / full_extension_correction_factor;
%     for j = 1:sz_D-2
%         mdf_prjc(j) = mdf_prjc(j) / sum(sum(D_sub(j:end,1:j))); %attenuation correction, divided by box sum
%     end;
    mdf_prjc = [mdf_prjc(2:end), 0];                            %crop out full-length (100%), last-nucleotode reactivity is 0
    mdf_prjc_err = [mdf_prjc_err(2:end), 0];
    %     mdf_rate = sum(mdf_prjc);
    %mdf_rate = sum(sum(D_sub(2:end-1,2:end-1))) / (sum(D_sub(1:end,1) + sum(D_sub(end, 2:end))));
    mdf_prjcs(i,:) = [mdf_prjc,zeros(1,sz_D - 2-length(mdf_prjc))];
    mdf_prjcs_err(i,:) = [mdf_prjc_err, zeros(1,sz_D - 2-length(mdf_prjc_err))];
    mdf_rates(i) = mdf_rate;
end;

clvg_prjcs = clvg_prjcs';
clvg_prjcs_err = clvg_prjcs_err';
mdf_prjcs = mdf_prjcs';
mdf_prjcs_err = mdf_prjcs_err';

figure(7);clf;
set_print_page(gcf, 0, [0 0 800 600]);
set(gcf,'name', '1D Projection');
subplot(2,1,1);
for i = 1:length(D_raw)
    stairs(1:length(clvg_prjcs(:,i)), clvg_prjcs(:,i),'color',colorcode(i,:),'linewidth',2);
    hold on;
end;
set(gca,'xgrid','on');
legend(lgnd,'Location','NorthEast');
ylabel('Percantage Rates','FontSize',12,'FontWeight','Bold');
xlabel('Sequence position','FontSize',12,'FontWeight','Bold');
title('Cleavage Projection');
subplot(2,1,2);
for i = 1:length(D_raw)
    stairs(1:length(mdf_prjcs(:,i)), mdf_prjcs(:,i),'color',colorcode(i,:),'linewidth',2);
    hold on;
end;
set(gca,'xgrid','on');
legend(lgnd,'Location','NorthEast');
ylabel('Percantage Rates','FontSize',12,'FontWeight','Bold');
xlabel('Sequence position','FontSize',12,'FontWeight','Bold');
title('Modification Projection');

