function [clvg_rates, mdf_rates, clvg_prjcs, mdf_prjcs] = determine_cleavage_modification_percentage (D_raw, primer_info, full_extension_correction_factor, colorcode)

sz_D = min(size(D_raw{1}'));

clvg_prjcs = zeros(length(D_raw), sz_D - 2);
clvg_rates = zeros(2, length(D_raw));
mdf_prjcs = zeros(length(D_raw), sz_D - 2);
mdf_rates = zeros(1, length(D_raw));

for i = 1:length(D_raw)
    
    D_sub = D_raw{i}';                                              %mirror by diagonal
    D_sub = D_sub(1:sz_D,1:sz_D);                               %reomove univ region
    D_sub = D_sub(2:end,1:end-1);                               %remove pos 1 (univ only)
    D_sub(end-1,:) = D_sub(end-1,:) + D_sub(end,1:end);         %sum STAR to full-length
    D_sub(end-1,end-1) = D_sub(end-1,end-1) + D_sub(end-1,end);
    D_sub = D_sub(1:end-1,1:end-1);                             %remove last pos (STAR)
    
    %D_clvg = D_sub([end,1:(end-1)],:);                          %move last pos (full-length) to top
    %D_clvg = D_sub;
    clvg_prjc = sum(D_sub,2);                                  %horizontal projection
    %clvg_prjc(end) = clvg_prjc(end) / full_extension_correction_factor;
    %clvg_prjc = clvg_prjc ./ cumsum(clvg_prjc);                %attenuation correction, divided by cumulative sum
    clvg_prjc = clvg_prjc / sum(D_sub(end,2:end));
    clvg_prjc = [clvg_prjc(1:end-1);0];                         %crop out full-length (100%), last-nucleotode cleavage is 0
    
    count_unclvg = D_sub(end,1);                                %c
    count_clvg = sum(D_sub(end,2:end));                         %a1
    count_clvg_2 = sum(D_sub(1:end-1,1));                       %a2
    count_new_frag = sum(sum(D_sub(1:end-1,:)));                %b
    
    nomod_rate = count_unclvg / (count_unclvg + count_clvg);    %c/(a1+c)
    clvg_rate = count_new_frag / count_clvg;                    %b/c
    clvg_prjcs(i,:) = clvg_prjc;
    clvg_rates(:,i) = [nomod_rate, clvg_rate];
    
    if abs(count_clvg-count_clvg_2) > (count_clvg+count_clvg_2)/2/2;
        fprintf(['WARNING: a1 (',num2str(count_clvg),') and a2(',num2str(count_clvg_2),') do not agree.\n']);
    end;

    %D_mdf = D_sub;
    mdf_prjc = sum(D_sub,1);
    mdf_prjc(1) = mdf_prjc(1) / full_extension_correction_factor;
    for j = 1:sz_D-2
        mdf_prjc(j) = mdf_prjc(j) / sum(sum(D_sub(j:end,1:j))); %attenuation correction, divided by box sum
    end;
    mdf_prjc = [mdf_prjc(2:end), 0];                            %crop out full-length (100%), last-nucleotode reactivity is 0
    mdf_rate = sum(mdf_prjc);
    %mdf_rate = sum(sum(D_sub(2:end-1,2:end-1))) / (sum(D_sub(1:end,1) + sum(D_sub(end, 2:end))));
    mdf_prjcs(i,:) = mdf_prjc;
    mdf_rates(i) = mdf_rate;
end;

clvg_prjcs = clvg_prjcs';
mdf_prjcs = mdf_prjcs';

lgnd = cell(1, length(D_raw));
for i = 1:length(primer_info)
    [tok, rem] = strtok(primer_info(i).Header, char(9));
    tok2 = strtok(rem, char(9));
    lgnd{i} = [tok,'   ',tok2];
end;

clf;
set_print_page(gcf, 0, [0 0 800 600]);
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

