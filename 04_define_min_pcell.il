; Minimal PCell binder. This is a standalone geometry smoke test, not a
; replacement for the original DiffAmpPcell_T28 device layout.

procedure(DAminDefinePCell(lib cell)
  pcDefinePCell(
    list(ddGetObj(lib) cell "layout")
    (
      (Pw float 4.0)
      (Ps float 1.2)
      (Ra float 1.0)
    )
    let((cv)
      cv = pcCellView
      Pw = DAminClamp(Pw 1.0 10.0)
      Ps = DAminClamp(Ps 0.5 10.0)
      Ra = DAminClamp(Ra 0.5 5.0)
      DAminDrawAllParts(cv Pw Ps Ra)
    )
  )
)
