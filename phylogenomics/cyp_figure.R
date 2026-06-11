
# Check if "devtools" installed
if("devtools" %in% rownames(installed.packages()) == FALSE){ 
  install.packages("devtools")
}

# install from github
devtools::install_github("g3viz/g3viz", force = TRUE)

library(g3viz)

mutation.dat <- readMAF("cyp51A_mutations.maf",
                        gene.symbol.col = "Hugo_Symbol",
                        variant.class.col = "Variant_Classification",
                        protein.change.col = "Protein_Change")

plot.options <- g3Lollipop.options(
  title.text = "Aspergillus fumigatus CYP51A mutations",
  legend.title = "Azole susceptibility",
  lollipop.pop.info.limit = 1.5,
  lollipop.pop.info.color = "#ffffff",
  lollipop.pop.min.size = 8,
  lollipop.pop.max.size = 20,
  lollipop.pop.info.dy = "0.35em",
  chart.width = 1200
)

plot <- g3Lollipop(
  mutation.dat,
  uniprot.id = "Q4WNT5",
  factor.col = "Phenotype",
  plot.options = plot.options,
  output.filename = "cyp51A_plot"
)


plot


###
library(httr)
library(jsonlite)

url <- "https://rest.uniprot.org/uniprotkb/Q4WNT5.json"

res <- fromJSON(content(GET(url), "text", encoding = "UTF-8"))

protein_length <- res$sequence$length

feat <- res$features

dom <- feat[feat$type == "Domain", ]

protein_domains <- data.frame(
  domain = dom$description,
  start = dom$location$start$value,
  end = dom$location$end$value,
  stringsAsFactors = FALSE
)

protein_domains$length <- protein_length


plot <- g3Lollipop(
  mutation.dat,
  gene.symbol = "CYP51A",
  protein.domains = protein_domains,
  factor.col = "Phenotype",
  plot.options = plot.options,
  output.filename = "cyp51A_plot"
)

plot
