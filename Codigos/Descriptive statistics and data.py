import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
# from statsmodels.tsa.ar_model import AutoReg

df = pd.read_csv(r"C:\Users\USER\OneDrive\Escritorio\Memoria\Memoria_LA\Codigos\Crypto_data250.csv")

stats_df = pd.DataFrame()


# Se calcula para cada moneda

for symbol in df['Symbol'].unique():
    subset = df[df['Symbol'] == symbol]
    
    
    subset['Returns'] = subset['Adj Close'].pct_change()
    
    
    subset = subset.dropna()
    

    if not subset.empty:
        
        mean = subset['Returns'].mean()
        median = subset['Returns'].median()
        std_dev = subset['Returns'].std()
        min_value = subset['Returns'].min()
        max_value = subset['Returns'].max()
        percentile_10 = np.percentile(subset['Returns'], 10)
        percentile_90 = np.percentile(subset['Returns'], 90)

        # Calculate AR(1)
        # model = AutoReg(subset['Returns'], lags=1)
        # model_fit = model.fit()
        # coef = model_fit.params

        stats_df = stats_df.append({
            'Symbol': symbol,
            'Mean': mean,
            'Median': median,
            'Standard Deviation': std_dev,
            'Minimum': min_value,
            'Maximum': max_value,
            '10th Percentile': percentile_10,
            '90th Percentile': percentile_90,
            # 'AR(1)': coef[1]
        }, ignore_index=True)


symbols = ['BTC-USD', 'ETH-USD', 'BNB-USD']

plt.figure(figsize=(18,9))

for s in symbols:
    returns = df[df['Symbol'] == s]['Adj Close'].pct_change().dropna()
    plt.hist(returns, bins=50, alpha=0.5, label=s)

plt.title('Frequency of Returns')
plt.xlabel('Returns')
plt.ylabel('Frequency')
plt.legend(loc='upper right')
plt.show()
