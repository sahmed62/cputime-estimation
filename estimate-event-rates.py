import sys

import pandas as pd

import numpy as np
from sklearn.linear_model import LinearRegression

import matplotlib
import matplotlib.pyplot as plt


if len(sys.argv) != 3:
    print ("Usage: ", sys.argv[0], " <input CSV> <output CSV>")
    print ("    got:", sys.argv)
    sys.exit(2)
else :
    InputFile=sys.argv[1]
    OutputFile=sys.argv[2]
#if

# Import the file and drop the last column
df = pd.read_csv(InputFile, delimiter=',')

# Extract the workload list
workload_list = [   'ackermann',
                    'hamming',
                    'gray',
                    'branch',
                    'longjmp',
                    'funccall',
                    'funcret',
                    'cache-l1',
                    'cache-l3',
                    'stream-mem',
                    'matrix-add-l1',
                    'matrix-add-l2',
                    'matrix-add-l3',
                    'matrix-add-mem',
                    'matrix-trans-l1',
                    'matrix-prod-mem',
                    'tree-rb-mem',
                    'tree-binary-mem',
                    'radixsort-mem',
                    'skiplist-mem']

event_list = ['cycles', 'branches', 'branch misses', 'L1-I loads', 'L1-I misses', 'L1-D loads', 'L1-D misses', 'L3 loads', 'L3 misses']

# Initialize the heatmap
coeff_map = np.zeros([len(workload_list), 9])
offs_map = np.zeros([len(workload_list), 9])
score_map = np.zeros([len(workload_list), 9])

output_dict = { 'workload': ([None] * len(workload_list)),
                'cycles rate': np.zeros([len(workload_list)]),
                'branches rate': np.zeros([len(workload_list)]),
                'branch misses rate': np.zeros([len(workload_list)]),
                'L1-I loads rate': np.zeros([len(workload_list)]),
                'L1-I misses rate': np.zeros([len(workload_list)]),
                'L1-D loads rate': np.zeros([len(workload_list)]),
                'L1-D misses rate': np.zeros([len(workload_list)]),
                'L3 loads rate': np.zeros([len(workload_list)]),
                'L3 misses rate': np.zeros([len(workload_list)]),
                'cycles offset': np.zeros([len(workload_list)]),
                'branches offset': np.zeros([len(workload_list)]),
                'branch misses offset': np.zeros([len(workload_list)]),
                'L1-I loads offset': np.zeros([len(workload_list)]),
                'L1-I misses offset': np.zeros([len(workload_list)]),
                'L1-D loads offset': np.zeros([len(workload_list)]),
                'L1-D misses offset': np.zeros([len(workload_list)]),
                'L3 loads offset': np.zeros([len(workload_list)]),
                'L3 misses offset': np.zeros([len(workload_list)]),
                'cycles score': np.zeros([len(workload_list)]),
                'branches score': np.zeros([len(workload_list)]),
                'branch misses score': np.zeros([len(workload_list)]),
                'L1-I loads score': np.zeros([len(workload_list)]),
                'L1-I misses score': np.zeros([len(workload_list)]),
                'L1-D loads score': np.zeros([len(workload_list)]),
                'L1-D misses score': np.zeros([len(workload_list)]),
                'L3 loads score': np.zeros([len(workload_list)]),
                'L3 misses score': np.zeros([len(workload_list)])}

