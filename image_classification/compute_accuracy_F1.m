function [accuracy,numcorrect,confus] = compute_accuracy_F1(actual,pred)
if size(actual,1) ~= size(pred,1)
    pred=pred';
end
classes = [1:max(max(actual),max(pred))];
numcorrect = sum(actual==pred);
accuracy = numcorrect/length(actual); 
for i=1:length(classes)
    a = classes(i);
    d = find(actual==a);     % d has indices of points with class a
    for j=1:length(classes)
        confus(i,j) = length(find(pred(d)==classes(j)));
    end
end
end
    
    