; Geometry helpers for DiffAmpPcell_T28 split examples.
; These functions can be called inside several PCells.

procedure(DFT28_coreSpan(Pw Ps Tr Ra)
  let((p w s t r)
    p = DFT28_normalizeParams(Pw Ps Tr Ra)
    w = nth(0 p)
    s = nth(1 p)
    t = nth(2 p)
    r = nth(3 p)
    list(25.0 68.0 75.0 88.0 (50.0 * r) w s t r)
  )
)

procedure(DFT28_makeTaperedU(cv layer xLeft xTurn xExit yTop yBot width exitSign)
  let((temp p1 p2 p3 p4 main topPt botPt ptA ptB taper short merged)
    temp = (width - 2.5) * 0.5
    p1 = DFT28_pt(xExit (yTop - width * 0.5))
    p2 = DFT28_pt((xLeft + width * 0.5) (yTop - width * 0.5))
    p3 = DFT28_pt((xLeft + width * 0.5) (yBot + width * 0.5))
    p4 = DFT28_pt(xTurn (yBot + width * 0.5))
    main = DFT28_createPath(cv layer list(p1 p2 p3 p4) width)

    topPt = DFT28_pt(xExit yTop)
    botPt = DFT28_pt(xExit (yTop - width))
    ptA = DFT28_pt((xExit + temp) (yTop - temp))
    ptB = DFT28_pt((xExit + temp) (yTop - temp - 2.5))
    taper = DFT28_createPolygon(cv layer list(topPt ptA ptB botPt))
    short = DFT28_createPath(cv layer list(DFT28_pt((xExit + temp) (yTop - width * 0.5))
                                           DFT28_pt(xTurn (yTop - width * 0.5))) 2.5)
    merged = DFT28_orFigs(cv layer list(main taper short))
    merged
  )
)

procedure(DFT28_makeExitJog(cv layer x0 y0 width gap diagWidth direction)
  let((seg tail x1 y1 x2 y2 out)
    x1 = 75.0 - (width + gap) * 0.5
    y1 = y0
    x2 = 75.0 + (width + gap) * 0.5
    y2 = y0 + direction * (width + gap)
    seg = dbCreatePathSeg(cv layer DFT28_pt(x1 y1) DFT28_pt(x2 y2)
                          diagWidth "custom" "custom"
                          list(diagWidth * 0.5 diagWidth * 0.5
                               list(width * 0.5 width * 0.5 diagWidth * 0.5
                                    width * 0.5 width * 0.5 diagWidth * 0.5)))
    tail = DFT28_createPath(cv layer list(DFT28_pt(x2 y2) DFT28_pt(88.0 y2)) 2.5)
    out = DFT28_orFigs(cv layer list(seg tail))
    out
  )
)

procedure(DFT28_createM4Frame(cv Pw Ps Tr Ra M4Layer)
  let((p w s t r yMax offset outer inner outerMirror innerMirror diag jog figs)
    p = DFT28_normalizeParams(Pw Ps Tr Ra)
    w = nth(0 p)
    s = nth(1 p)
    t = nth(2 p)
    r = nth(3 p)
    yMax = 50.0 * r
    offset = (7 - t) * (w + s)
    diag = ceiling(2.5 * sqrt(2) / (DFT28_getMfgGrid(cv) * 2.0)) * DFT28_getMfgGrid(cv) * 2.0

    outer = DFT28_makeTaperedU(cv M4Layer 25.0 75.0 68.0 (yMax - offset) (-yMax + offset) w 1)
    jog = DFT28_makeExitJog(cv M4Layer (75.0 - (w + s) * 0.5) (yMax - offset - w * 0.5) w s diag -1)
    outer = DFT28_orFigs(cv M4Layer list(outer jog))
    when(outer outerMirror = dbCopyFig(outer cv list(150:0 "MY")))

    inner = DFT28_makeTaperedU(cv M4Layer (25.0 + 6.0 * (w + s)) 75.0 68.0
                               (yMax - 6.0 * (w + s)) (-yMax + 6.0 * (w + s)) w -1)
    jog = DFT28_makeExitJog(cv M4Layer (75.0 - (w + s) * 0.5) (-yMax + 6.0 * (w + s) + w * 0.5) w s diag 1)
    inner = DFT28_orFigs(cv M4Layer list(inner jog))
    when(inner innerMirror = dbCopyFig(inner cv list(150:0 "MY")))

    figs = list(outer outerMirror inner innerMirror)
    list(?outer outer ?outerMirror outerMirror ?inner inner ?innerMirror innerMirror ?figs figs)
  )
)

