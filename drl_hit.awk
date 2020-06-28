#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 目的 : 入力ファイル中にM05/M07/M12/M89が含まれている場合の処理をおこなう
#        なお,この処理は _Drl_Hit(TargetFile) がおこなう
#
# 変数/配列/連想配列 : vDataType / 外部変数,入力データはNCかNCルーターか？
#                    : vConvertFlag / M0[57]/M12/M89処理用判定フラグ
#                    : vTempDir / 外部変数,テンポラリディレクトリの位置
#                    : サブルーチン内の変数/配列/連想配列は,サブルーチン内のコメントを参照する事
#
BEGIN {
    _TempDir()
    vOutputFile = vTempDir"DRL_HIT.TMP"
}

{
   if ($1 ~/M_(05|07|12)/) { # M_05/M_07/M_12 発見
        vConvertFlag = 1
        exit
    } else if ($1 == "M_89" && vDataType == "NC") { # M_89 発見
        vConvertFlag = 1
        exit
    }
}

END {
    close(FILENAME)
    if (vConvertFlag == 0) { # M05/M07/M12/M89は含まれていない
        system(vCP" "FILENAME" "vTempDir"DRL_HIT.TMP")
        close(vTempDir"DRL_HIT.TMP")
    } else if (vConvertFlag == 1) # M05/M07/M12/M89が含まれている
        _Drl_Hit(FILENAME)
}

function _Drl_Hit(A) {
#
# 目的 : 入力ファイル中にM05/M07/M12/M89が含まれている場合の処理をおこなう
#
#        サンプル_1) X_xxxx Y_yyyy ---------------> X_xxxx Y_yyyy M_0[57]
#                     M_0[57] / M12
#
#        サンプル_2) X_xxxx Y_yyyy M_0[57] / M12 -> これはそのまま
#
# 注意 : NCデータ/NCルーターデータ中に含まれるG81/M05/M07?M12は
#        ドリルサイクル(ドリルヒット)命令であるが,それぞれの動作には相違がある.
#
#         G81   この制御コード以下のX/Y座標に対して穴を開ける
#               この命令はG80によって解除されるまで有効である
#
# M05/M07/M12   この制御コードの直前/同一行のX/Y座標にのみ穴を開ける
#               この命令は直前/同一行のX/Y座標に対してのみ有効である
#
#         M89   この制御コードの直前/同一行のX/Y座標にのみ穴を開ける
#               この命令は直前/同一行のX/Y座標に対してのみ有効である
#               M89は逆セット判定コードであるが,ドリルヒットを行うので
#               ドリルヒット命令として扱う
#
#      : これらの命令がデータ中に混在している可能性がある事に留意せよ.
#
# 変数/配列/連想配列 : A : 入力ファイルハンドル
#                    : vOutputFile : 出力ファイルハンドル
#                    : vLineBuffer : M_0[57]/M12/M89 判定用変数
#
    n = 0 # 読み込んだ行数
    while (getline < A > 0) {
        if (NF == 1) {
            if ($1 ~/M_(05|07|12)/)
                printf " "$0 > vOutputFile
            else if ($1 == "M_89" && vDataType == "NC")
                printf " "$0 > vOutputFile
            else {
                if (n > 0) # 1行目に空行が入るのが嫌なので
                    printf "\n"$0 > vOutputFile
                else
                    printf $0 > vOutputFile
            }
        } else {
            if (n > 0) # 1行目に空行が入るのが嫌なので
                printf "\n"$0 > vOutputFile
            else
                printf $0 > vOutputFile
        }
        n++
    }
    print "" > vOutputFile
    close(A)
    close(vOutputFile)
}
