import re
import pandas as pd
import os

df = pd.read_excel('Envios alejandro.xlsx')
matches = {}

# Guardar como archivo .tsv
current_dir = os.getcwd()
if 'envios_alejandro.tsv' not in os.listdir(current_dir):
    df.to_csv('envios_alejandro.tsv', sep='\t', index=False)
    matches = {}
else:
    df = pd.read_csv('envios_alejandro.tsv', sep='\t')

def extraer_substring(texto):
    # Buscar todo lo que esté entre el primer número/letra después de letras iniciales y antes de _ o -
    match = re.search(r'[a-zA-Z]+(\d+)', texto)
    if match:
        clave = match.group(1)
        if clave not in matches:
            matches[clave] = texto

# Por cada nombre en la columna de Sample_Name
for index, row in df.iterrows():
    name = row['Sample_Name']
    print (f'Buscando coindicencia para {name}')
    extraer_substring(name)


# Guardar en TSV
matches_df = pd.DataFrame(list(matches.items()), columns=['name', 'set_datos'])
matches_df.to_csv('emilia_names.tsv', sep='\t', index=False)
print('Archivo con coincidencias creado')