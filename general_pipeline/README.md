# general_pipeline

Pipeline bioinformático general del TFM: procesa lecturas Illumina paired-end (WGS) desde los FASTQ crudos hasta un VCF de variantes filtrado, listo para los análisis poblacionales (carpeta `population_study`). Está pensado para ejecutarse en clusters HPC con gestor **SLURM** (scripts probados en SAGA, cuenta `nn8029k`; algunos módulos tienen también una versión para CESGA) y usa `sbatch`/dependencias (`--dependency=afterok`) para encadenar pasos.

El flujo de trabajo, en orden, es:

```
quality_control  →  trimming  →  mapping  →  qc_mapping  →  v_calling_aspergillus  →  qc_vc  →  post_filtering
                                                                                  ↳  map_vcal_outgroup.sh (muestra outgroup)
```

## Requisitos

Software cargado vía `module load` en el cluster (o disponible en el `PATH`):

- FastQC, MultiQC
- Trimmomatic 0.39
- BWA 0.7.18, SAMtools 1.18+
- GATK 4.5.0.0, Picard 3.0.0
- Qualimap 2.3
- BCFtools, VCFtools, tabix
- Python 3 (`pandas`, `numpy`, `cyvcf2`) — entorno conda `vcf_env`
- R (`ggplot2`, `data.table`, `gridExtra`)

> Varios scripts contienen rutas absolutas del cluster (`/cluster/projects/nn8029k/...`) y cuentas SLURM (`--account=nn8029k`) específicas del proyecto. Hay que adaptarlas antes de reutilizar el pipeline en otro entorno.

---

## 1. `quality_control/`

Control de calidad de las lecturas crudas.

| Script | Función |
|---|---|
| `fastqc.sh` | Lanza FastQC sobre un par de FASTQ (R1/R2), indicado por `SLURM_ARRAY_TASK_ID` a partir de un TSV de muestras. |
| `multiqc.sh` | Agrega todos los informes FastQC en un único reporte MultiQC. |
| `wrapper_final.sh` | Orquesta todo: lanza `fastqc.sh` como *array job* (una tarea por muestra) y, cuando termina (`afterok`), lanza `multiqc.sh`. |

```bash
sbatch quality_control/wrapper_final.sh \
  --samples samples_fastq.tsv \
  --fastqc-dir fastqc_raw \
  --multiqc-dir multiqc \
  --full-results-path /ruta/de/salida
```

El TSV de muestras tiene formato `sample<TAB>read1<TAB>read2` (sin cabecera, una línea por muestra).

---

## 2. `trimming/`

Recorte y filtrado de calidad de las lecturas con Trimmomatic (modo *paired-end*). Hay tres variantes del script de array, según la estrategia de recorte usada durante las pruebas del TFM:

| Script | Estrategia |
|---|---|
| `trimmomatic_array.sh` | `HEADCROP:15` (elimina las 15 primeras bases). |
| `trimmomatic_array_illuminaclip.sh` | `ILLUMINACLIP:TruSeq3-PE.fa:2:30:10` + `HEADCROP:15` + `CROP:200` + `TRAILING:25` + `MINLEN:45` (versión final, con adaptadores TruSeq3, `TruSeq3-PE.fa` incluido). |
| `trimmomatic_array_no_crop.sh` | Sin recorte de longitud, solo `MINLEN:2` (control). |
| `trim15bp.sh` | Versión no-array (bucle secuencial) equivalente a `HEADCROP:15`, para pruebas puntuales. |

Lanzadores (*wrappers*), que calculan el rango del array a partir del TSV y llaman a `sbatch`:

```bash
bash trimming/run_trimmomatic.sh samples.tsv outdir/          # usa trimmomatic_array_illuminaclip.sh
bash trimming/run_trimmomatic_no_crop.sh samples.tsv outdir/  # usa trimmomatic_array_no_crop.sh
```

`samples.tsv`: `sample<TAB>read1<TAB>read2`, con cabecera (el array empieza en la línea 2).

Salida por muestra: `SAMPLE_R1_paired.fastq.gz` y `SAMPLE_R2_paired.fastq.gz` (las lecturas *unpaired* se descartan a `/dev/null`).

---

## 3. `mapping/`

Alineamiento contra el genoma de referencia con BWA-MEM y generación de BAMs ordenados e indexados.

| Script | Función |
|---|---|
| `module.sh` | Carga los módulos necesarios (BWA, SAMtools). |
| `index_reference.sh` | Indexa la referencia (`bwa index` + `samtools faidx`), reconstruyendo el índice desde cero. |
| `map_array.sh` | *Array job*: mapea una muestra (BWA-MEM con `@RG`), filtra por `MIN_MAPQ` (por defecto 20) y produce un BAM ordenado e indexado. |
| `run_mapping.sh` | Wrapper: lanza primero `index_reference.sh` y, con dependencia `afterok`, lanza `map_array.sh` como array sobre todas las muestras. |
| `unite_mapping.sh` | Fusiona (`samtools merge`) los BAMs de muestras que comparten `BIOSAMPLE` (p. ej. varias corridas/accesiones del mismo individuo) y verifica el resultado con `samtools quickcheck` + `flagstat`. |

```bash
bash mapping/run_mapping.sh \
  --samples samples.tsv \
  --reference referencia.fasta \
  --outdir resultados_mapeo/ \
  --min-mapq 30
```

`samples.tsv` (sin cabecera): `sample<TAB>read1<TAB>read2` (`read2` puede ser `-` para *single-end*).

Para fusionar réplicas del mismo `BIOSAMPLE`:

```bash
sbatch mapping/unite_mapping.sh samples_con_biosample.tsv resultados_mapeo/ resultados_mapeo_fusionado/
```

