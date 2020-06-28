#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 目的 : 入力ファイルをHP-GL_1フォーマットに変換する
#           --> ワークボードを描画する
#           --> ファイル名を描画する
#           --> ツール名/穴径/穴数を描画する
#           --> M02の座標に特定のマークを描画する
#
# 変数/配列/連想配列 : vWBSXLength / ワークボードX長
#                    : vWBSYLength / ワークボードY長
#                    : vWBSXOffset / オフセットX長
#                    : vWBSYOffset / オフセットY長
#                    : vCatFlag / 外部変数,メインファイル,合成ファイル処理変更用
#                    : vCatFile / 外部変数,合成ファイル名
#                    : vToolInformationFile / ツール情報ファイル
#                    : vInputFile / 入力ファイル名
#                    : vStepDownFlag / ツール描画用変数
#                    : vTab / ツール描画用変数
#                    : vTotalCount / 穴数合計用変数
#                    : vToolSize / ドリル径
#                    : vRadius / CIの半径
#                    : vPenWidth / ペンの太さ
#                    : aToolInformation[...] / ツールコードをキーとしたツール情報(色,サイズ)
#                    : vPenModeFlag / ペンアップダウンフラグ
#                    : aTemporary[...] / split() が生成するテンポラリ配列
#                    : vABS_INC / ABS or INC判定用変数
#                    : vPrefix / プリフィックス用変数
#                    : vPrefixFlag / プリフィックスが必要か判定用フラグ
#                    : vWB_OriginX / ワークボード左下X座標
#                    : vWB_OriginY / ワークボード左下Y座標
#                    : vNC_OriginX / NC原点X座標
#                    : vNC_OriginY / NC原点Y座標
#
# サポートするNCデータ制御コード
#
#    1 : Txxx   = ツール指定                                    : SP
#    2 : M0[57] = ドリルサイクル(ドリルヒット)                  : CI
#    3 : G2[56] = サブブロック終了/開始                         : スクリプトで前処理を実施
#    4 : Nxx    = サブブロックシーケンス番号                    : スクリプトで前処理を実施
#    5 : G8[01] = 自動ドリルサイクル(自動ドリルヒット)終了/開始 : PU/PD
#    6 : M02    = データ終了コード                              : 複合命令を実行
#    7 : M89    = 逆セット防止コード                            : CI
#
# 注意 : HP-GL_1フォーマットの1単位(プロッターユニット)は0.025mmである
#      : A1サイズは 840mm * 594mm である
#      : HP-7586B の描画範囲は (-420, -297) から (420, 297) である
#
BEGIN {
    print "\nDF;\n"

    _TempDir()
    _ReadWBSInformation()
    _MakeWBS()
    _InputDataInformation()
    _JumpToDataOrigin()

    # ペン動作制御用フラグの設定
    # G80 = 0 / G81 = 1
    vPenModeFlag = 0

    # 絶対座標に設定   / 相対座標に設定
    # vABS_INC = "ABS" / vABS_INC = "INC"
    vABS_INC = "INC"

    # 座標に付けるプリフィックス(PA; or PU;)
    vPrefix = ""

    # プリフィックスが必要か判定するフラグ
    # 必要 = 0 / 不要 = 1
    vPrefixFlag = 1

    # ペンの太さ
    vPenWidth = 0.5
}

