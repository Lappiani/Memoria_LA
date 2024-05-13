clear all; clc;

load FF2530Z_1992.txt; %test assets returns 
load CAPMfactors_1992.txt; %monthly factor(s) Mkt-RF
load Tbill_onemonthp_1992.txt;     %1 month T-bill rate

% define returns
ff=FF2530Z_1992(:,2:56);  %calculate excess returns for test assets
Rf=Tbill_onemonthp_1992(:,2:2);       %dimension 1056x1
for i=1:55
    ff(:,i)=ff(:,i)-Rf;
end
ffmean=mean(ff)';

[T,N]=size(ff); %T:# of months in the serie N:# of portfolios/assets

disp('MODEL RESULTS');
%=================================================
%                First Pass  
%=================================================
facFF=CAPMfactors_1992(:,2:2);
facFF=[ones(T,1),facFF];   %add constant

for i=1:55     %run time-series regression for each of the 25+30 portfolios
    result3pass=ols(ff(:,i), facFF);
    betaFF(i,:)=result3pass.beta';
    tvalueFF(i,:)=result3pass.tstat'
    adjR2FF(i,:)=result3pass.rbar;
    errFF(:,i)=result3pass.resid;
end;
RbarpFF=mean(adjR2FF)
L=1; %L: number of factors
alpha=betaFF(:,1); %constant (alpha)
sigma=cov(errFF)*(T-1)/(T-L-1);  
omega=cov(facFF(:,2:end)); 
sigmaFull=cov(ff);
Rp_bar=mean(facFF(:,2:end))'
GRS_F=(T/N)*[(T-N-L)/(T-L-1)]*[(alpha'*inv(sigma)*alpha)/(1+Rp_bar'*inv(omega)*Rp_bar)]
GRS_F2=(T/N)*[(T-N-L)/(T-L-1)]*[(alpha'*inv(sigmaFull)*alpha)/(1+Rp_bar'*inv(omega)*Rp_bar)]
disp('Significance level of the F test is:');
disp(fcdf(GRS_F, N, T-N-L));

% The critical values
disp('The critical values of the F tests of 95% and 99% are:')
disp(finv(0.95, N, T-N-L));
disp(finv(0.99, N, T-N-L));

alphaabs=abs(alpha);

disp('Time Series Main Results:')
avgerror=mean(alphaabs)
RbarpFF=mean(adjR2FF)
GRS_F=(T/N)*[(T-N-L)/(T-L-1)]*[(alpha'*inv(sigma)*alpha)/(1+Rp_bar'*inv(omega)*Rp_bar)]
p_value_F=1-fcdf(GRS_F,N,T-N-L)  %p-value above 5% does not reject all alphas equal to zero (F-GRS test)

%============================================================
%                Second Pass (for average returns)
%============================================================

betaFF(:,1)=1;  %eliminate this comment (Cuando saco el intercepto % perfecto fit)
result2pass=ols(ffmean, betaFF);  %run cross-sectional regression for average returns
RP2p=result2pass.beta';
RPtvalue2p=result2pass.tstat';
adjR22p=result2pass.rbar;
pred_return=result2pass.yhat';

disp('     mean      tstat');
disp([RP2p', RPtvalue2p']);
disp('Adjusted R squared='); disp(adjR22p);

xxx=[0,2];  %set the range of for x and y axis
figure (1)
scatter (pred_return,ffmean,'filled','r'); title 'CAPM - FF25+FF30 industries (1927-2014 monthly excess returns)';xlabel 'predicted excess return'; ylabel 'actual excess return';
ax.XLim = xxx;
ax.YLim = xxx;
line(xxx,xxx);
legend ('definition','central difference','location', 'South')

%======================================================================
%         Second Pass  (cross-sectional reg. for every month)
%======================================================================
disp('Second Pass (cross-sectional reg. for every month'),

betaFF(:,1)=1;
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
