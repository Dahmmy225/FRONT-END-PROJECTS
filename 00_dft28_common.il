; Common helpers for DiffAmpPcell_T28 split geometry examples.
; Load before the geometry and PCell definition files.

procedure(DFT28_isOdd(n)
  let((v)
    v = fix(n)
    mod(v 2) != 0
  )
)

procedure(DFT28_clamp(x lo hi)
  let((v)
    v = x
    when(v < lo v = lo)
    when(v > hi v = hi)
    v
  )
)

procedure(DFT28_roundTo(x grid)
  let((v)
    if(grid && grid > 0.0 then
      v = round(x / grid) * grid
    else
      v = x
    )
    v
  )
)

procedure(DFT28_pt(x y)
  list(x y)
)

procedure(DFT28_rectPts(x1 y1 x2 y2)
  list(DFT28_pt(x1 y1) DFT28_pt(x2 y1) DFT28_pt(x2 y2) DFT28_pt(x1 y2))
)

procedure(DFT28_getTechFile(cv)
  let((tf libId)
    tf = nil
    when(cv
      libId = ddGetObj(cv~>libName)
      when(libId tf = techGetTechFile(libId))
    )
    tf
  )
)

procedure(DFT28_getMfgGrid(cv)
  let((tf grid)
    grid = 0.005
    tf = DFT28_getTechFile(cv)
    when(tf grid = techGetMfgGridResolution(tf))
    unless(grid && grid > 0.0 grid = 0.005)
    grid
  )
)

procedure(DFT28_normalizeParams(Pw Ps Tr Ra)
  let((w s t r span scale minW maxW minS maxS)
    w = if(Pw && Pw > 0.0 then Pw else 4.0)
    s = if(Ps && Ps > 0.0 then Ps else 1.0)
    t = if(Tr then fix(Tr) else 7)
    r = if(Ra && Ra > 0.0 then Ra else 1.0)

    when(t < 3 t = 3)
    when(t > 7 t = 7)
    unless(DFT28_isOdd(t) t = t + 1)
    when(t > 7 t = 7)

    case(t
      ((7) minW = 2.5 maxW = 4.8 minS = 1.2 maxS = 3.5)
      ((5) minW = 2.5 maxW = 7.0 minS = 1.75 maxS = 6.25)
      ((3) minW = 2.6 maxW = 14.0 minS = 1.5 maxS = 15.0)
      (t   minW = 2.5 maxW = 4.8 minS = 1.2 maxS = 3.5)
    )

    w = DFT28_clamp(w minW maxW)
    s = DFT28_clamp(s minS maxS)
    span = 14.0 * w + 13.0 * s
    when(span > 75.0
      scale = 75.0 / span
      w = DFT28_clamp(round(w * scale * 100.0) / 100.0 minW maxW)
      s = DFT28_clamp(round(s * scale * 100.0) / 100.0 minS maxS)
    )
    when(100.0 * r <= (w + s) * 13.0 + 5.0
      r = ((w + s) * 13.0 + 5.0) / 100.0
    )

    list(w s t r)
  )
)

procedure(DFT28_createPath(cv layer pts width)
  let((fig)
    fig = nil
    if(cv && layer && pts && length(pts) >= 2 && width > 0.0 then
      fig = dbCreatePath(cv layer pts width)
    else
      warn("DFT28_createPath: invalid argument layer=%L width=%L\n" layer width)
    )
    fig
  )
)

procedure(DFT28_createPolygon(cv layer pts)
  let((fig)
    fig = nil
    if(cv && layer && pts && length(pts) >= 3 then
      fig = dbCreatePolygon(cv layer pts)
    else
      warn("DFT28_createPolygon: invalid argument layer=%L\n" layer)
    )
    fig
  )
)

procedure(DFT28_deleteFigs(figs)
  let((clean)
    clean = setof(fig figs fig)
    foreach(fig clean dbDeleteObject(fig))
    t
  )
)

procedure(DFT28_orFigs(cv layer figs)
  let((clean out result)
    result = nil
    clean = setof(fig figs fig)
    when(cv && layer && clean
      out = dbLayerOr(cv layer clean)
      when(out result = car(out))
      DFT28_deleteFigs(clean)
    )
    result
  )
)

procedure(DFT28_shapePoints(fig)
  let((pts)
    pts = nil
    when(fig
      if(fig~>points then
        pts = fig~>points
      else
        when(fig~>bBox
          pts = DFT28_rectPts(xCoord(car(fig~>bBox)) yCoord(car(fig~>bBox))
                              xCoord(cadr(fig~>bBox)) yCoord(cadr(fig~>bBox)))
        )
      )
    )
    pts
  )
)

procedure(DFT28_addViaArray(cv viaLayer x y xPitch yPitch w l rows cols)
  let((xy)
    xy = nil
    if(cv && viaLayer && x && y && rows > 0 && cols > 0 then
      xy = dbCreateViaShapeArray(cv viaLayer nil x y xPitch yPitch w l rows cols)
    else
      warn("DFT28_addViaArray: invalid via request layer=%L rows=%L cols=%L\n" viaLayer rows cols)
    )
    xy
  )
)

procedure(DFT28_addOverlapVia(cv viaLayer pts1 pts2 dx dy xPitch yPitch w l rows cols)
  let((over pt xy)
    xy = nil
    when(cv && pts1 && pts2
      over = dbPointArrayAnd(cv list(pts1) list(pts2))
      if(over && car(over) then
        pt = car(car(over))
        xy = DFT28_addViaArray(cv viaLayer (xCoord(pt) + dx) (yCoord(pt) + dy) xPitch yPitch w l rows cols)
      else
        warn("DFT28_addOverlapVia: no overlap for %s\n" viaLayer)
      )
    )
    xy
  )
)

procedure(DFT28_createPinRect(cv layer pinName x1 y1 x2 y2 labelHeight)
  let((net rect label)
    net = dbCreateNet(cv pinName)
    rect = dbCreateRect(cv layer list(DFT28_pt(x1 y1) DFT28_pt(x2 y2)))
    when(net && rect dbCreatePin(net rect))
    label = dbCreateLabel(cv list(layer "text") DFT28_pt(((x1 + x2) / 2.0) ((y1 + y2) / 2.0))
                          pinName "centerCenter" "R0" "roman" labelHeight)
    list(rect label)
  )
)
