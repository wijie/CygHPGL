#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 目的 : NCルーターデータをHP-GL_1フォーマットに変換する
#           直線移動,ペン選択,ワークボード描画,データ原点
#           ヘッダ情報,穴開け,真円移動,スパイラル移動
#
# 変数/配列 :
#
# 注意 : HPGL-1_format の1単位(プロッタユニット)は0.025mmである
#      : A1サイズは 840mm * 594mm である
#      : HP-7586B の描画範囲は (-420 , -297) から (420 , 297) である
#
BEGIN {
    # 変数を初期化
    vPI = atan2(0, -1)
    fPenMode = "Up"
    fPenFunction = "Straight"

    # 前処理
    _TempDir() # テンポラリディレクトリの確認
    vDataOrigin = _ReadWBSInformation() # 入力データ原点の定義
    _ReadToolInformation()

    # ヘッダー部生成
    _MakeHeader()
}

{
    if ($0 ~/^$/) # カレント行は空行
        next
    else if ($1 != "HPGL") {
        if ($1 ~/T_/) { # ツール発見
            _GetTool($0)
            print "HPGL SP "vCurrentPenNumber";"
        } else if ($0 == "G_28 X_0 Y_0 " || $1 == "G_100") # データ原点へジャンプ
            print vDataOrigin
        else if ($1 == "mk_wbs") { # ワークボード生成
            if (vStandardSGXOffset == 0 && vStandardSGYOffset == 0)
                ;
            else
                _MakeWBS()
        } else { # ここから本番
            _MakeIJRXY() # フラグ,変数を準備する
            _CallFunction() # フラグ,変数に基づき,適切なサブルーチンを呼び出す
        }
    } else
        print $0
}

END {}

function _Spiral(A) {
#
# 目的 : _CallFunction() の下請けサブルーチン
#      : 引数 A で指定される形状でのスパイラルの近似
#
# 変数/配列 :
#
    if (A == "Spiral") { # 丸スパイラル
        SpiralXLength = (((vI - 0.2) * 2) / 0.025) # 丸スパイラル/半径判定
        print "HPGL CI "SpiralXLength";"
        print "HPGL PU "(-1 * (SpiralXLength / 2))","(SpiralXLength / 2)";"
        print "HPGL PD "(SpiralXLength)","(-1 * SpiralXLength)";"
        print "HPGL PU 0,"(SpiralXLength)";"
        print "HPGL PD "(-1 * SpiralXLength)","(-1 * SpiralXLength)";"
        print "HPGL PU "(SpiralXLength / 2)","(SpiralXLength / 2)";"
    }
    if (A == "SquareSpiral") { # 角スパイラル
        SpiralXLength = ((vX / 2) / 0.025) # 角スパイラル/X長判定
        SpiralYLength = ((vY / 2) / 0.025) # 角スパイラル/Y長判定
        print "HPGL PU "(-1 * (SpiralXLength / 2))","(-1 * (SpiralYLength / 2))";" # 角スパイラル/データ出力開始
        print "HPGL PD "SpiralXLength",0;"
        print "HPGL PD 0,"SpiralYLength";"
        print "HPGL PD "(-1 * (SpiralXLength))",0;"
        print "HPGL PD 0,"(-1 * (SpiralYLength))";"
        print "HPGL PD "SpiralXLength","SpiralYLength";"
        print "HPGL PU "(-1 * SpiralXLength)",0;"
        print "HPGL PD "SpiralXLength","(-1 * SpiralYLength)";"
        print "HPGL PU "((-1 * SpiralXLength) / 2)","(SpiralYLength / 2)";" # 角スパイラル/データ出力終了
    }
}

