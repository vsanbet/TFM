#!/bin/bash
REF=/mnt/c/Users/Valeria/Desktop/resultados_tfm/Ficheros/referencia/Aspfu1_AssemblyScaffolds_Repeatmasked.fasta
VCF=/mnt/c/Users/Valeria/Desktop/resultados_tfm/Ficheros/cyp51a/output_Afu4g06890_cds.vcf.gz
OUT=/mnt/c/Users/Valeria/Desktop/resultados_tfm/Ficheros/cyp51a/Afu4g06890_cds_all.fasta

rm -f $OUT

for SAMPLE in $(bcftools query -l $VCF); do
    for REGION in "Chr_4_A_fumigatus_Af293:1783713-1785059" "Chr_4_A_fumigatus_Af293:1785131-1785331"; do
        samtools faidx $REF $REGION | \
        bcftools consensus -s $SAMPLE $VCF | \
        sed "s/^>.*/>$SAMPLE\_$REGION/" \
        >> $OUT
    done
done
