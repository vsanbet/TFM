# unir datos de vluster
import pandas as pd

metadata = '/mnt/c/Users/Valeria/Desktop/csvs/merged_metadata_updated.csv'
admixture_metadata= '/mnt/c/Users/Valeria/Desktop/csvs/admixture_clusters_5and6.csv'

met = pd.read_csv(metadata, sep = ',', header = 0)
admx = pd.read_csv(admixture_metadata, sep = '\t', header= 0)

print("Columnas de met:", met.columns.tolist())
print("Columnas de admx:", admx.columns.tolist())

final_metadata = pd.merge(met, admx, on = 'BioinfoName', how='left')

# Guardar archivo
final_metadata.to_csv("final_metadata.csv", index=False)