function _CircleTrack() {
#
# 目的 : _CallFunction() の下請けサブルーチン
#      : 真円移動モード
#
    if (vCurrentI == "null") { # 垂直移動での真円モード
        if (vJ < 0) {
            print "HPGL PU 0,"((-1 * vJ) / 0.025)";"
            print "HPGL CI "((-1 * vJ) / 0.025)";"
            print "HPGL PU 0,"(vJ / 0.025)";"
        } else {
            print "HPGL PU 0,"(vJ / 0.025)";"
            print "HPGL CI "(vJ / 0.025)";"
            print "HPGL PU 0,"((-1 * vJ) / 0.025)";"
        }
    }
    if (vCurrentJ == "null") { # 水平移動での真円モード
        if (vI < 0) {
            print "HPGL PU "((-1 * vI) / 0.025)",0;"
            print "HPGL CI "((-1 * vI) / 0.025)";"
            print "HPGL PU "(vI / 0.025)",0;"
        } else {
            print "HPGL PU "(vI / 0.025)",0;"
            print "HPGL CI "(vI / 0.025)";"
            print "HPGL PU "((-1 * vI) / 0.025)",0;"
        }
    }
}

function _StraightTrack(A) {
#
# 目的 : 直線移動モード
#
    if (A == "Up") {print "HPGL PU "(vX / 0.025)","(vY / 0.025)";"} # 描画しない場合の処理
    if (A == "Down") {print "HPGL PD "(vX / 0.025)","(vY / 0.025)";"} # 描画する場合の処理
}

function _Hit() {
#
# 目的 : 穴開け命令処理
#
    print "HPGL PU "(vX / 0.025)","(vY / 0.025)";"
    print "HPGL CI "((vCurrentToolSize / 2) / 0.025)";"
}

function _CallFunction() {
#
# 目的 : カレント行で, _MakeIJRXY() が生成したフラグと変数に基づき,適切なサブルーチンを呼び出す
#      : カレント行最終フィールドがヒット命令なら _Hit() を呼び出す
#
    # 処理開始
    if ($NF ~/M_(05|07|12)/) # 穴開け命令
        _Hit()
    else if ($0 ~/I_/ || $0 ~/J_/ || $0 ~/R_/ || $0 ~/X_/ || $0 ~/Y_/) { # この判定は必要か？
        if (fPenMode == "Up") # 描画しない場合の処理
            _StraightTrack(fPenMode)
        else if (fPenMode == "Down") { # 描画する場合の処理
            if (fPenFunction == "Straight")
                _StraightTrack(fPenMode)
            else if (fPenFunction != "Spiral" && \
                     vCurrentX == "null" && \
                     vCurrentY == "null" && \
                     vCurrentR == "null")
                _CircleTrack()
            else if (vCurrentR == "null" && fPenFunction == "CW")
                print $0
            else if (vCurrentR == "null" && fPenFunction == "CCW")
                print $0
            else if (vCurrentR != "null" && fPenFunction == "CW")
                print $0
            else if (vCurrentR != "null" && fPenFunction == "CCW")
                print $0
            else if (fPenFunction == "Spiral")
                _Spiral(fPenFunction)
            else if (fPenFunction == "SquareSpiral")
                _Spiral(fPenFunction)
        }
    }
}

function _MakeIJRXY() {
#
# 目的 : カレント行を分解して,次のステップの為の準備をする
#
# 注意 : _CallFunction() と対のサブルーチン
#
    # 変数を初期化
    vCurrentI = vCurrentJ = vCurrentR = vCurrentX = vCurrentY = "null"
    vI = vJ = vR = vX = vY = 0

    # フラグ,変数を定義する
    for (i = 1; i <= NF; i++) {
        if ($i == "G_00") {
            fPenMode = "Up"
            fPenFunction = "Straight"
        } else if ($i == "G_01") {
            fPenMode = "Down"
            fPenFunction = "Straight"
        } else if ($i == "G_02") {
            fPenMode = "Down"
            fPenFunction = "CW"
        } else if ($i == "G_03") {
            fPenMode = "Down"
            fPenFunction = "CCW"
        } else if ($i == "G_12") {
            fPenMode = "Down"
            fPenFunction = "Spiral"
        } else if ($i == "G_14") {
            fPenMode = "Down"
            fPenFunction = "SquareSpiral"
        } else if ($i == "M_04")
            fPenMode = "Down"
        else if ($i == "M_14")
            fPenMode = "Up"
        else if ($i ~/I_/) {
            split($i, aTemporary, "_")
            vCurrentI = aTemporary[2]
        } else if ($i ~/J_/) {
            split($i, aTemporary, "_")
            vCurrentJ = aTemporary[2]
        } else if ($i ~/R_/) {
            split($i, aTemporary, "_")
            vCurrentR = aTemporary[2]
        } else if ($i ~/X_/) {
            split($i, aTemporary, "_")
            vCurrentX = aTemporary[2]
        } else if ($i ~/Y_/) {
            split($i, aTemporary, "_")
            vCurrentY = aTemporary[2]
        }
    }

    # 各サブルーチンが座標値として利用する変数を準備する
    if (vCurrentI != "null") {vI = vCurrentI}
    if (vCurrentJ != "null") {vJ = vCurrentJ}
    if (vCurrentR != "null") {vR = vCurrentR}
    if (vCurrentX != "null") {vX = vCurrentX}
    if (vCurrentY != "null") {vY = vCurrentY}
}

