from Bio import AlignIO
import pandas as pd

aln = AlignIO.read("/mnt/c/Users/Valeria/Desktop/resultados_tfm/Ficheros/cyp51a/Afu4g06890_aa_alineado.fasta", "fasta")

ref = aln[0]

mutaciones_por_muestra = {}

with open("mutaciones_por_muestra.txt", "w") as out:
    for record in aln[1:]:
        muts = []
        for i, (r, a) in enumerate(zip(ref.seq, record.seq)):
            if r != a and r != '-' and a != '-':
                muts.append(f"{r}{i+1}{a}")
        
        mutaciones_por_muestra[record.id] = muts
        
        linea = f"{record.id}: {', '.join(muts) if muts else 'sin mutaciones'}"
        print(linea)
        out.write(linea + "\n")

# Crear DataFrame con las mutaciones
muts_df = pd.DataFrame([
    {'BioinfoName': sample_id,
     'aa_mutations': ', '.join(muts) if muts else 'sin mutaciones'}
    for sample_id, muts in mutaciones_por_muestra.items()
])

# Merge con el metadata
ruta = '/mnt/c/Users/Valeria/Desktop/Afum_metadata.ods'
metadata = pd.read_excel(ruta, sheet_name='final_metadata', engine='odf')
metadata = metadata[['BioinfoName', 'aa_mutations']]
metadata['BioinfoName'] = metadata['BioinfoName'].str.replace('/', '-')

metadata = metadata.merge(muts_df, on='BioinfoName', how='left', suffixes=('_old', ''))
metadata = metadata.drop(columns=['aa_mutations_old'])

print(metadata)
metadata.to_csv("metadata_con_mutaciones.csv", index=False)