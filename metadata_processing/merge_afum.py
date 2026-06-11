# Unir info de clusters al documento final de metadata 
import pandas as pd

afum_path = '/mnt/c/Users/Valeria/Desktop/Afum_metadata.ods'
clusters_path = '/mnt/c/Users/Valeria/Desktop/admixture/multiple_5/admixture_clusters.tsv'

afum = pd.read_excel(afum_path, sheet_name="final_metadata", engine="odf")
clusters = pd.read_csv(clusters_path, sep='\t')

# Convertir ambos a string para asegurar que coinciden
afum["BioinfoName"] = afum["BioinfoName"].astype(str).str.strip()
clusters["BioinfoName"] = clusters["BioinfoName"].astype(str).str.strip()

# Seleccionar solo las columnas necesarias de clusters
cols = ["BioinfoName", "MajorityCluster"]
clusters_subset = clusters[cols]

# Unir por BioinfoName
resultado = afum.merge(clusters_subset, on="BioinfoName", how="left")
print(resultado)

resultado.to_csv("cluster5.csv", index=False)
