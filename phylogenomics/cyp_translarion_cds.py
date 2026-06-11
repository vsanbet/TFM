# 1. Unir CDS por muestras
fasta = '/mnt/c/Users/Valeria/Desktop/resultados_tfm/Ficheros/cyp51a/Afu4g06890_cds_all.fasta'

old_sample = None
sequences = {}
with open (fasta, 'r') as f:
    for linea in f:
       linea = linea.strip()
       if linea.startswith('>'):
           sample = linea.lstrip('>').split('_')
           current_sample = sample[0]
           
           # si no está, añadir
           if current_sample not in sequences:
               sequences[current_sample] = ''
            # si está, ignorar
           else:
               continue
        # añadir secuencia
       else:
           sequences[current_sample] += linea

# print(sequences)

# 2. Reversa complementaria (secuencia se encuentra en hebra -)
from Bio.Seq import Seq

reversed_samples = {}

for sample, seq in sequences.items():
    reversed_samples[sample] = Seq(seq).reverse_complement()

# print(reversed_samples)

# 3. Traducción a proteínas 
proteinas = {}
for sample, seq in reversed_samples.items():
    proteinas[sample] = seq.translate(to_stop=True)

# print(proteinas)
# print(len(proteinas.keys()))

# 4. Guardar proteínas en FASTA
output = '/mnt/c/Users/Valeria/Desktop/resultados_tfm/Ficheros/cyp51a/Afu4g06890_proteinas.fasta'

with open(output, 'w') as f:
    for sample, proteina in proteinas.items():
        f.write(f'>{sample}\n{proteina}\n')

print(f'Guardado en: {output}')
print(f'Total secuencias: {len(proteinas)}')