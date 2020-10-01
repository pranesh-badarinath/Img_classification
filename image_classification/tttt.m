clc
clear all
close all
load result.mat
load class_name.mat
actual=r(:,1);
pred=r(:,2);

%%
[accuracy,numcorrect,confus,precision,recall,F1_score] = compute_accuracy_F2(actual,pred)
