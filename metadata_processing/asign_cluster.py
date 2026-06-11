# script para unir datos clumpak con samples

import pandas as pd

samples = pd.read_csv('/mnt/c/Users/Valeria/Desktop/admixture/samples_maf_cluster.txt', header=None)
clumpak_data = pd.read_csv('/mnt/c/Users/Valeria/Desktop/admixture/k6/1777455486/K=6/CLUMPP.files/ClumppIndFile.output', sep='\s+', header=None)

clumpak_data = clumpak_data.iloc[:, 5:11] # cambiar dependiendo de número de clusters (para 6 = 5:11)
# print(clumpak_data)

# añadir sample names a clumpak data
clumpak_data.index = samples.iloc[:, 0].values

# print(clumpak_data)

# asignar cluster
for sample, row in clumpak_data.iterrows():
    max_col = row.idxmax()
    cluster = max_col - 4
    # print(f"{sample}: {cluster}")

result = pd.DataFrame({
    'Sample_Name': clumpak_data.index,
    'cluster': clumpak_data.idxmax(axis=1).map({5:1, 6:2, 7:3, 8:4, 9:5, 10:6})
})

result.to_csv('/mnt/c/Users/Valeria/Desktop/admixture/k6/clusters_6.csv', index=False) # clusters clumpak
cluster_6 = pd.read_csv('/mnt/c/Users/Valeria/Desktop/admixture/k6/clusters_6.csv', header=0)


# Añadir a metadata 
metadata_full = pd.read_excel('/mnt/c/Users/Valeria/Desktop/Afum_metadata.ods', header=0, engine='odf', sheet_name='final_metadata')
metadata_full = metadata_full[['Sample_Name', 'BioinfoName', 'Japanese Cluster']]
# Primer merge por Sample_Name
all_data = pd.merge(metadata_full, cluster_6, on='Sample_Name', how='left')

# Para los que no coincidieron, intentar por BioinfoName
no_match = all_data[all_data['cluster'].isna()]
metadata2 = metadata_full[metadata_full['Sample_Name'].isin(no_match['Sample_Name'])]

cluster_5_renamed = cluster_6.rename(columns={'Sample_Name': 'BioinfoName'})
second_merge = pd.merge(metadata_full[['Sample_Name', 'BioinfoName']], cluster_5_renamed, on='BioinfoName', how='inner')

# Rellenar los NaN del primer merge con los del segundo
all_data = all_data.merge(second_merge[['Sample_Name', 'cluster']], on='Sample_Name', how='left', suffixes=('', '_bio'))
all_data['cluster'] = all_data['cluster'].combine_first(all_data['cluster_bio'])
all_data.drop(columns=['cluster_bio'], inplace=True)

all_data.to_csv('/mnt/c/Users/Valeria/Desktop/admixture/k6/clusters_6_metadata.csv', index=False)