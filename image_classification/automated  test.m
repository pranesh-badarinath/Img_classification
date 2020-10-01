clc
clear all
close all
%% Get a list of all folders in this folder.

img_folder='C:\Users\prane\OneDrive\Desktop\matlab _test\101_ObjectCategories';
files    = dir(img_folder);
names    = {files.name};

% Get a logical vector that tells which is a directory.
dirFlags = [files.isdir] & ~strcmp(names, '.') & ~strcmp(names, '..');

% Extract only those that are directories.
subDirsNames = files(dirFlags);

%% Finding the length of  dataset folders:
num_class=length(subDirsNames);

%%
load db.mat

%%
actual=[];
predicted=[];
class_name={subDirsNames.name}

%%

for i=1:num_class;
f=fullfile(img_folder,subDirsNames(i).name);
data_img=dir(fullfile(f,'*.jpg'));
fname=fullfile(f,data_img(16).name);
im=imread(fname);
 
% Find the class the test image belongs

Ftest=[FeatureStatistical1(im)];


% Compare with the feature of training image in the database

for j=1:size(db,1);
    %dist(j,:)=sqrt(sum(power((db(j).F-Ftest),2)));
    dist(j,:) = sum(abs(db(j).F - Ftest))/6;
end   

 m= find(dist==min(dist),1);
[tf, idx] = ismember(class_name, db(m).class);
p=find(idx==1);
actual=[actual;i];
predicted=[predicted;p];
end


%%
r= [actual predicted];
save result.mat r
save class_name.mat class_name