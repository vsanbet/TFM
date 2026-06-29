# Análisis filogenómico y de la estructura poblacional de Aspergillus fumigatus en ambientes hospitalarios españoles
Scripts utilizados para el análisis de 403 muestras de *A. fumigatus* (150 internacionales y 253 de colaboradores). Esta pipeline incluye pasos de procesamiento de las muestras general, estudio filogenómico y de la esctura poblacional de las muestras.

## Estructura del repositorio
```
pipeline
├── general_pipeline/
  │   ├── mapping/
  │   ├── post_filtering/
  │   ├── qc_mapping/
  │   ├── qc_vc/
  │   ├── quality_control/
  │   ├── trimming/
  │   ├── v_calling_aspergillus/
├── metadata_processing/
├── phylogenomics/
└──  population_study/
```

## Pipeline
### General pipeline
Pasos previos a los análisis filogenómicos y de poblaciones.
#### 1. Control de calidad
- **FastQC** — control de calidad inicial (403 muestras)
- **Trimming** — recorte de lecturas y filtrado. 28 muestras descartadas por baja calidad
- **FastQC + MultiQC** — control de calidad post-trimming (375 muestras)

#### 2. Mapeo
- **BWA + samtools** — mapeo al genoma de referencia
- **Qualimap** — revisión manual de la calidad del mapeo

#### 3. Variant Calling
- **BaseRecalibrator** — recalibración de base quality scores
- **ApplyBQSR** → `.recal.bam`
- **HaplotypeCaller** `--sample-ploidy 1` → `.g.vcf.gz` (375 muestras)
- **CombineGVCFs** → 1 cohort file (823,208 SNPs)
- **GenotypeGVCFs** → 768,232 SNPs
- **SelectVariants** `--select-type-to-include SNP` → 754,518 SNPs
- **VariantFiltration** (QUAL, QD, FS, MQ, MQRankSum, ReadPosRankSum, SOR) → 704,188 SNPs
- **Control de calidad** — control de calidad de variant calling, qc.sh 

#### 4. Filtrado de variantes
- **Custom script** `dp_missingness.sh` (DP 5-95%, missing < 25%, max-missing 0.9) → 483,892 SNPs, 358 muestras
- **Plink** MAF 0.05 → **45,034 SNPs** (final filtered)
- **Plink** LD pruning `--indep-pairwise 0.5 kb 1 0.1` → 249,278 SNPs

![Imagen de la primera parte de la pipeline](vsanbet/TFM/pipeline_images/pipeline_esquema_1.png)

### Metadata processing
Scripts para el procesamiento de metadatos y creación de un nuevo fichero de metadata.

### Phylogenomics
Scripts para el estudio filogenómico de las muestras y del gen *Cyp51A*
- **Vcf2phylip** + **IQ-TREE** (`-m AUTO`, `-bb 1000`, outgroup: *A. oerlinghausenesis*)
- **Splitstree** — network
- **FastANI** + **Spades** — ANI analysis (6 FASTA files)
- Visualización con **ggtree** (R)
- **BCFtools** — extracción del locus cyp51A
- **Biopython** — traducción de CDS
- **MAFFT** — alineamiento
- **IQ-TREE** — filogenia del gen
- Visualización con **ggtree** y **g3viz** (R)

![Imagen de la segunda parte de la pipeline](vsanbet/TFM/pipeline_images/pipeline_esquema_2.png)

### Population structure
- **Plink PCA**
- **Admixture** K=1-10, 10 runs/K
- **CLUMPAK** K=5
- Visualización con **R** (ggtree, custom scripts)

![Imagen de la tercera parte de la pipeline](vsanbet/TFM/pipeline_images/pipeline_esquema_3.png)