function _LeftTop(A) {
#
# 目的 : _MakeWBS() の下請けサブルーチン
#      : ワークボード描画(外ガイド/左上)
#
# 変数/配列 :
#
    print ""
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(vStandardSGXOffset / 0.025)","(vStandardSGYOffset / 0.025)";"
    print "HPGL PU "(-1 * (5 / 0.025))","(5 / 0.025)";"
    print "HPGL PD 0,"(-1 * (vWBSYLength / 0.025))";"
    print "HPGL PD "(vWBSXLength / 0.025)",0;"
    print "HPGL PD 0,"(vWBSYLength / 0.025)";"
    print "HPGL PD "(-1 * (vWBSXLength / 0.025))",0;"
    print "HPGL PU "(5 / 0.025)","(-1 * (5 / 0.025))";"
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(-1 * (vStandardSGXOffset / 0.025))","(-1 * (vStandardSGYOffset / 0.025))";"
    print ""
}

function _RightTop(A) {
#
# 目的 : _MakeWBS() の下請けサブルーチン
#      : ワークボード描画(外ガイド/右上)
#
# 変数/配列/連想配列 :
#
    print ""
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(vStandardSGXOffset / 0.025)","(vStandardSGYOffset / 0.025)";"
    print "HPGL PU "(5 / 0.025)","(5 / 0.025)";"
    print "HPGL PD "(-1 * (vWBSXLength / 0.025))",0;"
    print "HPGL PD 0,"(-1 * (vWBSYLength / 0.025))";"
    print "HPGL PD "(vWBSXLength / 0.025)",0;"
    print "HPGL PD 0,"(vWBSYLength / 0.025)";"
    print "HPGL PU "(-1 * (5 / 0.025))","(-1 * (5 / 0.025))";"
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(-1 * (vStandardSGXOffset / 0.025))","(-1 * (vStandardSGYOffset / 0.025))";"
    print ""
}

function _RightBottom(A) {
#
# 目的 : _MakeWBS() の下請けサブルーチン
#      : ワークボード描画(外ガイド/右下)
#
# 変数/配列/連想配列 :
#
    print ""
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(vStandardSGXOffset / 0.025)","(vStandardSGYOffset / 0.025)";"
    print "HPGL PU "(5 / 0.025)","(-1 * (5 / 0.025))";"
    print "HPGL PD 0,"(vWBSYLength / 0.025)";"
    print "HPGL PD "(-1 * (vWBSXLength / 0.025))",0;"
    print "HPGL PD 0,"(-1 * (vWBSYLength / 0.025))";"
    print "HPGL PD "(vWBSXLength / 0.025)",0;"
    print "HPGL PU "(-1 * (5 / 0.025))","(5 / 0.025)";"
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(-1 * (vStandardSGXOffset / 0.025))","(-1 * (vStandardSGYOffset / 0.025))";"
    print ""
}

