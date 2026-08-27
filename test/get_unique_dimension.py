#/usr/bin/env python

import json

fname = '../tables/CMIP7_ocean.json'
#fname = '../tables/CMIP7_seaIce.json'
#fname = '../tables/CMIP7_ocnBgchem.json'
#fname = '../tables/CMIP7_landIce.json'

with open(fname,'r') as file:
    data = json.load(file)

    coord_full = {key.split("_")[1] for key in data['variable_entry']}

    dimensions_full = {tuple(data['variable_entry'][key]['dimensions']) for key in data['variable_entry']}

    dimensions_single = {item for key in data['variable_entry']
                        for item in data['variable_entry'][key]['dimensions']}

print('full coord')
for item in coord_full:
    print(item)

print("\n")

print('full dimensions')
for item in dimensions_full:
    print(item)

print('')

print('sigle dimensions')
print(dimensions_single)

