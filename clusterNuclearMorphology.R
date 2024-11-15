#!/usr/bin/env Rscript

# Copyright (C) 2024 Rishvanth Prabakar
#
# Authors: Rish Prabakar
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

suppressMessages(library("optparse"))
suppressMessages(library("ggplot2"))
suppressMessages(library("Seurat"))

main <- function() {
  
  parser <- OptionParser()
  parser <- add_option(parser, c("-f", "--cellFeatures"),
              help = "Cell features CSV file with header")
  parser <- add_option(parser, c("-o", "--outPrefix"),
              help = "Outfile prefix")
  parser <- add_option(parser, c("-k", "--kNeighbour"), default = 50, 
              help = "Number of nearest neighbour for kNN [default: %default]")
  parser <- add_option(parser, c("-r", "--resolution"), default = 0.3,
              help = "Clustering resolution [default: %default]")
  opt <- parse_args(parser)

  if (is.null(opt$cellFeatures) | is.null(opt$outPrefix)) {
    print_help(parser)
    quit(status = 1)
  }
 
  # read the propeties table
  features <- read.csv(opt$cellFeatures)
  print(dim(features))

  # check if there are rows with NA
  features <- features[complete.cases(features),]
  print(dim(features))

  # keep only the required features 
  features <- features[, c("area", "eccentricity", "DAPI_mean_intensity", 
                          "DAPI_contrast", "DAPI_homogeneity")]
  print(dim(features))

  # build graph
  features<- scale(features)
  nn.graph <- FindNeighbors(as.matrix(features), k.param = opt$kNeighbour) 

  # cluster 
  nn.cluster <- FindClusters(nn.graph$nn, resolution = opt$resolution)
  colnames(nn.cluster) <- "cluster"
  print(table(nn.cluster$cluster))

  # write clusters
  write.csv(data.frame(label = rownames(nn.cluster), cluster = nn.cluster$cluster),
    sprintf("%s_clusters.csv", opt$outPrefix), quote = F, row.names = F) 

  # plot umap 
  um <- RunUMAP(as.matrix(features))
  um <- data.frame(um[[]])
  um$cluster <- nn.cluster$cluster
  
  g <- ggplot(um) + geom_point(aes(x=UMAP_1, y=UMAP_2, color=cluster), size=0.2)
  ggsave(sprintf("%s_umap.pdf", opt$outPrefix), height=7, width=7)
}

main()
