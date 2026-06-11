# Añadir cluster de cyp al metadata para árboles

import pandas as pd

clado1 = "/mnt/c/Users/Valeria/Desktop/trees/cyp51/sin_soporte.csv"
clado2 = "/mnt/c/Users/Valeria/Desktop/trees/cyp51/clado_389_soporte72.csv"
clado3 = "/mnt/c/Users/Valeria/Desktop/trees/cyp51/clado_521_soporte67.csv"
clado4 = "/mnt/c/Users/Valeria/Desktop/trees/cyp51/clado_724_soporte54.csv"

ruta= "/mnt/c/Users/Valeria/Desktop/Afum_metadata.ods"
metadata = pd.read_excel(ruta, sheet_name='final_metadata', engine='odf')
c1 = pd.read_csv(clado1, header=0)
c2 = pd.read_csv(clado2, header=0)
c3 = pd.read_csv(clado3, header=0)
c4 = pd.read_csv(clado4, header=0)
print(c1)

metadata = metadata[['g_sample', 'cyp_cluster']]

dic_g_cluster = {}
# asignar número a cada gt
for g in c1['muestra']:
    dic_g_cluster[g] = 1

print(dic_g_cluster)
for g in c2['muestra']:
    dic_g_cluster[g] = 3
print(dic_g_cluster)

for g in c3['muestra']:
    dic_g_cluster[g] = 4
print(dic_g_cluster)

for g in c4['muestra']:
    dic_g_cluster[g] = 2
print(dic_g_cluster)


metadata['cyp_cluster'] = metadata['cyp_cluster'].astype(object)
metadata['cyp_cluster'] = metadata['g_sample'].map(dic_g_cluster)

print(metadata['cyp_cluster'])

metadata.to_csv("/mnt/c/Users/Valeria/Desktop/trees/cyp51/cyp_clades.tsv", index=False)