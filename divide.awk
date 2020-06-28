#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 目的 : 入力ファイルをメイン/サブブロックに分割する
#
# 変数/配列/連想配列 : vDataType / 外部変数,データ型
#                    : aTemporary[...] / split() が生成するテンポラリ配列
#                    : vTempDir / テンポラリディレクトリの位置
#                    : vSubBlock / サブブロック出力ファイルハンドル
#                    : vNextLine / 内部変数,ブロック終了判定用変数
#                    : vMainBlock / メインブロック出力ファイルハンドル
#
BEGIN { _TempDir() }

{
    if (vDataType == "NC") { # NCデータの場合
        if ($1 ~/N_(4[4-9]|[5-8][0-9]|9[0-7])/) { # 個別サブブロック開始
            split($1, aTemporary, "_") # サブブロック番号を得る
            vSubBlock = vTempDir"M_"aTemporary[2]".SUB"
            for ( ; ; ) { # サブブロック出力開始
                getline vNextLine
                if (vNextLine == "M_99") { # サブブロック終了
                    break
                } else {
                    print vNextLine > vSubBlock
                    continue
                }
            }
            close(vSubBlock)
        } else if ($0 == "G_25") { # サブブロック終了,メインブロック開始
            vMainBlock = vTempDir"MAIN.TMP"
            for ( ; ; ) { # メインブロック出力開始
                getline vNextLine
                if (vNextLine == "M_02") { # データ終了
                    print vNextLine > vMainBlock
                    break
                } else {
                   print vNextLine > vMainBlock
                   continue
                }
            }
            close(vMainBlock)
            exit
        }
    } else if (vDataType == "NC_R") { # NCルーターデータの場合
        if ($1 ~/O_/ && $1 != "O_99") { # 個別サブブロック開始
            split($1, aTemporary, "_") # サブブロック番号を得る
            if (aTemporary[2] + 0 <= 2) { # メインブロック開始
                vSubBlock = vTempDir"MAIN.TMP"
            } else if (aTemporary[2] + 0 != 99) { # サブブロック開始
                vSubBlock = vTempDir"P_"aTemporary[2]".SUB"
            }
            for ( ; ; ) { # ブロック出力開始
                getline vNextLine
                if (vNextLine == "M_99" || vNextLine == "M_02") { # 個別サブブロック終了
                    break
                } else if (vSubBlock == vTempDir"MAIN.TMP") {
                    # ここで追加書き込みモードに設定するのは,NCルーターデータは
                    # O_1(O1)とO_2(O2)の二つがメインブロックになるからである
                    print vNextLine >> vSubBlock
                    continue
                } else {
                    print vNextLine > vSubBlock
                    continue
                }
            }
            close(vSubBlock)
        }
    }
}

END {
    if (vDataType == "NC_R")
        print "M_02" >> vTempDir"MAIN.TMP"
}
