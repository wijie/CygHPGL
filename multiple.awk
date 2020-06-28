#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 目的 : 下記制御コード数値を正しい書式の小数点付き数値に直す
#
#           例) X_.1 Y_-10. --> X_0.1 Y_-10
#
#           1 : I
#           2 : J
#           3 : R
#           4 : U
#           5 : V
#           6 : X
#           7 : Y
#
#      : 下記の制御コード以外を削除する
#
#           01 : G00  : 非切削/移動のみ
#           02 : G01  : 切削/直線移動
#           03 : G02  : 切削/右回り曲移動
#           04 : G03  : 切削/左回り曲移動
#           05 : G12  : 丸スパイラル
#           06 : G14  : 角スパイラル
#           07 : G28  : 原点復帰(G100と等価)
#           08 : G64  : 切削/スリット加工
#           08 : G75  : Z軸上昇
#           09 : G100 : 原点復帰(G28と等価)
#           10 : G114 : ザグリ加工
#
#           11 : M04  : Z軸下降
#           12 : M05  : ドリルサイクル
#           12 : M12  : ドリルサイクル
#           13 : M14  : Z軸上昇
#           14 : M121 : 上面計測
#           15 : M122 : 計測終了
#
#           16 : Txxx : ツールナンバー
#
#      : モーダル形式 ==> ノンモーダル形式に変更する
#
# 変数/配列/連想配列 : vTempDir / 外部変数,テンポラリディレクトリの位置
#                    : vTemporary[...] / split() が生成するテンポラリ配列
#                    : vBuffer / 一時保管用変数
#
BEGIN { _TempDir() }

{
    for (i = 1; i <= NF; i++) { # 書式を整える
        # 制御コードを探せ
        # Gコード (G00,G01,G02,G03,G12,G14,G28,G64,G75,G100,G114)
        # Mコード (M04,M05,M12,M14,M121,M122)
        # Tコード (T_*)
        # その他のコード(I,J,R,U,V,X,Y) --> 数式を整える

        if ($i ~/G_(00|01|02|03|12|14|28|64|75|100|114)/)
            vBuffer = vBuffer $i" "
        else if ($i ~/M_(04|05|12|14|121|122)/)
            vBuffer = vBuffer $i" "
        else if ($i ~/T_/)
            vBuffer = vBuffer $i" "
        else if ($i ~/I_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        } else if ($i ~/J_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        } else if ($i ~/R_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        } else if ($i ~/U_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        } else if ($i ~/V_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        } else if ($i ~/X_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        } else if ($i ~/Y_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        }
    }
    gsub(/ $/, "", vBuffer)
    print vBuffer
    vBuffer = ""
}

END {}
