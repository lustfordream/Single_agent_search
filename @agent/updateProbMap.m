function [prob_map] = updateProbMap(field, mu, sigma, w)
% Construct the target distribution in the field using gaussian mixture
% mu and sigma correpsonds to the vector and matrix of mean and covariance
% of each gaussian. w is the mix
xMin = field.endpoints(1);
xMax = field.endpoints(2);
yMin = field.endpoints(3);
yMax = field.endpoints(4);
step = field.step;
xLength = (xMax-xMin)/step;
yLength = (yMax-yMin)/step;
mix_num = length(w);
[x_axis,y_axis] = meshgrid(xMin+step/2:step:xMax-step/2,yMin+step/2:step:yMax-step/2);
prob_map = zeros(xLength,yLength);
all_prob = zeros(numel(x_axis),mix_num);
for ii = 1:mix_num
    all_prob(:,ii) = mvnpdf([x_axis(:),y_axis(:)],mu(ii,:),sigma(:,:,ii));
    % transform into probability mass
    prob_map(:,:) = w(ii)*(reshape(all_prob(:,ii),size(prob_map))*step^2)'+prob_map(:,:);
end
end