idx=0
for workload in workload_list :
    # filter a sub dataframe for this workload
    workload_bool_filter = df.Workload.values == workload
    workload_df = df[workload_bool_filter]

    # we reshape the variables as we extract them since this is required by
    # the linear regression implementation

    # the independent variable
    wl_instructions = workload_df[' Core 3 instructions'].values.reshape(-1, 1)

    # the dependent variables
    wl_cycles           = workload_df[' Core 3 cpu cycles'].values
    wl_cycles           = wl_cycles.reshape(-1, 1)
    wl_branch_count     = workload_df[' Core 3 branch instructions'].values
    wl_branch_count     = wl_branch_count.reshape(-1, 1)
    wl_branch_misses    = workload_df[' Core 3 branch misses'].values
    wl_branch_misses    = wl_branch_misses.reshape(-1, 1)
    wl_l1icache_loads   = workload_df[' Core 3 L1 i-cache loads'].values
    wl_l1icache_loads   = wl_l1icache_loads.reshape(-1, 1)
    wl_l1icache_misses  = workload_df[' Core 3 L1 i-cache misses'].values
    wl_l1icache_misses  = wl_l1icache_misses.reshape(-1, 1)
    wl_l1dcache_loads   = workload_df[' Core 3 L1 d-cache loads'].values
    wl_l1dcache_loads   = wl_l1dcache_loads.reshape(-1, 1)
    wl_l1dcache_misses  = workload_df[' Core 3 L1 d-cache misses'].values
    wl_l1dcache_misses  = wl_l1dcache_misses.reshape(-1, 1)
    wl_l3dcache_loads   = workload_df[' L3 cache loads'].values
    wl_l3dcache_loads   = wl_l3dcache_loads.reshape(-1, 1)
    wl_l3dcache_misses  = workload_df[' L3 cache misses'].values
    wl_l3dcache_misses  = wl_l3dcache_misses.reshape(-1, 1)

    # fit them
    LR = LinearRegression().fit(wl_instructions, wl_cycles)
    wl_cycles_rate          = LR.coef_[0]
    wl_cycles_offs          = LR.intercept_
    wl_cycles_score         = LR.score(wl_instructions, wl_cycles)

    LR = LinearRegression().fit(wl_instructions, wl_branch_count)
    wl_branch_count_rate    = LR.coef_[0]
    wl_branch_count_offs    = LR.intercept_
    wl_branch_count_score   = LR.score(wl_instructions, wl_branch_count)

    LR = LinearRegression().fit(wl_instructions, wl_branch_misses)
    wl_branch_misses_rate   = LR.coef_[0]
    wl_branch_misses_offs   = LR.intercept_
    wl_branch_misses_score  = LR.score(wl_instructions, wl_branch_misses)

    LR = LinearRegression().fit(wl_instructions, wl_l1icache_loads)
    wl_l1icache_loads_rate  = LR.coef_[0]
    wl_l1icache_loads_offs  = LR.intercept_
    wl_l1icache_loads_score = LR.score(wl_instructions, wl_l1icache_loads)

    LR = LinearRegression().fit(wl_instructions, wl_l1icache_misses)
    wl_l1icache_misses_rate = LR.coef_[0]
    wl_l1icache_misses_offs = LR.intercept_
    wl_l1icache_misses_score= LR.score(wl_instructions, wl_l1icache_misses)

    LR = LinearRegression().fit(wl_instructions, wl_l1dcache_loads)
    wl_l1dcache_loads_rate  = LR.coef_[0]
    wl_l1dcache_loads_offs  = LR.intercept_
    wl_l1dcache_loads_score = LR.score(wl_instructions, wl_l1dcache_loads)

    LR = LinearRegression().fit(wl_instructions, wl_l1dcache_misses)
    wl_l1dcache_misses_rate = LR.coef_[0]
    wl_l1dcache_misses_offs = LR.intercept_
    wl_l1dcache_misses_score= LR.score(wl_instructions, wl_l1dcache_misses)

    LR = LinearRegression().fit(wl_instructions, wl_l3dcache_loads)
    wl_l3dcache_loads_rate  = LR.coef_[0]
    wl_l3dcache_loads_offs  = LR.intercept_
    wl_l3dcache_loads_score = LR.score(wl_instructions, wl_l3dcache_loads)

    LR = LinearRegression().fit(wl_instructions, wl_l3dcache_misses)
    wl_l3dcache_misses_rate = LR.coef_[0]
    wl_l3dcache_misses_offs = LR.intercept_
    wl_l3dcache_misses_score= LR.score(wl_instructions, wl_l3dcache_misses)

    coeff_map[idx][0] = wl_cycles_rate
    coeff_map[idx][1] = wl_branch_count_rate
    coeff_map[idx][2] = wl_branch_misses_rate
    coeff_map[idx][3] = wl_l1icache_loads_rate
    coeff_map[idx][4] = wl_l1icache_misses_rate
    coeff_map[idx][5] = wl_l1dcache_loads_rate
    coeff_map[idx][6] = wl_l1dcache_misses_rate
    coeff_map[idx][7] = wl_l3dcache_loads_rate
    coeff_map[idx][8] = wl_l3dcache_misses_rate

    offs_map[idx][0] = wl_cycles_offs
    offs_map[idx][1] = wl_branch_count_offs
    offs_map[idx][2] = wl_branch_misses_offs
    offs_map[idx][3] = wl_l1icache_loads_offs
    offs_map[idx][4] = wl_l1icache_misses_offs
    offs_map[idx][5] = wl_l1dcache_loads_offs
    offs_map[idx][6] = wl_l1dcache_misses_offs
    offs_map[idx][7] = wl_l3dcache_loads_offs
    offs_map[idx][8] = wl_l3dcache_misses_offs

    score_map[idx][0] = wl_cycles_score
    score_map[idx][1] = wl_branch_count_score
    score_map[idx][2] = wl_branch_misses_score
    score_map[idx][3] = wl_l1icache_loads_score
    score_map[idx][4] = wl_l1icache_misses_score
    score_map[idx][5] = wl_l1dcache_loads_score
    score_map[idx][6] = wl_l1dcache_misses_score
    score_map[idx][7] = wl_l3dcache_loads_score
    score_map[idx][8] = wl_l3dcache_misses_score

    output_dict['workload'][idx] = workload

    output_dict['cycles rate'][idx] = wl_cycles_rate
    output_dict['branches rate'][idx] = wl_branch_count_rate
    output_dict['branch misses rate'][idx] = wl_branch_misses_rate
    output_dict['L1-I loads rate'][idx] = wl_l1icache_loads_rate
    output_dict['L1-I misses rate'][idx] = wl_l1icache_misses_rate
    output_dict['L1-D loads rate'][idx] = wl_l1dcache_loads_rate
    output_dict['L1-D misses rate'][idx] = wl_l1dcache_misses_rate
    output_dict['L3 loads rate'][idx] = wl_l3dcache_loads_rate
    output_dict['L3 misses rate'][idx] = wl_l3dcache_misses_rate

    output_dict['cycles offset'][idx] = wl_cycles_offs
    output_dict['branches offset'][idx] = wl_branch_count_offs
    output_dict['branch misses offset'][idx] = wl_branch_misses_offs
    output_dict['L1-I loads offset'][idx] = wl_l1icache_loads_offs
    output_dict['L1-I misses offset'][idx] = wl_l1icache_misses_offs
    output_dict['L1-D loads offset'][idx] = wl_l1dcache_loads_offs
    output_dict['L1-D misses offset'][idx] = wl_l1dcache_misses_offs
    output_dict['L3 loads offset'][idx] = wl_l3dcache_loads_offs
    output_dict['L3 misses offset'][idx] = wl_l3dcache_misses_offs

    output_dict['cycles score'][idx] = wl_cycles_score
    output_dict['branches score'][idx] = wl_branch_count_score
    output_dict['branch misses score'][idx] = wl_branch_misses_score
    output_dict['L1-I loads score'][idx] = wl_l1icache_loads_score
    output_dict['L1-I misses score'][idx] = wl_l1icache_misses_score
    output_dict['L1-D loads score'][idx] = wl_l1dcache_loads_score
    output_dict['L1-D misses score'][idx] = wl_l1dcache_misses_score
    output_dict['L3 loads score'][idx] = wl_l3dcache_loads_score
    output_dict['L3 misses score'][idx] = wl_l3dcache_misses_score

    idx=idx+1