{
    if ($0 == "G_80") # ペンアップ
        vPenModeFlag = 0
    else if ($0 == "G_81") # ペンダウン
        vPenModeFlag = 1
    else if ($0 == "G_90") { # 絶対座標
        if (vABS_INC == "INC") {
            vABS_INC = "ABS"
            vPrefix = "PA;"
            vPrefixFlag = 0
        }
    } else if ($0 == "G_91") { # 相対座標
        if (vABS_INC == "ABS") {
            vABS_INC = "INC"
            vPrefix = "PR;"
            vPrefixFlag = 0
        }
    } else if ($1 ~/T_/) { # ツール選択
        vTool = $1
        split(aToolInformation[vTool], aTemporary, ":")
        vPenColor = aTemporary[1]
        vToolSize = aTemporary[2]
	vRadius = ((vToolSize - vPenWidth) / 2) / 0.025
	if (vRadius < 0) vRadius = 0 # 半径0以下は0で描く
        print "SP "vPenColor";"
    } else if ($1 ~/X_/ && $2 ~/Y_/) { # X/Y移動
        if (NF == 3 && $3 ~/M_(05|07|89)/) { # ヒットコード
            _XYCoordinate()
            if (vPrefixFlag == 1) vPrefix = ""
            if (vABS_INC == "ABS")
                print vPrefix"PU "(((vXCoordinate + vNC_OriginX) / 100) / 0.025) \
                      ","(((vYCoordinate + vNC_OriginY) / 100) / 0.025)";"
            else
                print vPrefix"PU "((vXCoordinate / 100) / 0.025)","((vYCoordinate / 100) / 0.025)";" # 100で割るのはなぜ？
            print "CI "vRadius";"
            vPrefixFlag = 1
        } else if (NF == 2 && vPenModeFlag == 1) { # ペンダウン
            _XYCoordinate()
            if (vPrefixFlag == 1) vPrefix = ""
            if (vABS_INC == "ABS")
                print vPrefix"PU "(((vXCoordinate + vNC_OriginX) / 100) / 0.025) \
                      ","(((vYCoordinate + vNC_OriginY) / 100) / 0.025)";"
            else
                print vPrefix"PU "((vXCoordinate / 100) / 0.025)","((vYCoordinate / 100) / 0.025)";" # 100で割るのはなぜ？
            print "CI "vRadius";"
            vPrefixFlag = 1
        } else if (NF == 2 && vPenModeFlag == 0) { # ペンアップ
            _XYCoordinate()
            if (vPrefixFlag == 1) vPrefix = ""
            if (vABS_INC == "ABS")
                print vPrefix"PU "(((vXCoordinate + vNC_OriginX) / 100) / 0.025) \
                      ","(((vYCoordinate + vNC_OriginY) / 100) / 0.025)";"
            else
                print vPrefix"PU "((vXCoordinate / 100) / 0.025)","((vYCoordinate / 100) / 0.025)";" # 100で割るのはなぜ？
            vPrefixFlag = 1
        }
    } else if ($0 == "M_02") { # データ終了コード
        if (vABS_INC == "ABS") vPrefix == "PR;"
        print "SP 1;"
        print vPrefix"PU "(-1 * (2.5 / 0.025))","(2.5 / 0.025)";"
        print "PD "(5 / 0.025)","(-1 * (5 / 0.025))";"
        print "PU 0,"(5 / 0.025)";"
        print "PD "(-1 * (5 / 0.025))","(-1 * (5 / 0.025))";"
    } else if ($0 == "M_89") # 逆セット防止コード
        print "CI "vRadius";"
}

END {
    if (vCatFile == "null" || vCatFlag == 1)
        print "\nPU;SP 0;\n"
}

function _XYCoordinate() {
#
# 目的 : X/Y座標の移動量を得る
#
# 変数/配列/連想配列 : aTemporart[...] / split() が生成するテンポラリ配列
#                    : vXCoordinate / X移動量
#                    : vYCoordinate / Y移動量
#
# 制限 : (たぶん)なし
#
    split($1, aTemporary, "_") # X移動量
    vXCoordinate = aTemporary[2]

    split($2, aTemporary, "_") # Y移動量
    vYCoordinate = aTemporary[2]
}

function _JumpToDataOrigin() {
#
# 目的 : 入力データに対応したデータ原点までジャンプする
#
# 注意 : スルーホールデータ原点はワークボードサイズによって可変するオフセット値がある
#      : ノンスルーホールデータ原点はワークボードサイズに関係なく一意に決定される
#      : 57.15はツールリストの描画エリアである
#      : 290は描画エリアである(297に設定すると切れてしまう為小さ目の値にした)
#
    print "PA;PU 420,297;"
    if ((vWBSYLength / 2) + 57.15 > 290) {
        print "PR;PU "(-1 * ((vWBSXLength / 2) / 0.025))","(-1 * ((vWBSYLength - 290) / 0.025))";"
        vWB_OriginX = -1 * (vWBSXLength / 2)
        vWB_OriginY = -1 * (vWBSYLength - 290)
    } else {
        print "PR;PU "(-1 * ((vWBSXLength / 2) / 0.025))","(-1 * ((vWBSYLength / 2) / 0.025))";"
        vWB_OriginX = -1 * (vWBSXLength / 2)
        vWB_OriginY = -1 * (vWBSYLength / 2)
    }
    if (vCatFlag == 0) { # スルーホールデータの場合
        print "PR;PU "(vWBSXOffset / 0.025)","(vWBSYOffset / 0.025)";"
        print ""
        vNC_OriginX = (vWB_OriginX + vWBSXOffset) * 100
        vNC_OriginY = (vWB_OriginY + vWBSYOffset) * 100
    } else if (vCatFlag == 1) { # ノンスルーホールデータの場合
        if (vPCBLayer == "Dual")
            print "PR;PU "(vWBSXOffset / 0.025)",0;"
        else
            print "PR;PU "((vWBSXOffset - 1) / 0.025)",0;"
        print ""
        vNC_OriginX = ((vWB_OriginX + vWBSXOffset) - 1) * 100
        vNC_OriginY = vWB_OriginY * 100
    }
}

