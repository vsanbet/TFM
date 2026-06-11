# Contar los runs que han salido y luego ver cuales no están 

import csv
import pandas as pd

fichero = pd.read_csv('/home/bettini/data_ordenadir/muestras_internacionales/run_comprobacion.csv')

lista_nombres = fichero['runs']

nombres_filtrados = []

for nombre in lista_nombres:
    if '_1.fastq' in nombre:
        base = nombre.replace('_1.fastq', '')
        if base not in nombres_filtrados:
            nombres_filtrados.append(base)
    elif '_2.fastq' in nombre:
        base = nombre.replace('_2.fastq', '')
        if base not in nombres_filtrados:
            nombres_filtrados.append(base)


print(f'{len(nombres_filtrados)} -> número de muestras que se han descargado')

muestras_internacionales = pd.read_csv('/home/bettini/data_ordenadir/muestras_internacionales/sra_run_download.csv')

lista_internacionales = muestras_internacionales['Run (SRA)']

for nombre in lista_internacionales:
    nombre.strip()
    if nombre not in nombres_filtrados:
        print(nombre)


      



