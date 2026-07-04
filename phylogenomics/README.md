# phylogenomics

Scripts para el estudio filogenómico de la cohorte y del gen *cyp51A*: construcción del árbol de máxima verosimilitud, extracción y traducción del locus, visualización de mutaciones y comparación genómica por ANI.

## Requisitos
```bash
pip install biopython pandas --break-system-packages
```
R: `ggtree`, `ape`, `tidyverse`, `readODS`, `pheatmap`, `trackViewer`, `g3viz`, `Polychrome`, `colorBlindness`, `RColorBrewer`
Otros: IQ-TREE 2, BCFtools, SAMtools

## Scripts

| Script | Función |
|---|---|
| `iq_invariant_root.sh` | Lanza IQ-TREE (SLURM) sobre un alineamiento `.phy` con sitios invariantes corregidos (`-fconst`), modelo `TVM+F+R8`, 1000 bootstraps y outgroup fijo. |
| `fasta_cyp.sh` | Extrae la región del gen *cyp51A* del genoma de referencia y genera un FASTA con la secuencia consenso por muestra a partir del VCF. |
| `cyp_translarion_cds.py` | Une los CDS por muestra, obtiene la reversa complementaria (hebra -) y traduce a proteína, guardando un FASTA de proteínas. |
| `cyp_tree.R` | Construye el árbol circular de *cyp51A* (ggtree) con anexos de metadata: susceptibilidad a azoles, cluster de ADMIXTURE, grupo de mutación, etc. |
| `cyp_figure.R` | Genera un *lolliplot* de las mutaciones de Cyp51A sobre la estructura de la proteína (dominios de UniProt), coloreado por fenotipo de resistencia. |
| `heatmap_fastani.R` | Heatmap de identidad ANI (all-vs-all) entre genomas ensamblados, anotado por cluster. |
| `stacked_plot_cluster.py` | Barras apiladas de susceptibilidad a azoles (R/S/I) por cluster, país de origen y fuente de aislamiento, en porcentaje y en número absoluto. |
