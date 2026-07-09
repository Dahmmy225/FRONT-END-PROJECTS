NMOS Pcell（升级版，含TAP和CDF）
skill
;============================================================
; NMOS Pcell 完整版
; 库名: Faker  单元名: NmosPcell
; 参数: l(沟道长度), w(沟道宽度), TAP(衬底接触环开关)
; 包含CDF注册，支持参数化面板
;============================================================
pcDefinePCell(
   list(ddGetObj("Faker") "NmosPcell" "layout")  ; 指定Pcell位置
       (                                          ; 参数列表开始
        (l "1.0u")                                ; 沟道长度，字符串类型，默认1.0u
        (w "6.0u")                                ; 沟道宽度，默认6.0u
        (TAP "Yes")                               ; 衬底接触开关，默认Yes(生成)
       )
    let(((cv pcCellView))                         ; cv绑定到当前cellView
      l=evalstring(l)*1e6                         ; 解析字符串并转为数据库单位(微米)
      w=evalstring(w)*1e6

    ;------------ 1. 栅极 (POLY1) ------------
    Gate=rodCreateRect(
        ?cvId   cv
        ?layer "POLY1"
        ?width  l
        ?length w+2*1.00
        ?origin l/(-2):(w+2*1.00)/(-2)             ; 中心对称
            )

    ;------------ 2. 有源区 (DIFF) ------------
    DIFF=rodCreateRect(
        ?cvId   cv
        ?layer "DIFF"
        ?width  l+2*1.20
        ?length w
        ?origin (l+2*1.00)/(-2)-0.2:w/(-2)         ; 偏移对齐
            )

    ;------------ 3. 源漏金属 + 接触孔阵列 ------------
    SDPath=rodCreateRect(
        ?cvId   cv
        ?layer "METAL1"
        ?width  1.20
        ?length w
        ?origin (l+2*1.00)/(-2)-0.2:w/(-2)
        ?elementsX 2                                ; 复制2份 (源和漏)
        ?spaceX l                                   ; 间距 = l (栅极宽度)
        ?subRectArray
           list(
                list(
                ?layer "CONT"
                ?width 0.50
                ?length 0.50
                ?gap "distribute"                    ; 均匀分布
                ?lowerLeftOffsetX 0.30
                ?lowerLeftOffsetY 0.30
                ?upperRightOffsetX -0.3
                ?upperRightOffsetY -0.3
                ?spaceX            0.5
                ?spaceY            0.5
                     );End 1st subrectangle list
               );End all subrectangle lists
           );SD Path

    ;------------ 4. N+注入层 (NIMP) ------------
    NIMP=rodCreateRect(
            ?cvId  cv
            ?layer "NIMP"
            ?fromObj DIFF                            ; 基于DIFF扩展
            ?size 0.80
                     )

    ;------------ 5. 衬底接触环 (TAP) ------------
    if(TAP == "Yes"                                 ; 仅当TAP参数为"Yes"时生成
        then
        TAP_Path = rodCreatePath(                   ; 创建封闭路径
            ?layer "METAL1"                         ; 顶层金属
            ?width 1.1                              ; 金属宽度
            ?pts list(0:-1*(w/2+2.55)               ; 起点：下方中心
                      l/2+3.75:-1*(w/2+2.55)        ; 右下角
                      l/2+3.75:1*(w/2+2.55)         ; 右上角
                     -1*(l/2+3.75):1*(w/2+2.55)     ; 左上角
                     -1*(l/2+3.75):-1*(w/2+2.55)    ; 左下角
                      0:-1*(w/2+2.55))              ; 回到起点，形成闭环
            ?pin t                                  ; 创建端子Pin
            ?pinLabel t                             ; 创建Pin标签
            ?termIOType "inputOutput"               ; Pin方向：双向
            ?termName "B"                           ; 端子名：B (体端)
            ?offsetSubPath                          ; 嵌套子路径
            list(
                list(?layer "DIFF"                   ; 扩散层
                     ?width 1.1)                     ; 与金属等宽
                list(?layer "PIMP"                   ; P+注入层 (用于衬底接触)
                     ?width 1.1+2*0.8)              ; 每侧扩展0.8
                );offsetSubPath
            ?subRect                                 ; 路径上的接触孔
            list(
                list(?layer "CONT"
                     ?width 0.5
                     ?length 0.5
                     ?gap "distribute"               ; 沿路径均匀分布
                     ?beginOffset 0.25               ; 路径起点偏移
                     ?endOffset 0.25                 ; 路径终点偏移
                     ?space 0.5                      ; 孔间距
                    )
                ); subRect lists
            );rodCreatePath
        );if

    ;------------ 6. 标签 ------------
    dbCreateLabel(cv "TEXT" 0:0 sprintf(nil "W=%Lu" w) "centerCenter" "R0" "roman" 0.5)
    dbCreateLabel(cv "TEXT" 0:-0.8 sprintf(nil "L=%Lu" l) "centerCenter" "R0" "roman" 0.5)
           );let
        );pcDefine

;============================================================
; CDF 参数面板注册部分
;============================================================
   let((libId cellId cdfId)
        unless(cellId = ddGetObj("Faker" "NmosPcell")  ; 获取cell对象
              error("Could not get cell %s." "NmosPcell")
                     )
            cdfId = cdfGetBaseCellCDF(cellId)          ; 获取已有CDF
            when(cdfId cdfDeleteCDF(cdfId))            ; 如果存在，先删除
            cdfId = cdfCreateBaseCellCDF(cellId)       ; 创建新基础CDF

            ; 注册参数 l
            cdfCreateParam(cdfId
                ?name "l"
                ?prompt "Length(M)"
                ?units "lengthMetric"                  ; 单位类型：长度
                ?defValue "1.0u"
                ?type "string"                         ; 字符串类型
                ?display "t"
                ?editable "t"
                ?parseAsNumber "yes"                   ; 解析为数字
                ?parseAsCEL "yes"
                ?storeDefault "no"
                          )
            ; 注册参数 w
            cdfCreateParam(cdfId
                ?name "w"
                ?prompt "Width(M)"
                ?units "lengthMetric"
                ?defValue "6.0u"
                ?type "string"
                ?display "t"
                ?editable "t"
                ?parseAsNumber "yes"
                ?parseAsCEL "yes"
                ?storeDefault "no"
                           )
            ; 注册参数 TAP (下拉菜单)
            cdfCreateParam(cdfId
                ?name "TAP"
                ?prompt "tap"
                ?choices '("None" "Yes")                ; 枚举选项
                ?defValue "Yes"
                ?type "cyclic"                          ; 循环类型 (下拉菜单)
                ?display "t"
                ?editable "t"
                           )
            cdfSaveCDF(cdfId)                           ; 保存CDF
       );let