function _InputDataInformation() {
#
# 目的 : ファイル名称/ドリルレポートを生成する
#      : 描画の為の参照用連想配列を生成する
#
# 注意 : ファイル名はワークボード原点から6.35mm下げた箇所に生成する
#      : ファイル名は文字幅3mm/文字高さ4mm(すべて大文字の場合)で描画する
#      : ツール情報はファイル名から5.08mm下げた箇所から生成する
#      : ツール情報は文字幅1.5mm/文字高さ2mm(すべて大文字の場合)で描画する
#      : ツール情報をツール番号をキーにした連想配列に読み込む(ペン色とツールの直径)
#
    print "PA;PU 420,297;"
    vStepDownFlag = 1
    vTab = 0
    vToolCount = 0
    if ((vWBSYLength / 2) + 57.15 > 290) {
        vListPossionX = (-1 * ((vWBSXLength / 2) / 0.025))
        vListPossionY = (-1 * (((vWBSYLength - 290) + 6.35) / 0.025))
    } else {
        vListPossionX = (-1 * ((vWBSXLength / 2) / 0.025))
        vListPossionY = (-1 * (((vWBSYLength / 2) + 6.35) / 0.025))
    }
    if (vCatFlag == 0) { # スルーホールデータの場合
        print "PA;PU "vListPossionX","vListPossionY";"
        vToolInformationFile = vTempDir"MAIN_INF.TMP"
        print "SI.30,.40;LB"vInputFile""
        print ""
    } else if (vCatFlag == 1) { # ノンスルーホールデータの場合
        print "PA;PU 0,"vListPossionY";"
        vToolInformationFile = vTempDir"CAT_INF.TMP"
        print "SI.30,.40;LB"vInputFile""
        print ""
    }
    while (getline < vToolInformationFile > 0) {
        split($0 , aTemporary , ":")
        aTemporary[2] *= 1
        aToolInformation[aTemporary[1]] = aTemporary[2]":"aTemporary[3]
        gsub("_", "", aTemporary[1])

        # T50は穴数に数えない
        if (aTemporary[1] == "T50")
            aTemporary[4] = "("aTemporary[4]")"
        else
            vTotalCount += aTemporary[4]

        if (vStepDownFlag > 10) {
            vTab += 2000
            vStepDownFlag = 1
        }
        if (vCatFlag == 0) # スルーホールデータの場合
            print "PA;PU "vListPossionX + vTab","vListPossionY - ((5.08 * vStepDownFlag) / 0.025)";"
        else if (vCatFlag == 1) # ノンスルーホールデータの場合
            print "PA;PU "0 + vTab"," vListPossionY - ((5.08 * vStepDownFlag) / 0.025)";"
        print "SP "aTemporary[2]";"
        if (aTemporary[1] == "T50")
            printf("SI.15,.20;LB%s/%-5smm/%7s\n", aTemporary[1], aTemporary[3], aTemporary[4])
        else
            printf("SI.15,.20;LB%s/%-5smm/%6s\n", aTemporary[1], aTemporary[3], aTemporary[4])
        vStepDownFlag++
    }
    if (vCatFlag == 0) # スルーホールデータの場合
        print "PA;PU "vListPossionX + vTab","vListPossionY - ((5.08 * vStepDownFlag) / 0.025)";"
    else if (vCatFlag == 1) # ノンスルーホールデータの場合
        print "PA;PU "0 + vTab"," vListPossionY - ((5.08 * vStepDownFlag) / 0.025)";"
    print "SP 1;"
    printf("SI.15,.20;LB%4s%-7s/%6s\n", "", "Total", vTotalCount)
    print ""
    close(vToolInformationFile)
}

function _MakeWBS() {
#
# 目的 : ワークボードを生成する
#
    print "PA;PU 420,297;"
    # 用紙の原点からワークボード原点まで絶対座標で移動する
    if ((vWBSYLength / 2) + 57.15 > 290)
        print "PR;PU "(-1 * ((vWBSXLength / 2) / 0.025))","(-1 * ((vWBSYLength - 290) / 0.025))";"
    else
        print "PR;PU "(-1 * ((vWBSXLength / 2) / 0.025))","(-1 * ((vWBSYLength / 2) / 0.025))";"
    print "PR;"

    # ペン番号1を選択
    print "SP 1;"

    # ワークボード描画
    print "PD "(vWBSXLength / 0.025)",0;"
    print "PD 0,"(vWBSYLength / 0.025)";"
    print "PD "(-1 * (vWBSXLength / 0.025))",0;"
    print "PD 0,"(-1 * (vWBSYLength / 0.025))";"
    print ""
}

function _ReadWBSInformation() {
#
# 目的 : ワークボード情報,オフセット値をファイルから読み込んで,変数を用意する
#
# 変数/配列/連想配列 :
#
    vWBSDefine = vTempDir"WBS.TMP"
    while (getline < vWBSDefine > 0) {
        split($0, aTemporary, ":")
        vWBSXLength = aTemporary[1]
        vWBSYLength = aTemporary[2]
        vWBSXOffset = aTemporary[3]
        vWBSYOffset = aTemporary[4]
    }
    close(vWBSDefine)
}
