import sys

import pandas as pd

import numpy as np
from sklearn.linear_model import LinearRegression

import matplotlib
import matplotlib.pyplot as plt


if len(sys.argv) != 2:
    print ("Usage: ", sys.argv[0], " <input CSV>")
    print ("    got:", sys.argv)
    sys.exit(2)
else :
    InputFile=sys.argv[1]
#if

# Import the file and drop the last column
df = pd.read_csv(InputFile, delimiter=',')

# Split into test set and training set
df_train=df.sample(frac=0.8,random_state=42)
df_test=df.drop(df_train.index)

indep_col_names = [ ' Core 3 branch misses',
                    ' Core 3 L1 i-cache loads',
                    ' Core 3 L1 i-cache misses',
                    ' Core 3 L1 d-cache loads',
                    ' Core 3 L1 d-cache misses',
                    ' L3 cache loads',
                    ' L3 cache misses']

# Extract the independent vars
df_train_indep=df_train[indep_col_names]
df_train_dep=df_train[' Core 3 cpu cycles']
df_train_instructions = df_train[' Core 3 instructions']

# Convert to np arrays
train_indep = df_train_indep.to_numpy().astype(np.float32)
train_dep = df_train_dep.to_numpy().astype(np.float32)
train_instructions = df_train_instructions.to_numpy().astype(np.float32)

# go to per instruction values
for j in range(len(train_dep)):
    train_indep[j,:] = train_indep[j,:] / train_instructions[j]
    train_dep[j] = train_dep[j] / train_instructions[j]
# for

# Perform linear regression
LR = LinearRegression().fit(train_indep, train_dep)

# Extract the independent vars
df_test_indep=df_test[indep_col_names]
df_test_dep=df_test[' Core 3 cpu cycles']
df_test_instructions = df_test[' Core 3 instructions']

# Convert to np arrays
test_indep = df_test_indep.to_numpy().astype(np.float32)
test_dep = df_test_dep.to_numpy().astype(np.float32)
test_instructions = df_test_instructions.to_numpy().astype(np.float32)

# go to per instruction values
for j in range(len(test_dep)):
    test_indep[j,:] = test_indep[j,:] / test_instructions[j]
    test_dep[j] = test_dep[j] / test_instructions[j]
# for

print(LR.coef_)
print(LR.intercept_)
print(LR.score(test_indep, test_dep))
