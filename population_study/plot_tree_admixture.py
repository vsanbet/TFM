"""
plot_tree_admixture.py

Genera una figura combinada de:
  - Arbol filogenetico (newick, con branch lengths)
  - Columna de puntos coloreada por un cluster de metadata (ej. "Our Cluster")
  - Barras de ADMIXTURE (promedio de N runs alineados estilo CLUMPP) para un K dado

Requisitos (instalar con pip):
    pip install biopython numpy pandas scipy matplotlib odfpy --break-system-packages

Archivos de entrada esperados:
  - tree.nwk                  -> arbol en formato newick (con un tip llamado "Outgroup" si aplica)
  - maf_filter.fam             -> archivo .fam de PLINK usado como input de ADMIXTURE
                                   (columna 2 = IDs de muestra, formato "ID_ID")
  - maf_filter_K5_run{1..N}.Q  -> matrices Q de ADMIXTURE para cada run independiente, mismo K
  - Afum_metadata.ods           -> metadata con hoja "final_metadata", columnas
                                   "Sample_Name", "BioinfoName" y "Our Cluster"

Salida:
  - tree_admixture_K5.png
  - tree_admixture_K5.pdf

Uso:
    python3 plot_tree_admixture.py
(ajusta las variables de configuracion en la seccion CONFIG de mas abajo)
"""

import pickle
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from Bio import Phylo
from scipy.optimize import linear_sum_assignment

# ============================== CONFIG ==============================
TREE_FILE = "tree.nwk"
FAM_FILE = "maf_filter.fam"
Q_FILE_PATTERN = "maf_filter_K5_run{i}.Q"   # {i} = 1..N_RUNS
N_RUNS = 10
K = 5
META_FILE = "Afum_metadata.ods"
META_SHEET = "final_metadata"
META_CLUSTER_COL = "Our Cluster"            # columna de metadata a usar como color de los puntos
OUTGROUP_NAME = "Outgroup"                  # nombre del tip a usar como raiz (None si no hay)
OUT_PREFIX = "tree_admixture_K5"
# ======================================================================


def load_fam_ids(fam_file):
    """Lee el .fam de PLINK y devuelve la lista de IDs en orden (mismo orden que las filas del .Q)."""
    ids = []
    with open(fam_file) as f:
        for line in f:
            parts = line.split()
            sample_id = parts[1].split("_")[0]  # PLINK suele duplicar el ID como FID_IID
            ids.append(sample_id)
    return ids


def align_admixture_runs(q_pattern, n_runs, k):
    """
    Alinea N runs independientes de ADMIXTURE (mismo K, pero columnas en orden arbitrario)
    usando el algoritmo hungaro (equivalente a lo que hace CLUMPP) tomando el primer run
    como referencia, y devuelve el promedio normalizado por fila.
    """
    runs = [np.loadtxt(q_pattern.format(i=i)) for i in range(1, n_runs + 1)]

    ref = runs[0]
    aligned = [ref]
    for Q in runs[1:]:
        cost = np.zeros((k, k))
        for a in range(k):
            for b in range(k):
                cost[a, b] = np.sum(np.abs(ref[:, a] - Q[:, b]))
        row_ind, col_ind = linear_sum_assignment(cost)
        aligned.append(Q[:, col_ind])

    avg = np.mean(aligned, axis=0)
    avg = avg / avg.sum(axis=1, keepdims=True)
    return avg


def load_metadata_cluster(meta_file, sheet, cluster_col, sample_ids):
    """
    Carga el metadata y devuelve un dict {sample_id: valor_cluster}, buscando primero por
    'Sample_Name' y si no se encuentra, por 'BioinfoName'.
    """
    meta = pd.read_excel(meta_file, sheet_name=sheet, engine="odf")
    by_sample_name = meta.set_index(meta["Sample_Name"].astype(str))
    by_bioinfo_name = meta.set_index(meta["BioinfoName"].astype(str))

    result = {}
    for sid in sample_ids:
        if sid in by_sample_name.index:
            v = by_sample_name.loc[sid, cluster_col]
        elif sid in by_bioinfo_name.index:
            v = by_bioinfo_name.loc[sid, cluster_col]
        else:
            v = None
        if isinstance(v, pd.Series):  # por si hay IDs duplicados en el metadata
            v = v.iloc[0]
        result[sid] = v
    return result