function _LeftBottom(A) {
#
# 目的 : _MakeWBS() の下請けサブルーチン
#      : ワークボード描画(外ガイド/左下)
#
# 変数/配列/連想配列 :
#
    print ""
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(vStandardSGXOffset / 0.025)","(vStandardSGYOffset / 0.025)";"
    print "HPGL PU "(-1 * (5 / 0.025))","(-1 * (5 / 0.025))";"
    print "HPGL PD "(vWBSXLength / 0.025)",0;"
    print "HPGL PD 0,"(vWBSYLength / 0.025)";"
    print "HPGL PD "(-1 * (vWBSXLength / 0.025))",0;"
    print "HPGL PD 0,"(-1 * (vWBSYLength / 0.025))";"
    print "HPGL PU "(5 / 0.025)","(5 / 0.025)";"
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(-1 * (vStandardSGXOffset / 0.025))","(-1 * (vStandardSGYOffset / 0.025))";"
    print ""
}

function _MakeWBS() {
#
# 目的 : ワークボードを生成する
#
# 変数/配列/連想配列 :
#
    if (vGuideHole == "Outside") {
        if (vStandardSG == "LeftBottom")
            _LeftBottom(vGuideHole)
        else if (vStandardSG == "RightBottom")
            _RightBottom(vGuideHole)
        else if (vStandardSG == "RightTop")
            _RightTop(vGuideHole)
        else if (vStandardSG == "LeftTop")
            _LeftTop(vGuideHole)
    } else if (vGuideHole == "Inside") {
        if (vStandardSG == "LeftBottom")
            _LeftBottom(vGuideHole)
        else if (vStandardSG == "RightBottom")
            _RightBottom(vGuideHole)
        else if (vStandardSG == "RightTop")
            _RightTop(vGuideHole)
        else if (vStandardSG == "LeftTop")
            _LeftTop(vGuideHole)
    }
}

function _GetTool(A) {
#
# 目的 : 引数 A で指定されたデータからツールを生成する
#      : ツール番号,ツールサイズを生成する
#
# 変数/配列 : vCurrentPenNumber / 現在選択されているツールを描画する為のペン番号
#           : vCurrentToolSize / 現在選択されているツールの直径
#
# 注意 : _ReadToolInformation() に依存する
#
    vToolInformation = aToolInformation[A] # _ReadToolInformation() が生成した配列から
    split(vToolInformation, aTemporary, ":") # ツール番号,ツールサイズを取り出す        
    vCurrentPenNumber = aTemporary[1]
    vCurrentToolSize = aTemporary[2]
}

function _MakeHeader() {
#
# 目的 : HP_GL_1データのヘッダー部を生成する
#      : データ原点までジャンプする
#      : ファイル名,ツール情報を出力する
#
# 注意 : ファイル名はワークボード原点から6.35mm下げた箇所に生成する
#      : ファイル名は文字幅3cm/文字高さ4cm(すべて大文字の場合)で描画する
#      : ツール情報はファイル名から5.08mm下げた箇所から生成する
#      : ツール情報は文字幅1.5cm/文字高さ2cm(すべて大文字の場合)で描画する
#
    print "HPGL DF;PR;PU;" # HPGLデータヘッダー出力
    print vDataOrigin # データ原点までジャンプ
    print "HPGL SP 1;" # ファイル名,ツール情報出力を開始
    print "HPGL PU 0,"(-1 * (6.35 / 0.025))";"
    print "HPGL SI.30,.40;LB"vInputFile"" # ファイル名出力

    vStepDownFlag = 1 # ツール情報出力を開始
    while (getline < vToolInformationFile > 0) { # ループ終了でツール情報出力終了
        split($0, aTemporary, ":")
        gsub("_", "", aTemporary[1])

        print vDataOrigin
        print "HPGL PU 0,"(-1 * (6.35 / 0.025))";"
        print "HPGL PU 0,"(-1 * ((5.08 * vStepDownFlag) / 0.025))";"
        print "HPGL SP "aTemporary[2]";"
        printf("HPGL SI.15,.20;LB%s/%-5smm/%6s\n", aTemporary[1], aTemporary[3], aTemporary[4])
        vStepDownFlag++
    }
    close(vToolInformationFile)
    print "" # ファイル名,ツール情報出力は終了
}

