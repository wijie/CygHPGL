#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 目的 : ドリルヒット回数を各ツール毎に集計する
#      : ツール情報とドリルカウント情報を合成する
#
# 変数/配列/連想配列 : vCatFlag / 外部変数,合成ファイルの有無
#                    : vOutputFile / 出力ファイルハンドル
#                    : vTempDir / 外部変数,テンポラリディレクトリの位置
#                    : vToolFile / ツール情報が納められているファイル
#                    : vToolCountFlag / ツールカウント処理用フラグ
#                    : aDrillCount[...] / ツールをキーとしたドリルカウント情報
#                    : aDrillFile[...] / split() が生成するテンポラリ配列
#                    : aToolFile[...] / split() が生成するテンポラリ配列
#                    : vDataType / 外部変数,入力データはNCかNCルーターか？
#
BEGIN {
    _TempDir()
    vToolCountFlag = "Off" # ツールカウント用フラグの初期化
    if (vCatFlag == 0) { # NCデータメインファイル処理
        vToolFile = vTempDir"MAINTOOL.TMP"
        vOutputFile = vTempDir"MAIN_INF.TMP"
    } else if (vCatFlag == 1) { # 合成ファイル処理
        vToolFile = vTempDir"CAT_TOOL.TMP"
        vOutputFile = vTempDir"CAT_INF.TMP"
    }
}

{
    if ($1 ~/T_[0-9]+/) { # ツール発見
        vToolCountFlag = "Ready" # ツールカウント準備
        vCurrentTool = $1 # 連想配列用のキーを用意する
    } else if ($0 == "G_81") # ドリルサイクル開始コード発見
        vToolCountFlag = "On" # ツールカウント開始
    else if ($0 == "G_80") # ドリルサイクル終了コード発見
        vToolCountFlag = "Off" # ツールカウント終了
    else if ($0 ~/M_0[57]/) { # ドリルヒットコード発見
        if (vToolCountFlag == "Ready")
            aDrillCount[vCurrentTool] += 1
        else if (vToolCountFlag == "Off")
            ;
        else if (vToolCountFlag == "On")
            ;
    } else if (vDataType == "NC" && $3 == "M_89") { # 逆セット防止コード発見
        if (vToolCountFlag == "Ready")
            aDrillCount[vCurrentTool] += 1
        else if (vToolCountFlag == "Off")
            ;
        else if (vToolCountFlag == "On")
            ;
    } else if ($1 ~/X_/ && $2 ~/Y_/) { # X/Y座標発見
        if (vToolCountFlag == "Ready")
            ;
        else if (vToolCountFlag == "Off")
            ;
        else if (vToolCountFlag == "On")
            aDrillCount[vCurrentTool] += 1
    }
}

END {
    while (getline < vToolFile > 0) { # ツール情報読み込み
        split($0, aToolFile, ":")
        if (vDataType == "NC")
            print $0":"aDrillCount[aToolFile[1]] > vOutputFile
        else if (vDataType == "NC_R")
            print $0":"aDrillCount[aToolFile[1]] > vTempDir"DRL_TMP1.TMP"
    }
    if (vDataType == "NC_R") {
        system(vSORT" "vTempDir"DRL_TMP1.TMP > "vOutputFile)
        close(vTempDir"DRL_TMP1.TMP")
    }
    close(vToolFile)
}