def build_tree(tree_file, outgroup=None):
    tree = Phylo.read(tree_file, "newick")
    if outgroup is not None:
        tree.root_with_outgroup(outgroup)
    tree.ladderize()
    return tree


def assign_coordinates(tree, y_pos):
    """Calcula coordenadas x (longitud acumulada de rama) e y (orden de los tips) para cada clado."""

    def assign_x(clade, x=0.0):
        clade.__dict__["_x"] = x
        for c in clade.clades:
            bl = c.branch_length if c.branch_length is not None else 0.0
            assign_x(c, x + bl)

    def assign_y(clade):
        if clade.is_terminal():
            clade.__dict__["_y"] = y_pos[clade.name]
            return clade._y
        ys = [assign_y(c) for c in clade.clades]
        clade.__dict__["_y"] = sum(ys) / len(ys)
        return clade._y

    assign_x(tree.root, 0.0)
    assign_y(tree.root)


def draw_tree(ax, clade):
    """Dibuja recursivamente las ramas del arbol (estilo cladograma rectangular) sobre ax."""
    x0, y0 = clade._x, clade._y
    for c in clade.clades:
        x1, y1 = c._x, c._y
        ax.plot([x0, x1], [y1, y1], color="black", lw=0.4)
        draw_tree(ax, c)
    if not clade.is_terminal():
        ys = [c._y for c in clade.clades]
        ax.plot([x0, x0], [min(ys), max(ys)], color="black", lw=0.4)


