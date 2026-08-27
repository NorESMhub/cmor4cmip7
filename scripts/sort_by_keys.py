#/usr/bin/env python

import json

# read in existing entries
fname = '../recipes/template/mapping.json'
with open(fname,'r') as file:
    data_dict = json.load(file)

sorted_data_dict = dict()
sorted_data_dict = data_dict
#print(sorted_data_dict['variable_entry'].keys())
for key in data_dict['variable_entry'].keys():
    print(key)

exit
#sorted_data_dict['Header'] = data_dict['Header']

# import and add more entries
dreq_file='cmip7_dreq_noresm_ocn.txt'
dreq_file='cmip7_dreq_noresm_ocnBgc.txt'
with open(dreq_file, 'r') as ifile:
    for n, line in enumerate(ifile,1):
        line = line.strip()
        if not line:
            continue

        parts = line.split()
        if len(parts) < 2:
            print(f"Warning: line {line_num} has fewer than 2 columns, skipping")
            continue

        key=parts[0]
        original_name = " ".join(parts[1:])
        sorted_data_dict['variable_entry'][key] = {"original_name": original_name, "sources": {"var": 1.0},"postprocs": {"post": True},"history": "", "comment": ""}
        print(f"key:{key}")

sorted_data_dict['variable_entry'] = {k: v for k, v in sorted(data_dict['variable_entry'].items(), key=lambda item: item[0])}

# write to new json file
fname2 = '../recipes/template/mapping_sorted.json'
with open(fname2, 'w') as f:
    json.dump(sorted_data_dict, f, indent=4)

