import matplotlib.pyplot as plt
import pandas as pd

ruta = "/mnt/c/Users/Valeria/Desktop/Afum_metadata.ods"
metadata = pd.read_excel(ruta, sheet_name='final_metadata', engine='odf')

mutaciones = metadata[['Sample_Name', 'aa_mutations']]

fichero = '/mnt/c/Users/Valeria/Desktop/resultados_tfm/mutaciones_reducidas.tsv'

with open(fichero, 'w') as f:
    f.write('Sample_Name\tMutation_group\n')

    for _, row in mutaciones.iterrows():
        sample = row['Sample_Name']
        mutacion = str(row['aa_mutations']).strip()

        if mutacion.startswith('L98H'):
            grupo = 'TR'

        elif mutacion == 'F46Y, M172V, N248T, D255E, E427K':
            grupo = '5 SNPs'

        elif mutacion == 'F46Y, M172V, E427K':
            grupo = '3 SNPs'

        elif mutacion == 'WT':
            grupo = 'WT'

        elif mutacion in ['-', 'nan']:
            grupo = '-'

        else:
            grupo = 'puntual'

        f.write(f'{sample}\t{grupo}\n')

print('Archivo guardado correctamente')