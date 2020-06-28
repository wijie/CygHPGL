#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 目的 : 基準SGの位置に従い,入力ファイルをマークアップする
#
# 変数/配列/連想配列 :
#
BEGIN {
    _TempDir()

    # 変数の初期化
    vMarkupInput = vTempDir"SORT.TMP"
    vTargetStandardSG = ""
    vT06Flag = 0
    vT06Count = 0

    # ソート済みの T06[...] を読み込み,変数を用意する
    while (getline < vMarkupInput > 0) {
        split($0 , aTemporary , ":")
        vTargetStandardSG = aTemporary[3]
        break
    }
}

{
    print $0
    if ($0 == "T_06")
        vT06Flag = 1
    else if (vT06Flag == 1) {
        if ($NF == "M_05" || $NF == "M_07" || $NF == "M_12") {
            vT06Count++
            if (vT06Count == vTargetStandardSG)
                print "mk_wbs"
        }
    }
}

END {}