function _ReadToolInformation() {
#
# 目的 : ツール情報をツール番号をキーにした連想配列に読み込み,
#        描画の為の参照用連想配列を生成する
#
# 変数/配列 : vToolInformationFile / ツール情報を納めたファイル
#           : aToolInformation[...] /
#           : vToolCount / 読み込んだツール数
#
    # 変数を初期化
    vToolInformationFile = vTempDir"MAIN_INF.TMP"
    vToolCount = 0

    # 処理開始
    while (getline < vToolInformationFile > 0) {
        split($0 , aTemporary , ":")
        aToolInformation[aTemporary[1]] = aTemporary[2]":"aTemporary[3]
        vToolCount++
    }
    close(vToolInformationFile)
}

function _SetDataOrigin() {
#
# 目的 : _ReadWBSInformation() の下請けサブルーチン
#      : 入力データの原点を定義し,上位ルーチンへ返す
#
    # 処理開始
    if (vDataXOffset <= 0) {vDataXOffset = (-1 * vDataXOffset)} # 基準位置/X座標の補正
    if (vDataYOffset <= 0) {vDataYOffset = (-1 * vDataYOffset)} # 基準位置/Y座標の補正
    if (vStandardSGXOffset <= 0) {vStandardSGXOffset = (-1 * vStandardSGXOffset)} # SGオフセット/X座標の補正
    if (vStandardSGYOffset <= 0) {vStandardSGYOffset = (-1 * vStandardSGYOffset)} # SGオフセット/Y座標の補正

    # ガイド穴位置/基板外形サイズ等に基づき,データ原点を準備する
    if (vGuideHole = "Outside") { # 外ガイドの場合
        if (vStandardSGOffset = "LeftBottom") {
            vDataXOffset = (((vWBSXLength / 2) * -1) / 0.025)
            vDataYOffset = 0
        } else if (vStandardSGOffset = "RightBottom")
            ;
        else if (vStandardSGOffset = "RightTop")
            ;
        else if (vStandardSGOffset = "LeftTop")
            ;
    } else if (vGuideHole = "Inside") { # 内ガイドの場合
        if (vStandardSGOffset = "LeftBottom") {
            vDataXOffset = (((vWBSXLength / 2) * -1) / 0.025)
            vDataYOffset = 0
        } else if (vStandardSGOffset = "RightBottom")
            ;
        else if (vStandardSGOffset = "RightTop")
            ;
        else if (vStandardSGOffset = "LeftTop")
            ;
    }
    # データ原点を定義して,上位ルーチンに返す
    return "HPGL PA;PU "vDataXOffset","vDataYOffset";PR;"
}

function _ReadWBSInformation() {
#
# 目的 : ワークボードデータ等を外部ファイルから読み込み,変数に分類する
#      : 各変数に基づき,入力データ原点を定義する(_SetDataOrigin())
#      : 入力データ原点を上位ルーチンに返す
#
# 変数/配列 : vWBSInformationFile /
#           : vTemporary /
#           : aTemporary[...] /
#           : vWBSXLength / ワークボードX長
#           : vWBSYLength / ワークボードY長
#           : vGuideHole / ガイド穴の位置
#           : vStandardSG / 基準SGの位置
#           : vStandardSGXOffset / 基準SGのX方向オフセット値
#           : vStandardSGYOffset / 基準SGのY方向オフセット値
#           : vDataXOffset / 基準位置X座標
#           : vDataYOffset / 基準位置Y座標
#
    # ワークボード情報を読み込み,変数を準備する
    vWBSInformationFile = vTempDir"WBS.TMP"
    while (getline < vWBSInformationFile > 0) {
        vTemporary = $0
        split(vTemporary, aTemporary, ":")
        vWBSXLength = aTemporary[1]
        vWBSYLength = aTemporary[2]
        vGuideHole = aTemporary[3]
        vStandardSG = aTemporary[4]
        vStandardSGXOffset = aTemporary[5]
        vStandardSGYOffset = aTemporary[6]
        vDataXOffset = aTemporary[7]
        vDataYOffset = aTemporary[8]
    }
    close(vWBSInformationFile)
    return _SetDataOrigin()
}
