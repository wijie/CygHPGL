#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 目的 : NCルーターデータをHP-GL_1フォーマットに変換する
#           最終データ形式出力
#
# 変数/配列 :
#
# 注意 : HPGL-1_format の1単位(プロッタユニット)は0.025mmである
#      : A1サイズは 840mm * 594mm である
#      : HP-7586B の描画範囲は (-420, -297) から (420, 297) である
#
BEGIN {}

{
    if ($1 == "HPGL") {
        gsub(/^HPGL /, "")
        print $0
    } else
        print $0
}

END {
    print "\nPU;SP 0;\n"
}
