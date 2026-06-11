# Script para juntar los datos de Emilia en el merged_metadata.csv para el árbol filogenético en R
import pandas as pd

own_metadata = "/mnt/c/Users/Valeria/Desktop/trees/japanese_control/merged_metadata.csv"
emilia_metadata = '/mnt/c/Users/Valeria/Desktop/csvs/lista_mutaciones.csv'

metadata = pd.read_csv(own_metadata)
mutaciones = pd.read_csv(emilia_metadata)

# mutaciones = pd.DataFrame(mutaciones)
# print(mutaciones.columns)

# vamos a juntar por sample
mutaciones = pd.DataFrame(mutaciones[['Sample_Name', 'origin_s', 'cyp51A_mutations', 'LineageCluster']])
metadata = pd.DataFrame(metadata)
df_final=pd.merge(metadata,mutaciones, on='Sample_Name', how='left', indicator=True)
print(df_final)

# Guardar archivo
df_final.to_csv("merged_metadata_updated.csv", index=False)


# Muestras de mutaciones que NO están en metadata
not_added = mutaciones[
    ~mutaciones['Sample_Name'].isin(metadata['Sample_Name'])
]

print(not_added)
print(f"Número de muestras no añadidas: {len(not_added)}")

# Guardarlas en archivo
not_added.to_csv("samples_from_mutaciones_not_in_metadata.csv", index=False)
