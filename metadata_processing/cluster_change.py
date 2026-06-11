import pandas as pd

pd.set_option('future.no_silent_downcasting', True)

ruta = '/mnt/c/Users/Valeria/Desktop/Afum_metadata.ods'

# Leer solo final_metadata
df = pd.read_excel(ruta, sheet_name='final_metadata', engine='odf')

cluster_map = {
    1.0: 5.0,
    2.0: 4.0,
    3.0: 1.0,
    4.0: 2.0,
    5.0: 3.0
}

df['New Cluster'] = df['Our Cluster 5'].replace(cluster_map)

df.to_csv('/mnt/c/Users/Valeria/Desktop/Afum_metadata_new_cluster.csv', index=False)