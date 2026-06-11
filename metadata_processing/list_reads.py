# obtener lista de reads para añadir al excel
import pandas as pd

excel = pd.read_csv('/mnt/c/Users/Valeria/Downloads/AFUM_METADATA_DP.xlsx - AFUM_METADATA.csv', header = 0)

columnas = ['BioinfoName']

list_set = excel['BioinfoName'].tolist()

new_names = []
string_name = str('_1.fastq')
for name in list_set:
    nname = str(name) + string_name
    new_names.append(nname)

print(new_names)
print(len(new_names))

with open('reads.txt', 'w') as f:
    for line in new_names:
        f.write(f"{line}\n")