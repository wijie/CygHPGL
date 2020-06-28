#
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 目的 : 各スクリプトで共通の変数, 関数をまとめる
#
BEGIN {
    vCP = "cp"     # ファイルをコピーするコマンド名
    vMV = "mv"     # ファイルを移動するコマンド名
    vRM = "rm"     # ファイルを削除するコマンド名
    vCAT = "cat"   # ファイルをリダイレクトするコマンド名
    vSORT = "sort" # ソートコマンド名
                   # sortはGNU sortを使う事(Windowsのsort.exeは不可)
    vCLEAR = "clear" # 画面を消去するコマンド名
}

function _DeleteArray(A) {
#
# 目的 : 引数 A で指定された配列の全要素を削除する
#
    for (item in A) {
        delete A[item]
    }
}

function _Test(file) {
#
# 目的 : ファイルの有無を調べる
#
    vFS = FS # フィールドセパレータを記憶
    vRS = RS # レコードセパレータを記憶
    FS = " " # フィールドセパレータをスペースに設定
    RS = "\n" # レコードセパレータを改行に設定

    err = getline < file
    close(file)
    FS = vFS # フィールドセパレータを戻す
    RS = vRS # レコードセパレータを戻す
    return err
}

function _TempDir() {
#
# 目的 : テンポラリディレクトリの場所を確認する
#
# 制限 : 環境変数で"TEMP"が設定されていなければならない
#      : 環境変数未設定の場合はカレントディレクトリに出力する
#
# 変数/配列/連想配列 : vTempDir / テンポラリディレクトリのファイルハンドル
#
    vTempDir = ENVIRON["TEMP"]
    gsub(/\\/, "/", vTempDir)
    if (substr(vTempDir, length(vTempDir), 1) == "/")
        ;
    else if (vTempDir == "")
        ;
    else
        vTempDir = vTempDir"/"
}
