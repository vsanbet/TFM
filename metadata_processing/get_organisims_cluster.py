import pandas as pd
import sys
import random

file_clusters = sys.argv[1]
file_metadata = sys.argv[2]

cluster_pd = pd.read_excel(file_clusters, engine="odf")
afum_pd = pd.read_excel(file_metadata, engine="odf")

# Diccionario: cluster -> lista de IDs
cluster_dict = {}

for _, row in cluster_pd.iterrows():
    sample_id = row["ID"]
    cluster_num = int(row["Cluster"])

    # Columna de probabilidad correspondiente
    col_name = f"Cluster {cluster_num}"

    # Convertir coma decimal a float
    value = float(str(row[col_name]).replace(",", "."))

    if value >= 0.99:
        cluster_dict.setdefault(cluster_num, []).append(sample_id)

# print(cluster_dict)

# Comprobar qué organismos tenemos
samples_id = list()
for _, row in afum_pd.iterrows():
    sample_id = row['Sample_Name']
    samples_id.append(sample_id)

# print(samples_id)
samples_set = set(samples_id)

have = {}

for cluster, especies in cluster_dict.items():
    comunes = [e for e in especies if e in samples_set]
    if comunes:
        have[cluster] = comunes

"""
for cluster, organisms in have.items():
    print(f'Organismos del cluster {cluster}:')
    for organism in organisms:
        print(f'-{organism}')
"""

for cluster, samples in cluster_dict.items():
    r_samples = random.sample(samples, 10)
    print(f'Muestras {cluster}:')
    for sample in r_samples:
        print(f'-{sample}')