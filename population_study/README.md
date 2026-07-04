# population_study

Scripts para el estudio de la estructura poblacional de las muestras de *Aspergillus fumigatus* a partir del VCF final filtrado (`final_filtered.vcf.gz`, salida de `general_pipeline/post_filtering/`). Incluye análisis de componentes principales (PCA), inferencia de ancestría con ADMIXTURE y visualización conjunta con el árbol filogenómico (`phylogenomics/`).

Flujo de trabajo:

\```
                    ┌─→ plink_pca.R ───────────────────────────────┐
VCF filtrado (Plink)┤                                              ├─→ figuras finales
                    └─→ run_admixture.sh (K=1-10, 10 runs) ─→ cv_graph.R (elegir K)
                                                            └─→ CLUMPAK (externo) ─→ clustering.R
                                                                                  └─→ plot_tree_admixture.py
\```

## Requisitos
- PLINK (generación de `.bed/.bim/.fam`, PCA y ficheros `maf_filter*`)
- ADMIXTURE 1.3.0
- [CLUMPAK](https://clumpak.tau.ac.il/) (alineado de runs de ADMIXTURE y `ClumppIndFile.output`), solo necesario para `clustering.R`
- R (`ggplot2`, `dplyr`, `tidyr`, `readODS`, `ggtext`, `plotly`)
- Python 3 (`biopython`, `numpy`, `pandas`, `scipy`, `matplotlib`, `odfpy`)

\```bash
pip install biopython numpy pandas scipy matplotlib odfpy --break-system-packages
\```

---

## 1. `run_admixture.sh`

*Array job* de SLURM que ejecuta ADMIXTURE sobre un fichero PLINK (`.bed`) para **K=1 a 10, con 10 réplicas independientes por K** (100 tareas en total, `--array=1-100`), cada una con una semilla distinta y validación cruzada (`--cv=10`).

- El índice de la tarea del array se traduce a `(K, run)`: tareas 1–10 → K=1 (runs 1–10), 11–20 → K=2, etc.
- Cada combinación K/run se ejecuta en su propio directorio (`OUTDIR/K{K}/run{RUN}`) y los ficheros de salida (`.Q`, `.P`) se renombran incluyendo K y run.
- El error de validación cruzada de cada run se extrae del log y se acumula en `OUTDIR/cv_errors.txt` (columnas `K`, `run`, `seed`, `CV`).

\```bash
sbatch run_admixture.sh
\```


---

## 2. `cv_graph.R`

Grafica el error de validación cruzada (CV) de ADMIXTURE frente a K para elegir el número óptimo de clusters ancestrales.

- Parte de un data frame `doc` con columnas `K` y `CV` (una fila por run; se puede construir leyendo `cv_errors.txt` generado por `run_admixture.sh`).
- Calcula la media de CV por K y la pendiente entre K consecutivos (a menor pendiente, menor beneficio de aumentar K).
- Dibuja los runs individuales (`geom_jitter`), la media por K (línea + puntos) y etiqueta cada tramo con la pendiente.

---

## 3. `clustering.R`

Genera el barplot de ancestría (estilo STRUCTURE/ADMIXTURE) para un K dado (por defecto K=5), a partir de la salida ya alineada por **CLUMPAK** (`ClumppIndFile.output`).

Pasos principales:
1. Carga `ClumppIndFile.output` (probabilidad de pertenencia a cada cluster) y la lista de muestras en el mismo orden usado en ADMIXTURE.
2. Cruza los IDs bioinformáticos con la metadata (`Afum_metadata.ods`) para obtener nombres de muestra legibles, distinguiendo muestras con varias lecturas (`Sample_Name_BioinfoName`).
3. Asigna a cada muestra su cluster dominante (máxima probabilidad) y ordena el eje X por cluster y pureza.
4. Dibuja el barplot apilado (`ggplot2`, una barra por individuo) y resalta en rojo las muestras españolas de la cohorte del TFM.
5. Exporta el gráfico a SVG y PDF.

---

## 4. `plink_pca.R`

Visualiza el PCA generado por PLINK (`pca_maf.eigenvec` / `.eigenval`) coloreado por cluster de ancestría, cruzando los resultados con la metadata (`Afum_metadata.ods`, columna `Our Cluster`). Incluye dos bloques equivalentes (K=6 y K=5, con paletas de color ligeramente distintas):

- **PCA 3D interactivo** (PC1–PC3) con `plotly`, con tooltip por muestra (cluster, país de origen, sensibilidad a azoles).
- **PCA 2D** para las tres combinaciones de componentes (PC1–PC2, PC1–PC3, PC2–PC3) con `ggplot2`, exportado a PNG y PDF.

---

## 5. `plot_tree_admixture.py`

Combina en una sola figura el árbol filogenómico (de `phylogenomics/`) con las barras de ADMIXTURE para un K dado, coloreando además cada punta del árbol según el cluster asignado en la metadata (`Our Cluster`). A diferencia de `clustering.R`, no depende de CLUMPAK: alinea los runs de ADMIXTURE él mismo.

Archivos de entrada esperados (en el directorio de trabajo):

| Fichero | Contenido |
|---|---|
| `tree.nwk` | Árbol en formato Newick, con un tip `Outgroup` opcional para enraizar |
| `maf_filter.fam` | `.fam` de PLINK usado como input de ADMIXTURE (define el orden de muestras de los `.Q`) |
| `maf_filter_K5_run{1..N}.Q` | Matrices Q de ADMIXTURE de cada run independiente, mismo K |
| `Afum_metadata.ods` | Metadata, hoja `final_metadata`, columnas `Sample_Name`, `BioinfoName`, `Our Cluster` |

Qué hace `main()`:
1. **Árbol** — lee el Newick, lo enraíza con el outgroup si se indica, lo laderiza y calcula coordenadas x/y de cada rama y punta.
2. **ADMIXTURE** — carga los `N_RUNS` ficheros `.Q` y los alinea entre sí con el algoritmo húngaro (`scipy.optimize.linear_sum_assignment`), equivalente a lo que hace CLUMPAK, y promedia las proporciones de ancestría por muestra.
3. **Metadata** — asigna a cada muestra su `Our Cluster`, buscando primero por `Sample_Name` y si no por `BioinfoName`.
4. **Reordenación de colores** — reasigna las columnas del Q-matrix (que ADMIXTURE numera de forma arbitraria) al número de `Our Cluster` con mayor solapamiento, para que un mismo color represente siempre el mismo grupo genético en toda la figura.
5. **Figura** — dibuja tres paneles alineados por muestra: cladograma, columna de puntos coloreados por `Our Cluster` y barras apiladas de ancestría (K=5 por defecto), con leyenda común.

Configuración (constantes al inicio del script, sección `CONFIG`): `TREE_FILE`, `FAM_FILE`, `Q_FILE_PATTERN`, `N_RUNS`, `K`, `META_FILE`, `META_SHEET`, `META_CLUSTER_COL`, `OUTGROUP_NAME`, `OUT_PREFIX`.

\```bash
python3 plot_tree_admixture.py
\```

Salida: `tree_admixture_K5.png`, `tree_admixture_K5.pdf`, `tree_admixture_K5.svg`.
