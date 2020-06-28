#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 目的 : ブロック展開
#
# 変数/配列 : vTempDir / テンポラリディレクトリの位置
#           : vDataType / 外部変数,データ型
#           : vSubBlock / サブブロックファイル名
#           : vSubBlockCount / サブブロック呼び出し回数
#           : vSubBlockList / サブブロックファイル名のリスト
#           : vRM / ファイルを削除するコマンド名
#
# 注意 : NCルーターデータはサブブロック中で別のサブブロックを呼び出している事がある.
#      : 2回以上のサブブロック呼び出しには対応していない.
#
BEGIN {
    _TempDir()
}

{
    if (vDataType == "NC") {
        if ($0 ~/M_(4[4-9]|[5-8][0-9]|9[0-7])/ && $0 != "M_89") { # サブブロック呼び出し
            vSubBlock = vTempDir $1".SUB"
            if (vSubBlockList !~$1".SUB,")
                vSubBlockList = vSubBlockList $1".SUB,"
            while (getline < vSubBlock > 0)
                print $0
            close(vSubBlock)
        } else
            print $0
    } else if (vDataType == "NC_R") {
        if ($0 ~/M_98/ && $0 ~/P_/ && $0 ~/L_/) { # サブブロック複数呼び出し
            for (i = 1; i <= NF; i++) {
                if ($i ~/P_/) {
                    vSubBlock = vTempDir $i".SUB"
                    if (vSubBlockList !~$i".SUB,")
                        vSubBlockList = vSubBlockList $i".SUB,"
                } else if ($i ~/L_/) {
                    split($i, aTemporary, "_")
                    vSubBlockCount = aTemporary[2]
                    for (ii = 1; ii <= vSubBlockCount * 1; ii++) {
                        while (getline < vSubBlock > 0)
                            print $0
                        close(vSubBlock)
                    }
                    close(vSubBlock)
                }
            }
        } else if ($0 ~/M_98/ && $0 ~/P_/ && $0 !~/L_/) { # サブブロック呼び出し
            for (i = 1; i <= NF; i++) {
                if ($i ~/P_/) {
                    vSubBlock = vTempDir $i".SUB"
                    if (vSubBlockList !~$i".SUB,")
                        vSubBlockList = vSubBlockList $i".SUB,"
                    while (getline < vSubBlock > 0)
                        print $0
                    close(vSubBlock)
                }
            }
        } else if ($0 ~/G_114/) { # ザグリ加工用サブブロック呼び出し
            for (i = 1; i <= NF; i++) {
                if ($i ~/M_/) {
                    split($i, aTemporary, "_")
                    vSubBlock = vTempDir"P_"aTemporary[2]".SUB"
                    if (vSubBlockList !~"P_"aTemporary[2]".SUB,")
                        vSubBlockList = vSubBlockList "P_"aTemporary[2]".SUB,"
                    while (getline < vSubBlock > 0)
                        print $0
                    close(vSubBlock)
                }
            }
            close(vSubBlock)
        } else
            print $0
    }
}

END {
    _RmSubBlock()
}

function _RmSubBlock() {
#
# 目的 : テンポラリファイルを削除する
#
    vRmFiles = ""
    split(vSubBlockList, TempFile, ",")
    for (i in TempFile) {
        vErrorFlag = _Test(vTempDir TempFile[i])
        if (vErrorFlag != -1)
#            system(vRM" "vTempDir TempFile[i])
            vRmFiles = vRmFiles" "vTempDir TempFile[i]
    }
    system(vRM vRmFiles)
}
