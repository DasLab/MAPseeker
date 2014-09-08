function extract_fastq_subset(file_name, N)

if ~exist(file_name,'file');
    fprintf(2,'WARNING: fastq file not found.\n');
    return;
end;
if ~exist('N','var') || isempty(N); N = 100; end;

tic;
fid = fopen(file_name,'r');
fod = fopen('temp.txt','w');
fprintf('Extracting...\n');

fgetl(fid);
count = 0;
while ~feof(fid);
    fseek(fid,159*100000,0);
    fgetl(fid);
    a = 0;
    while a == 0 && ~feof(fid)
        b = fgetl(fid);
        c = strrep(strrep(strrep(strrep(strrep(b,'A',''),'G',''),'C',''),'T',''),'N','');
        if isempty(c);
            a = 1;
            fprintf(fod, [b,'\n']);
            count = count + 1;
        end;
    end;
end;
fclose(fid);
fclose(fod);
fprintf(['Reads extracted: ',num2str(count),'.\n']);

fid = fopen('temp.txt','r');
fod = fopen('extract.txt','w');

if N>count; N = count; end;
list = randperm(count, N);
cursor = 1;
while ~feof(fid);
    if ismember(cursor, list);
        fprintf(fod, [fgetl(fid),'\n']);
    else
        fgetl(fid);
    end;
    cursor = cursor + 1;
end;
fclose(fid);
fclose(fod);
fprintf(['Reads extracted: ',num2str(N),'.\n']);

delete('temp.txt');
toc;