procedure(DFT28_createRingSet(cv layer Pw Ps Tr Ra startIndex count step MLayerName)
  let((p w s t r yMax diag idx space path jog mirror figs all)
    p = DFT28_normalizeParams(Pw Ps Tr Ra)
    w = nth(0 p)
    s = nth(1 p)
    t = nth(2 p)
    r = nth(3 p)
    yMax = 50.0 * r
    diag = ceiling(2.5 * sqrt(2) / (DFT28_getMfgGrid(cv) * 2.0)) * DFT28_getMfgGrid(cv) * 2.0
    all = list()

    for(idx 0 count - 1
      space = (w + s) * (startIndex + idx * step)
      path = DFT28_makeTaperedU(cv layer (25.0 + space) 75.0 68.0
                                (yMax - space) (-yMax + space) w 1)
      jog = DFT28_makeExitJog(cv layer (75.0 - (w + s) * 0.5) (-yMax + space + w * 0.5) w s diag 1)
      path = DFT28_orFigs(cv layer list(path jog))
      when(path mirror = dbCopyFig(path cv list(150:0 "R180")))
      all = append(all list(path mirror))
    )
    all
  )
)

procedure(DFT28_createM4Rings(cv Pw Ps Tr Ra M4Layer)
  let((p t cnt)
    p = DFT28_normalizeParams(Pw Ps Tr Ra)
    t = nth(2 p)
    cnt = (t - 3) / 2
    if(cnt > 0 then
      DFT28_createRingSet(cv M4Layer Pw Ps Tr Ra 2 cnt 2 M4Layer)
    else
      list()
    )
  )
)

procedure(DFT28_createM3Rings(cv Pw Ps Tr Ra M3Layer)
  let((p t cnt)
    p = DFT28_normalizeParams(Pw Ps Tr Ra)
    t = nth(2 p)
    cnt = (t - 1) / 2
    DFT28_createRingSet(cv M3Layer Pw Ps Tr Ra 1 cnt 2 M3Layer)
  )
)

procedure(DFT28_createPortBridge(cv Pw Ps Tr Ra M3Layer M4Layer M5Layer Via3 Via4 Via5)
  let((p w s t r yTop yBot h1 h2 v1 v2)
    p = DFT28_normalizeParams(Pw Ps Tr Ra)
    w = nth(0 p)
    s = nth(1 p)
    t = nth(2 p)
    r = nth(3 p)
    yTop = 50.0 * r + 20.0 + w
    yBot = -50.0 * r - 30.0 - w

    h1 = DFT28_createPath(cv M4Layer list(DFT28_pt(-20.0 yTop) DFT28_pt(170.0 yTop)) w)
    h2 = DFT28_createPath(cv M3Layer list(DFT28_pt(-25.0 (yTop + 10.0)) DFT28_pt(175.0 (yTop + 10.0))) w)
    v1 = DFT28_createPath(cv M5Layer list(DFT28_pt(-15.0 yBot) DFT28_pt(-15.0 yTop)) 5.0)
    v2 = DFT28_createPath(cv M5Layer list(DFT28_pt(165.0 yBot) DFT28_pt(165.0 yTop)) 5.0)

    DFT28_addViaArray(cv Via4 -16.0 (yTop - w * 0.5) 3.0 3.0 1.5 1.5 1 3)
    DFT28_addViaArray(cv Via4 163.0 (yTop - w * 0.5) 3.0 3.0 1.5 1.5 1 3)
    DFT28_addViaArray(cv Via5 -17.0 yBot 4.0 4.0 2.0 2.0 2 1)
    DFT28_addViaArray(cv Via5 162.0 yBot 4.0 4.0 2.0 2.0 2 1)
    DFT28_addViaArray(cv Via3 24.0 (yTop + 10.0) 3.0 3.0 1.5 1.5 1 3)
    DFT28_addViaArray(cv Via3 154.0 (yTop + 10.0) 3.0 3.0 1.5 1.5 1 3)

    DFT28_createPinRect(cv M5Layer "P1" -17.5 yBot -12.5 (yBot + 5.0) w)
    DFT28_createPinRect(cv M5Layer "P2" 162.5 yBot 167.5 (yBot + 5.0) w)
    DFT28_createPinRect(cv M3Layer "P3" -25.0 (yTop + 10.0) (-25.0 + w) (yTop + 10.0 + w) w)
    DFT28_createPinRect(cv M3Layer "P4" (175.0 - w) (yTop + 10.0) 175.0 (yTop + 10.0 + w) w)

    list(h1 h2 v1 v2)
  )
)