(TSV con columnas `sample_name`, `bioinfoname`, `biosample`, `accession`).

---

## 4. `qc_mapping/`

Control de calidad de los BAMs mapeados con Qualimap.

| Script | Función |
|---|---|
| `qc_array.sh` | *Array job*: ejecuta `qualimap bamqc` sobre el BAM de cada muestra. |
| `qc_multi.sh` | Genera el TSV de rutas de los QC individuales y ejecuta `qualimap multi-bamqc` para el informe conjunto. |
| `qc_wrapper.sh` | Lanza `qc_array.sh` (array de 1 a N muestras) y, con dependencia `afterok`, `qc_multi.sh`. |

```bash
sbatch qc_mapping/qc_wrapper.sh input_bams.tsv salida_individual/ salida_global/
```

`input_bams.tsv`: `sample<espacio>ruta_bam` (una línea por muestra).

---

## 5. `v_calling_aspergillus/`

Llamada de variantes con GATK, específica para *Aspergillus fumigatus* (organismo **haploide**, `--sample-ploidy 1`). `wrapper.sh` encadena todos los pasos mediante dependencias SLURM:

| Paso | Script | Función |
|---|---|---|
| 0 | `index_reference.sh` | Indexa la referencia (`samtools faidx` + `gatk CreateSequenceDictionary`). |
| 1 | `01_base_recalibrator.sh` | BQSR: `gatk BaseRecalibrator` + `ApplyBQSR` usando sitios conocidos de FungiDB. |
| 2 | `02_hapcaller.sh` | `gatk HaplotypeCaller` en modo GVCF (`-ERC GVCF`, ploidía 1) por muestra. |
| 3 | `03_genotypegvcf.sh` | `CombineGVCFs` + `GenotypeGVCFs` → VCF conjunto de la cohorte (`cohort.vcf.gz`). |
| 4 | `04_selectvariants.sh` | `SelectVariants` para quedarse solo con SNPs. |
| 5 | `05_filtervariants.sh` | `VariantFiltration` con filtros *hard* adaptados a haploides (`QUAL<30`, `QD<2`, `FS>60`, `MQ<40`, `MQRankSum<-12.5`, `ReadPosRankSum<-8`, `SOR>3`) y selección de variantes `PASS`. |

`module.sh` carga GATK, BWA y SAMtools. Todos los pasos son reanudables: si el fichero de salida ya existe, el paso se salta.

```bash
bash v_calling_aspergillus/wrapper.sh \
  --samples samples_bam.tsv \
  --reference referencia.fasta \
  --workdir resultados_vc/
```

`samples_bam.tsv` (con cabecera): `sample<TAB>bam`.

Salida final: `WORKDIR/bsr_dir/filtered/cohort_snps_pass.filtered.vcf.gz`.

---

## 6. `qc_vc/`

Control de calidad de las variantes llamadas: extrae, por muestra, las métricas de calidad de las posiciones donde esa muestra es no-referencia (SNPs) y genera un PDF (una página por muestra) con histogramas de `QUAL`, `DP`, `QD`, `MQ`, `FS`, `SOR`, `MQRankSum`, `ReadPosRankSum` y el recuento de `FILTER`.

```bash
bash qc_vc/qc.sh cohorte.vcf.gz [outdir=qc_site_metrics] [pdfname=site_metrics_by_sample.pdf]
```

Requiere `bcftools`, `tabix` y `Rscript` (con `data.table`, `ggplot2`, `gridExtra`) en el `PATH`.

---

## 7. `post_filtering/`

Filtrado final del VCF por profundidad (DP) y *missingness*, y análisis de desequilibrio de ligamiento (LD).

| Script | Función |
|---|---|
| `module.sh` | Carga BCFtools. |
| `final_filtering.sh` | Versión SLURM: calcula percentiles 5/95 de DP global, filtra por `FORMAT/DP`, elimina individuos con >25 % de *missing* y luego posiciones con >10 % de *missing*. |
| `dp_missingess.sh` | Versión más completa (no-SLURM, ejecutable directamente): calcula percentiles de DP **por muestra** (no globales) con un script Python (`pandas`/`cyvcf2`), pone a *missing* los genotipos fuera de rango, filtra individuos y posiciones por *missingness*, y genera un informe de texto (`filtering_report.txt`) con el recuento de SNPs/individuos en cada paso. |
| `ld_plot.R` | Grafica la curva de decaimiento del LD (`Mean r²` vs distancia en kb) a partir de un CSV de salida de un análisis de LD (p. ej. PLINK). |

```bash
# Filtrado DP + missingness (recomendado, umbrales por muestra)
bash post_filtering/dp_missingess.sh cohort_snps_pass.filtered.vcf.gz workdir/

# Alternativa como job SLURM (umbral de DP global)
sbatch post_filtering/final_filtering.sh cohort_snps_pass.filtered.vcf.gz workdir/
```

Salida final: `workdir/missingness/final_filtered.vcf.gz` (este VCF es el que alimenta los análisis de `population_study`).

---

## `map_vcal_outgroup.sh`

Script independiente para procesar la muestra *outgroup* (SRA `SRR11363406`) contra la misma referencia: mapeo con BWA-MEM, generación de BAM ordenado y llamada de variantes con `gatk HaplotypeCaller` (diploide, sin `-ERC GVCF`). Se usa para incorporar el outgroup a los análisis filogenéticos/poblacionales.

```bash
sbatch map_vcal_outgroup.sh
```

(Rutas de referencia, FASTQ y salida están fijadas dentro del script; hay que editarlas si cambia la ubicación de los datos.)
readme de esta parte :)
