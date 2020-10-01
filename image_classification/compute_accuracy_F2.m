function [accuracy,numcorrect,confus,precision,recall,F1_score] = compute_accuracy_F2(actual,pred)
if size(actual,1) ~= size(pred,1)
    pred=pred';                                     % converting row vector to column vector
end 
classes = [1:max(max(actual),max(pred))];
numcorrect = sum(actual==pred);
% confussion matrix
for i=1:length(classes)
    a = classes(i);
    d = find(actual==a);                            % d has indices of points with class a
    for j=1:length(classes)
        confus(i,j) = length(find(pred(d)==classes(j)));
    end
end
%% 1.Accuracy (all correct / all) = TP + TN / TP + TN + FP + FN
accuracy =  100*trace(confus)/sum(confus(:));

%%
% 1.Precision (true positives / predicted positives) = TP / TP + FP
% 2.Recall (true positives / all actual positives) = TP / TP + FN
precision=[];
recall=[];
F1_score=[];


for i=1:length(classes)
    S = sum(confus(i,:));
    if S
        recall(i) = confus(i,i) / sum(confus(i,:));
    else
        recall(i) = 0;
    end
    S =  sum(confus(:,i));
    if S
       precision(i) = confus(i,i) / S;
    else
       precision(i) = 0;
    end
     if (precision(i)+recall(i))
         F1_score(i) = 2 * (precision(i)*recall(i)) / (precision(i)+recall(i));
     else
            F1_score(i) = 0;
        end
    
end
end


