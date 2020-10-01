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
db=[];
for i=1:num_class;
f=fullfile(img_folder,subDirsNames(i).name);
data_img=dir(fullfile(f,'*.jpg'));
data_img(16:end)=[];
num_img=length(data_img);
    for j=1:num_img;
        imname=data_img(j).name;
        fname=fullfile(f,imname);
        im=imread(fname);
        imgs.name=imname;
        imgs.class=subDirsNames(i).name;
        imgs.F=[FeatureStatistical1(im)];
        db=[db;imgs];
    end
   
end

%%
save db.mat db
