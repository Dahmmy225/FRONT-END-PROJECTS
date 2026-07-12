; Minimal split loader for independent geometry experiments.

procedure(DAminLoad(baseDir)
  let((sep)
    sep = "/"
    load(strcat(baseDir sep "02_min_geom_helpers.il"))
    load(strcat(baseDir sep "03_min_parts.il"))
    load(strcat(baseDir sep "04_define_min_pcell.il"))
  )
)