#for

output_df = pd.DataFrame(output_dict, columns = ['workload',
                                                'cycles rate',
                                                'branches rate',
                                                'branch misses rate',
                                                'L1-I loads rate',
                                                'L1-I misses rate',
                                                'L1-D loads rate',
                                                'L1-D misses rate',
                                                'L3 loads rate',
                                                'L3 misses rate',
                                                'cycles offset',
                                                'branches offset',
                                                'branch misses offset',
                                                'L1-I loads offset',
                                                'L1-I misses offset',
                                                'L1-D loads offset',
                                                'L1-D misses offset',
                                                'L3 loads offset',
                                                'L3 misses offset',
                                                'cycles score',
                                                'branches score',
                                                'branch misses score',
                                                'L1-I loads score',
                                                'L1-I misses score',
                                                'L1-D loads score',
                                                'L1-D misses score',
                                                'L3 loads score',
                                                'L3 misses score'])
output_df.to_csv(OutputFile)

# Generate the heat map

fig, ax = plt.subplots()
im = ax.imshow(coeff_map)

# We want to show all ticks...
ax.set_xticks(np.arange(len(event_list)))
ax.set_yticks(np.arange(len(workload_list)))
# ... and label them with the respective list entries
ax.set_xticklabels(event_list)
ax.set_yticklabels(workload_list)
# Rotate the tick labels and set their alignment.
plt.setp(ax.get_yticklabels(), rotation=45, ha="right",
         rotation_mode="anchor")
plt.setp(ax.get_xticklabels(), rotation=90, ha="right",
         rotation_mode="anchor")

# Loop over data dimensions and create text annotations.
for i in range(len(workload_list)):
    for j in range(len(event_list)):
        text = ax.text(j, i, "{:.2f}".format(coeff_map[i, j]),
                       ha="center", va="center", color="w", fontsize="large")
    #for
#for

ax.set_title("Event rates per instruction")
fig.tight_layout()
plt.show()

#CSVdict= df.to_dict()
#https://matplotlib.org/3.1.1/gallery/images_contours_and_fields/image_annotated_heatmap.html
#https://stackoverflow.com/questions/24662571/python-import-csv-to-list
#https://stackoverflow.com/questions/29051573/python-filter-list-of-dictionaries-based-on-key-value

