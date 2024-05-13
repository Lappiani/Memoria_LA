clear;

reg_factors_route = "C:\Users\USER\OneDrive\Escritorio\Memoria\Memoria_LA\Fama-macBeth data\Reg_factors.xlsx";
portfolio_returns_route = "C:\Users\USER\OneDrive\Escritorio\Memoria\Memoria_LA\Fama-macBeth data\Portfolio returns\Portfolio_returns_26_VW.xlsx";

% Periodo 2020 bull market (53,100)
initial_row = 39
final_row = 96
% Load data from first Excel file
[data1, headers1] = xlsread(portfolio_returns_route);
% Test asset returns
FF2530Z_1992 = data1(initial_row:final_row,:); % Assuming the first 56 columns contain the test assets returns

% Extract the number of portfolios
numHeaders = size(headers1, 2)-1;
% numHeaders = 1;
numPortfolios = size(headers1, 2)-1;

% Load data from second Excel file
[data2, headers2] = xlsread(reg_factors_route);

% Factors
CAPMfactors_1992 = data2(initial_row:final_row,:); % Assuming all columns contain the CAPM factors
%load Tbill_onemonthp_1992.txt;     %1 month T-bill rate

% Define returns
ff = FF2530Z_1992(:,:);  % Calculate excess returns for test assets
T = size(ff, 1); % Number of months in the series

% Set risk-free return data to all zeros
Rf = zeros(T, 1);

% Calculate excess returns by subtracting the risk-free rate
for i = 1:numHeaders
    ff(:, i) = ff(:, i) - Rf;
end

% First Pass  
facFF = CAPMfactors_1992(:,:);
facFF = [ones(T, 1), facFF];   % Add constant

betaFF = zeros(numHeaders, 3); % Preallocate matrix to store estimated betas
tvalueFF = zeros(numHeaders, 3); % Preallocate matrix to store t-values
adjR2FF = zeros(numHeaders, 1); % Preallocate vector to store adjusted R-squared values
% errFF = zeros(:, numHeaders); % Preallocate matrix to store residuals

for i = 1:numHeaders

    firstValidRow = find(~isnan(ff(:,i)), 1, 'first');
    % disp(firstValidRow);
    % Run time-series regression for each of the portfolios
    result3pass = ols(ff(firstValidRow:end, i), facFF(firstValidRow:end,:));
    betaFF(i, :) = result3pass.beta';
    tvalueFF(i, :) = result3pass.tstat';
    adjR2FF(i) = result3pass.rbar;
    errFF(:, i) = result3pass.resid;
end;

ffmean=mean(ff)';
RbarpFF = mean(adjR2FF);
L = 1; % Number of factors
alpha = betaFF(:, 1); % Constant (alpha)
sigma = cov(errFF) * (T - 1) / (T - L - 1);  
omega = cov(facFF(:, 2:end)); 
sigmaFull = cov(ff);
Rp_bar = mean(facFF(:, 2:end))';

GRS_F = (T / numPortfolios) * [(T - numPortfolios - L) / (T - L - 1)] * [(alpha' * inv(sigma) * alpha) / (1 + Rp_bar' * inv(omega) * Rp_bar)];
GRS_F2 = (T / numPortfolios) * [(T - numPortfolios - L) / (T - L - 1)] * [(alpha' * inv(sigmaFull) * alpha) / (1 + Rp_bar' * inv(omega) * Rp_bar)];

disp('Significance level of the F test is:');
disp(fcdf(GRS_F, numPortfolios, T - numPortfolios - L));

% The critical values
disp('The critical values of the F tests of 95% and 99% are:')
disp(finv(0.95, 55, T - numPortfolios - L));
disp(finv(0.99, 55, T - numPortfolios - L));

alphaabs = abs(alpha);

disp('Time Series Main Results:')
avgerror = mean(alphaabs);
RbarpFF = mean(adjR2FF);
GRS_F = (T / numPortfolios) * [(T - numPortfolios - L) / (T - L - 1)] * [(alpha' * inv(sigma) * alpha) / (1 + Rp_bar' * inv(omega) * Rp_bar)];
p_value_F = 1 - fcdf(GRS_F, numPortfolios, T - numPortfolios - L);  % p-value above 5% does not reject all alphas equal to zero (F-GRS test)

% Second Pass (for average returns)
betaFF(:, 1) = 1;  % Eliminate this comment (Cuando saco el intercepto % perfecto fit)
result2pass=ols(ffmean, betaFF);  % Run cross-sectional regression for average returns
RP2p = result2pass.beta';
RPtvalue2p = result2pass.tstat';
adjR22p = result2pass.rbar;
pred_return = result2pass.yhat';

disp('     mean      tstat');
disp([RP2p', RPtvalue2p']);
disp('Adjusted R squared=');
disp(adjR22p);

xxx=[0,0.01];  %set the range of for x and y axis
figure (1)
scatter (pred_return,ffmean,'filled','r'); title 'CAPM - FF25+FF30 industries (1927-2014 monthly excess returns)';xlabel 'predicted excess return'; ylabel 'actual excess return';
ax.XLim = xxx;
ax.YLim = xxx;
line(xxx,xxx);
legend ('definition','central difference','location', 'South')

% Second Pass (cross-sectional reg. for every month)
betaFF(:, 1) = 1;


for i=1:T     %run cross-sectional regression for each month
    result2mpass=ols(ff(i,:)', betaFF);
    RP2p(i,:)=result2mpass.beta';
    RPtvalue2p(i,:)=result2mpass.tstat';
    R22p(i,:)=result2mpass.rsqr;
    adjR22p(i,:)=result2mpass.rbar;
    err2p(i,:)=result2mpass.resid';
    pred_return(i,:)=result2mpass.yhat';
end

meanRP=mean(RP2p);
tstat=sqrt(T)*mean(RP2p)./std(RP2p);
Rbarp22=mean(adjR22p);
stdRbar=std(adjR22p);
report=[meanRP',tstat'];
disp('     mean      tstat');
disp(report);
report2=[[Rbarp22 stdRbar]];
disp('Avg.Adj.R2  Std.dev. Adj.R2');
disp(report2);
m_pre_ret=mean(pred_return);

%figure 1
disp('insert here fig.1')

xxx=[0,2];  %set the range of for x and y axis
figure (1)
scatter (m_pre_ret,ffmean,'filled','r'); title 'CAPM - FF25+FF30 industries (1927-2014 monthly excess returns)';xlabel 'predicted excess return'; ylabel 'actual excess return';
ax.XLim = xxx;
ax.YLim = xxx;
line(xxx,xxx);

disp(mean(CAPMfactors_1992));