def main():
    # --- 1. arbol ---
    tree = build_tree(TREE_FILE, outgroup=OUTGROUP_NAME)
    tips_in_order = [t.name for t in tree.get_terminals()]
    n = len(tips_in_order)
    y_pos = {name: n - i for i, name in enumerate(tips_in_order)}
    assign_coordinates(tree, y_pos)

    # --- 2. admixture: alinear y promediar los N runs ---
    fam_ids = load_fam_ids(FAM_FILE)
    avg_Q = align_admixture_runs(Q_FILE_PATTERN, N_RUNS, K)
    Q_df = pd.DataFrame(avg_Q, index=fam_ids, columns=[f"Cluster{i+1}" for i in range(K)])

    # --- 3. metadata para colorear los tips ---
    cluster_map = load_metadata_cluster(META_FILE, META_SHEET, META_CLUSTER_COL, fam_ids)
    if OUTGROUP_NAME:
        cluster_map[OUTGROUP_NAME] = None

    clusters_present = sorted(v for v in set(cluster_map.values()) if pd.notna(v))

    # --- 3b. reordenar columnas del Q-matrix para que el indice de cada cluster de
    #          ADMIXTURE coincida con el numero de "Our Cluster" mayoritario, de forma
    #          que un mismo color signifique siempre el mismo grupo en toda la figura ---
    our_cluster_ids = sorted(int(float(c)) for c in clusters_present)
    dominant = Q_df.values.argmax(axis=1)  # columna dominante (0..K-1) por muestra
    overlap = np.zeros((K, len(our_cluster_ids)))
    for row_i, fid in enumerate(fam_ids):
        oc = cluster_map.get(fid)
        if pd.notna(oc):
            j = our_cluster_ids.index(int(float(oc)))
            overlap[dominant[row_i], j] += 1
    # asignacion optima (maximizar solapamiento) admixture_col -> our_cluster_id
    row_ind, col_ind = linear_sum_assignment(-overlap)
    col_to_ourcluster = {r: our_cluster_ids[c] for r, c in zip(row_ind, col_ind)}
    # columnas de Q sin pareja (si K > num clusters de metadata) se numeran al final
    used = set(col_to_ourcluster.values())
    free_ids = [oc for oc in our_cluster_ids if oc not in used] or list(range(1, K + 1))
    new_order = []
    for col in range(K):
        new_order.append(col_to_ourcluster.get(col))
    # reordenar Q_df: la columna final i-esima (0-indexed) debe representar al cluster (i+1)
    target_order = sorted(range(K), key=lambda col: (col_to_ourcluster.get(col, 999)))
    Q_df = Q_df.iloc[:, target_order]
    Q_df.columns = [f"Cluster{i+1}" for i in range(K)]

    # Paleta fija extraida de la leyenda de referencia ("Our Cluster": 1-5 + NA)
    FIXED_CLUSTER_COLORS = {
        1: "#DF0D22",  # rojo
        2: "#3E7FB7",  # azul
        3: "#54AF4E",  # verde
        4: "#964FA2",  # morado
        5: "#FB7C1A",  # naranja
    }
    NA_COLOR = "#BEBEBE"  # gris (NA)
    bar_colors = [FIXED_CLUSTER_COLORS[i + 1] for i in range(K)]
    cluster_colors = {}
    for c in clusters_present:
        key = int(float(c)) if float(c).is_integer() else c
        cluster_colors[c] = FIXED_CLUSTER_COLORS.get(key, NA_COLOR)
    
    # --- 4. layout de la figura ---
    fig_h = max(10, n * 0.045)
    fig = plt.figure(figsize=(14, fig_h))
    gs = fig.add_gridspec(1, 3, width_ratios=[3.2, 0.18, 1.6], wspace=0.02)
    ax_tree = fig.add_subplot(gs[0, 0])
    ax_dot = fig.add_subplot(gs[0, 1], sharey=ax_tree)
    ax_bar = fig.add_subplot(gs[0, 2], sharey=ax_tree)

    # arbol
    draw_tree(ax_tree, tree.root)
    ax_tree.set_yticks([])
    ax_tree.set_xlabel("Branch length")
    for spine in ["top", "right", "left"]:
        ax_tree.spines[spine].set_visible(False)
    ax_tree.set_ylim(0.5, n + 0.5)

    # puntos de metadata
    for name in tips_in_order:
        y = y_pos[name]
        c = cluster_map.get(name)
        color = cluster_colors[c] if pd.notna(c) else NA_COLOR
        size = 10 if pd.notna(c) else 8
        ax_dot.scatter([0], [y], color=color, s=size, zorder=3)
    ax_dot.set_xlim(-1, 1)
    ax_dot.axis("off")

    # barras de admixture
    for name in tips_in_order:
        y = y_pos[name]
        if name in Q_df.index:
            vals = Q_df.loc[name].values
            left = 0
            for k_idx in range(K):
                ax_bar.barh(y, vals[k_idx], left=left, height=1.0,
                            color=bar_colors[k_idx], edgecolor="none")
                left += vals[k_idx]
        else:
            ax_bar.barh(y, 1, left=0, height=1.0, color="white", edgecolor="none")
    ax_bar.set_xlim(0, 1)
    ax_bar.set_ylim(0.5, n + 0.5)
    ax_bar.set_yticks([])
    ax_bar.set_xlabel(f"Admixture (K={K})")
    for spine in ["top", "right", "left"]:
        ax_bar.spines[spine].set_visible(False)

    # leyenda unica (mismos colores para puntos y barras)
    cluster_legend = [
        Line2D([0], [0], marker="s", color="w", markerfacecolor=cluster_colors[c],
               markersize=9, label=f"{int(float(c)) if float(c).is_integer() else c}")
        for c in clusters_present
    ]
    cluster_legend.append(
        Line2D([0], [0], marker="s", color="w", markerfacecolor=NA_COLOR,
               markersize=9, label="NA")
    )

    ax_bar.legend(cluster_legend, [l.get_label() for l in cluster_legend],
                  loc="upper left", bbox_to_anchor=(1.02, 1),
                  title="Clusters", fontsize=8, title_fontsize=9, frameon=False)

    fig.suptitle(f"K = {K}  (ADMIXTURE, {N_RUNS} runs averaged) + ML tree", y=0.995, fontsize=12)

    plt.savefig(f"{OUT_PREFIX}.png", dpi=200, bbox_inches="tight")
    plt.savefig(f"{OUT_PREFIX}.pdf", bbox_inches="tight")
    plt.savefig(f"{OUT_PREFIX}.svg", bbox_inches="tight")
    print(f"OK -> {OUT_PREFIX}.png / {OUT_PREFIX}.pdf / {OUT_PREFIX}.svg")


if __name__ == "__main__":
    main()
