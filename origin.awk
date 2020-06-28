#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 目的 : NCルーターデータの基準位置を求める
#
# 変数/配列/連想配列 : vTemporary / 各種テンポラリデータ
#                    : vFieldCount
#                    : aTemporary[...] / split() が生成するテンポラリ配列
#                    : vDataXOffset / データ基準位置(X座標)
#                    : vDataYOffset / データ基準位置(Y座標)
#
# 制限 : 入力データに"G_100"がなければどうなる？
#      : 斜辺の長さが同じになる座標がデータ中に存在する場合はどうしよう？
#
BEGIN {
    _TempDir()

    # 変数を定義する
    vDataXOffset = 0
    vDataYOffset = 0
    vAbsoluteX = 0
    vAbsoluteY = 0

    # ワークボード情報をファイルから取り込む
    _GetWBSInformation()
}

{
    if ($1 == "G_100") {
        getline vTemporary

        # 基板の基準位置を求める
        vFieldCount = split(vTemporary, aTemporary, " ")
        for (i = 1; i <= vFieldCount; i++) {
            if (aTemporary[i] ~/X_/)
                vDataXOffset = _GetCoordinate(aTemporary[i])
            else if (aTemporary[i] ~/Y_/)
                vDataYOffset = _GetCoordinate(aTemporary[i])
        }

        # 後始末
        _DeleteArray(aTemporary)
        exit
    }
}

END {
    # ワークボード情報を出力する
    print vWBSDefine":"vDataXOffset":"vDataYOffset > vWBSInformationFile

    # すべての T_06 の座標を得る
    _GetT06()
}

function _AbsoluteXY() {
#
# 目的 : _GetT06() の下請けサブルーチン
#      : X/Y座標を絶対値で返す
#
# 変数/配列/連想配列 : vIncrementX / カレントX座標(相対座標)
#                    : vIncrementY / カレントY座標(相対座標)
# 注意 : 絶対座標が初期化されるタイミングは,このサブルーチンの外で決定している
#
    vIncrementX = 0
    vIncrementY = 0

    for (i = 1; i <= NF; i++) {
        if ($i ~/X_/)
            vIncrementX = _GetCoordinate($i)
        else if ($i ~/Y_/)
            vIncrementY = _GetCoordinate($i)
    }

    vAbsoluteX += vIncrementX
    vAbsoluteY += vIncrementY

    return (vAbsoluteX":"vAbsoluteY)
}

function _GetT06 () {
#
# 目的 : T_06 で指定された穴位置を連想配列にまとめる
#      : T_06 連想配列をファイルに落とす
#
# 変数/配列/連想配列 : vInputFile / 入力ファイルへのハンドル
#                    : vAbsoluteX / カレントX座標(相対座標)
#                    : vAbsoluteY / カレントY座標(相対座標)
#                    : vGetT06Flag / 処理行確認用フラグ
#                    : aT06[...] / 発見順番をキーとする T_06 以降の穴開け座標
#
    # 変数の初期化
    vInputFile = vTempDir"DRL_HIT.TMP"
    vGetT06Flag = 0
    vT06Count = 0
    vAbsoluteX = 0
    vAbsoluteY = 0

    # 入力ファイルを読み込み, T06 以降の座標データを配列にまとめる
    while (getline < vInputFile > 0) {
        if ($0 == "T_06") # これ以降は処理対象データである
            vGetT06Flag = 1

        if (vGetT06Flag == 1) {
            if ($1 == "G_28") {
                vAbsoluteX = 0
                vAbsoluteY = 0
            } else if ($NF == "M_05" || $NF == "M_07" || $NF == "M_12") {
                vT06Count++
                aT06[vT06Count] = _AbsoluteXY()
            }
        }
    }
    close(vInputFile)

    # ファイルに落とす
    for (item in aT06) {
        print aT06[item]":"item > vTempDir"ORIGIN.TMP"
    }

    # 後始末
    _DeleteArray(aT06)
}

function _GetCoordinate(A) {
#
# 目的 : 引数として指定されたフィールドから,数だけを切り分けて返す
#
# 変数/配列/連想配列 : Temporary[...] / split() が生成するテンポラリ配列
#
# 注意 : 引数には *_* の形を期待している
#
    # 処理開始
    split (A, aTemporary, "_")
    return aTemporary[2]

    # 後始末
    _DeleteArray(aTemporary)
}

function _GetWBSInformation() {
#
# 目的 : ワークボード情報の読み込み
#      : 基準SGの位置を確認
#
# 変数/配列/連想配列 : vWBSInformationFile / ワークボード情報を納めたファイルへのハンドル
#                    : vWBSDefine / ワークボード情報
#                    : aTemporary[...] / split() が生成するテンポラリ配列
#                    : vTargetArea / 基準SGの位置
#
    # 変数設定
    vWBSInformationFile = vTempDir"WBS.TMP"
    vTargetArea = ""

    # ファイル読み込み
    while (getline < vWBSInformationFile > 0) {
        vWBSDefine = $0
    }
    close(vWBSInformationFile)

    # 基準位置を変数に取り込む
    split(vWBSDefine, aTemporary, ":")
    vTargetArea = aTemporary[4]

    # 後始末
    _DeleteArray(aTemporary)
}
