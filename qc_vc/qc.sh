#!/usr/bin/env bash
set -euo pipefail

VCF="${1:-}"
OUTDIR="${2:-qc_site_metrics}"
PDFNAME="${3:-site_metrics_by_sample.pdf}"

if [[ -z "${VCF}" ]]; then
  echo "Usage: bash $0 input.vcf.gz [outdir] [pdfname]"
  exit 1
fi
if [[ ! -f "${VCF}" ]]; then
  echo "ERROR: VCF not found: ${VCF}"
  exit 1
fi

mkdir -p "${OUTDIR}"
TMPDIR="${OUTDIR}/_tmp"
mkdir -p "${TMPDIR}"

command -v bcftools >/dev/null 2>&1 || { echo "ERROR: bcftools not found"; exit 1; }
command -v tabix >/dev/null 2>&1 || { echo "ERROR: tabix not found"; exit 1; }
command -v Rscript >/dev/null 2>&1 || { echo "ERROR: Rscript not found"; exit 1; }

# Index if missing
if [[ ! -f "${VCF}.tbi" && ! -f "${VCF}.csi" ]]; then
  tabix -p vcf "${VCF}"
fi

# List samples
SAMPLES_TXT="${OUTDIR}/samples.txt"
bcftools query -l "${VCF}" > "${SAMPLES_TXT}"

# Per-sample TSVs with site metrics for SNPs where the sample is NON-REF
# NOTE: This keeps the input as a MULTISAMPLE VCF, but processes one sample at a time.
echo "[INFO] Extracting per-sample metric TSVs (SNPs; non-ref in sample)..."
while IFS= read -r S; do
  [[ -z "${S}" ]] && continue
  OUT_TSV="${OUTDIR}/${S}.site_metrics.tsv"

  # Keep only SNPs, single sample, then keep only non-ref genotypes (0/1,1/0,1/1 and phased)
  bcftools view -v snps -s "${S}" "${VCF}" \
    | bcftools view -i 'GT!="0/0" && GT!="0|0" && GT!="./." && GT!=".|."' \
    | bcftools query -f '%CHROM\t%POS\t%QUAL\t%FILTER\t%INFO/DP\t%INFO/QD\t%INFO/MQ\t%INFO/FS\t%INFO/SOR\t%INFO/MQRankSum\t%INFO/ReadPosRankSum\n' \
    > "${OUT_TSV}"

done < "${SAMPLES_TXT}"

# R script: build 1 PDF page per sample
R_SCRIPT="${OUTDIR}/make_pdf.R"
cat > "${R_SCRIPT}" << 'RSCRIPT'
#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(gridExtra)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) stop("Usage: Rscript make_pdf.R <outdir> <samples.txt> <pdfname>")

outdir <- args[1]
samples_txt <- args[2]
pdfname <- args[3]

samples <- fread(samples_txt, header = FALSE)[[1]]
out_pdf <- file.path(outdir, pdfname)
pdf(out_pdf, width = 11, height = 8.5, onefile = TRUE)

num_cols <- c("QUAL","INFO_DP","QD","MQ","FS","SOR","MQRankSum","ReadPosRankSum")

p_hist <- function(df, col, title, xlab) {
  ggplot(df, aes(x = .data[[col]])) +
    geom_histogram(bins = 60, na.rm = TRUE) +
    theme_bw() +
    labs(title = title, x = xlab, y = "Count")
}

p_filter <- function(df) {
  d <- df[, .N, by = FILTER][order(-N)]
  if (nrow(d) > 12) {
    d <- rbind(d[1:11], data.table(FILTER="OTHER", N=sum(d$N) - sum(d[1:11]$N)))
  }
  d[, FILTER := factor(FILTER, levels = d$FILTER)]
  ggplot(d, aes(x = FILTER, y = N)) +
    geom_col() +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(title = "FILTER counts (site-level)", x = NULL, y = "Variants")
}

for (s in samples) {
  f <- file.path(outdir, paste0(s, ".site_metrics.tsv"))
  if (!file.exists(f)) next

  dt <- fread(f, header = FALSE, sep = "\t", na.strings = c(".", "NA", ""))

  # If a sample has zero non-ref variants, the file may be empty
  if (nrow(dt) == 0) {
    p <- ggplot() + theme_void() + annotate("text", x=0, y=0,
      label=sprintf("Sample: %s\nNo non-ref SNPs found (after filtering).", s),
      size=6, hjust=0)
    print(p)
    next
  }

  setnames(dt, c("CHROM","POS","QUAL","FILTER","INFO_DP","QD","MQ","FS","SOR","MQRankSum","ReadPosRankSum"))

  for (cc in num_cols) dt[, (cc) := suppressWarnings(as.numeric(get(cc)))]

  title_text <- sprintf("Site-level QC metrics (SNPs) for sample: %s\n(variants where sample is non-ref; n=%d)", s, nrow(dt))
  p_title <- ggplot() + theme_void() + annotate("text", x=0, y=0, label=title_text, size=5, hjust=0)

  g1 <- p_hist(dt, "QUAL", "QUAL (site)", "QUAL")
  g2 <- p_filter(dt)
  g3 <- p_hist(dt, "INFO_DP", "INFO/DP (site total depth)", "INFO/DP")
  g4 <- p_hist(dt, "QD", "QD (Quality by Depth)", "QD")
  g5 <- p_hist(dt, "MQ", "MQ (Mapping Quality)", "MQ")
  g6 <- p_hist(dt, "FS", "FS (strand bias)", "FS")
  g7 <- p_hist(dt, "SOR", "SOR (strand odds ratio)", "SOR")
  g8 <- p_hist(dt, "MQRankSum", "MQRankSum", "MQRankSum")
  g9 <- p_hist(dt, "ReadPosRankSum", "ReadPosRankSum", "ReadPosRankSum")

  grid.arrange(
    p_title,
    arrangeGrob(g1, g2, g3, g4, g5, g6, g7, g8, g9, ncol = 3),
    nrow = 2,
    heights = c(0.12, 0.88)
  )
}

dev.off()
message("PDF written to: ", out_pdf)
RSCRIPT

chmod +x "${R_SCRIPT}"
Rscript "${R_SCRIPT}" "${OUTDIR}" "${SAMPLES_TXT}" "${PDFNAME}"

echo "Done."
echo "PDF: ${OUTDIR}/${PDFNAME}"

