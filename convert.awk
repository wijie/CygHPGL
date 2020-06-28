#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 変換メインモジュール/リリース4(AWK版)
#
#   目的 : ユーザーインターフェイスモジュール/リリース4の出力ファイル
#          (TempDir/NC2HPGL.TBL)を読み込みNCデータ/NCルーターデータを
#          HP-GL_1フォーマットに変換する
#
#   注意 : 各データワークボードサイズによって,それの原点からのシフト値(下駄)が異なる
#           スルーホール/両面基板 => 1) ワークボード短辺400mm未満 = X:Y <=> 4mm : 0mm
#                                    2) ワークボード短辺400mm以上 = X:Y <=> 4mm : 25mm
#           スルーホール/多層基板 => 1) ワークボード短辺400mm以下 = X:Y <=> 5mm : ワークボードY辺/2
#                                    2) ワークボード短辺400mm超   = X:Y <=> 5mm : 205mm
#           ノンスルーホール穴基板 ===============================> X:Y <=> 4mm : 0mm
#
#        : NCルーターデータの原点シフト計算は下記の通り
#           外ガイド => 5mm * 5mm
#           内ガイド => (基準SGからのX + 5mm) * (基準SGからのY + 5mm)
#
#        : Cygwin付属Awkは, system()のシェルがsh.exeである
#
BEGIN {
    FS = "\n"            # フィールドセパレータは改行
    RS = ""              # レコードセパレータは空行
    vAWK = "gawk"        # AWKの実行ファイル名
    vNCDir = "./NC/"     # NCデータを置くディレクトリ
    vHPGLDir = "./HPGL/" # *.HPを出力するディレクトリ
    _TempDir()
    vUserInterfaceTable = vTempDir"NC2HPGL.TBL" # UIF.AWK 出力ファイル

    system(vCLEAR) # 画面を消去する
    system("echo 変換中．．．\\(-.-\\)y-~~")

    while (getline < vUserInterfaceTable > 0) {
        if ($0 !~/^$/) {
            _DataInitialize()
            vDataType = $1
            vMainFile = $2
            split(vMainFile, aTemporary, ".")
            vBaseFileName = aTemporary[1]
            _DivideTool($3)
            _WBSDefine($4)
            vPCBLayer = $5
            vCatFile = $6
            _DivideTool($7)
        }

        # データ変換開始
#        vOutputDev = "lpt2" # プリンタポートに出力
#        vOutputDev = vHPGLDir vBaseFileName".HP" # ファイルに出力
	vOutputDev = vTempDir "TEMP.HP" # テンポラリに出力
        if (vDataType == "NC") {
            if (vCatFile == "null") { # 合成しない処理
                _ConvertNC(vMainFile, 0, vOutputDev) # NCデータメインファイル
            } else if (vCatFile != "null") { # 合成ファイル処理
                _ConvertNC(vMainFile, 0, vTempDir"T_HOLE.HP") # NCデータメインファイル
                _ConvertNC(vCatFile, 1, vTempDir"N_T_HOLE.HP") # NCデータ合成ファイル
                system(vCAT" "vTempDir"T_HOLE.HP "vTempDir"N_T_HOLE.HP > "vOutputDev)
            }
        } else if (vDataType == "NC_R") { # NCルーターデータ変換開始
            _ConvertNC_R()
        }
#        print "PRINT "vBaseFileName".HP" >> "P_OUT.BAT"
        _RmTempFiles()
    }
    exit
}

END {
    system(vRM " " vUserInterfaceTable)
#    if (vOutputDev !~/^lpt[1-9]$/) {
#        gsub("/", "\\", vHPGLDir)
#        system("start '" vHPGLDir "'")
#    }
#getline PAUSE < "/dev/stdin" # プログラムを止める(デバッグ用)
}

function _ConvertNC_R() {
#
# 目的 : NCルーターデータ変換
#
# 変数/配列/連想配列 :
#
    _MkField(vNCDir vMainFile, vTempDir"MK_FIELD.TMP")
    system(vAWK" -v vDataType="vDataType \
               " -f nc2hplib.awk \
                 -f divide.awk "vTempDir"MK_FIELD.TMP")

    vErrorFlag = _Test(vTempDir"MAIN.TMP")

    if (vErrorFlag == -1) {
        system(vMV" "vTempDir"MK_FIELD.TMP "vTempDir"EXPAND_2.TMP")
    } else {
        system(vAWK" -v vDataType="vDataType \
                   " -f nc2hplib.awk \
                     -f expand.awk "vTempDir"MAIN.TMP > "vTempDir"EXPAND_1.TMP")
        system(vAWK" -v vDataType="vDataType \
                   " -f nc2hplib.awk \
                     -f expand.awk "vTempDir"EXPAND_1.TMP > "vTempDir"EXPAND_2.TMP")
    }

    system(vAWK" -f nc2hplib.awk \
                 -f multiple.awk "vTempDir"EXPAND_2.TMP > "vTempDir"MULTIPLE.TMP")
    system(vAWK" -v vDataType="vDataType \
               " -f nc2hplib.awk \
                 -f drl_hit.awk "vTempDir"MULTIPLE.TMP")
    system(vAWK" -v vCatFlag=0 \
                 -v vDataType="vDataType \
               " -f nc2hplib.awk \
                 -f t_count.awk "vTempDir"DRL_HIT.TMP")
    system(vAWK" -f nc2hplib.awk \
                 -f origin.awk "vTempDir"DRL_HIT.TMP")

    vSortInput = vTempDir"ORIGIN.TMP"
    vSortOutput = vTempDir"SORT.TMP"
    vX = "null"
    vY = "null"
    vHitCount = "null"
    vCurrentX = "null"
    vCurrentY = "null"
    vCurrentHitCount = "null"
    FS = " " # フィールドセパレータをリセット
    RS = "\n" # レコードセパレータをリセット
    if (vStandardSG == "LeftBottom")
        system(vSORT" -n -t: -k1,2 "vSortInput" > "vSortOutput)
    else if (vStandardSG == "RightBottom") {
        while (getline < vSortInput > 0) {
            split($0, aTemporary, ":")
            if (vX == "null") {
                vX = aTemporary[1]
                vY = aTemporary[2]
                vHitCount = aTemporary[3]
            } else if (vX != "null") {
                vCurrentX = aTemporary[1]
                vCurrentY = aTemporary[2]
                vCurrentHitCount = aTemporary[3]
                if (vCurrentX >= vX && vCurrentY <= vY) {
                    vX = vCurrentX
                    vY = vCurrentY
                    vHitCount = vCurrentHitCount
                }
            }
        }
        print vX":"vY":"vHitCount > vSortOutput
    } else if (vStandardSG == "RightTop")
        system(vSORT" -r -n -t: -k1,2 "vSortInput" > "vSortOutput)
    else if (vStandardSG == "LeftTop") {
        while (getline < vSortInput > 0) {
            split($0, aTemporary, ":")
            if (vX == "null") {
                vX = aTemporary[1]
                vY = aTemporary[2]
                vHitCount = aTemporary[3]
            } else if (vX != "null") {
                vCurrentX = aTemporary[1]
                vCurrentY = aTemporary[2]
                vCurrentHitCount = aTemporary[3]
                if (vCurrentX <= vX && vCurrentY >= vY) {
                    vX = vCurrentX
                    vY = vCurrentY
                    vHitCount = vCurrentHitCount
                }
            }
        }
        print vX":"vY":"vHitCount > vSortOutput
    }
    FS = "\n" # フィールドセパレータはリターン
    RS = "" # レコードセパレータは空行
    close(vSortOutput)

    system(vAWK" -f nc2hplib.awk \
                 -f markup.awk "vTempDir"DRL_HIT.TMP > "vTempDir"MARKUP.TMP")
    system(vAWK" -v vInputFile="vMainFile \
               " -f nc2hplib.awk \
                 -f ncrpass1.awk "vTempDir"MARKUP.TMP > "vTempDir"NCRPASS1.TMP")
    system(vAWK" -f ncrpass2.awk "vTempDir"NCRPASS1.TMP > "vTempDir"NCRPASS2.TMP")
    system(vAWK" -f ncrpass3.awk "vTempDir"NCRPASS2.TMP > "vTempDir"NCRPASS3.TMP")
    system(vAWK" -f ncrpass4.awk "vTempDir"NCRPASS3.TMP > "vOutputDev)
}

function _ConvertNC(vTargetFile, vCatFlag, vFinalOutputFile) {
#
# 目的 : NCデータ変換
#
# 変数/配列/連想配列 : vTargetFile / メインファイル,合成ファイル
#                    : vCatFlag / 合成ファイル判定用フラグ
#                    : vFinalOutputFile / テンポラリ出力ファイル名
#                    : vErrorFlag / 処理変更用フラグ
#
    _MkField(vNCDir vTargetFile, vTempDir"MK_FIELD.TMP")
    system(vAWK" -v vDataType="vDataType \
               " -f nc2hplib.awk \
                 -f divide.awk "vTempDir"MK_FIELD.TMP")

    vErrorFlag = _Test(vTempDir"MAIN.TMP")

    if (vErrorFlag == -1) {
        system(vMV" "vTempDir"MK_FIELD.TMP "vTempDir"EXPAND_1.TMP")
    } else {
        system(vAWK" -v vDataType="vDataType \
                   " -f nc2hplib.awk \
                     -f expand.awk "vTempDir"MAIN.TMP > "vTempDir"EXPAND_1.TMP")
    }

    system(vAWK" -v vDataType="vDataType \
               " -f nc2hplib.awk \
                 -f drl_hit.awk "vTempDir"EXPAND_1.TMP")
    system(vAWK" -v vDataType="vDataType \
               " -v vCatFlag="vCatFlag \
               " -f nc2hplib.awk \
                 -f t_count.awk "vTempDir"DRL_HIT.TMP")
    system(vAWK" -v vInputFile="vTargetFile \
               " -v vCatFlag="vCatFlag \
               " -v vCatFile="vCatFile \
               " -v vPCBLayer="vPCBLayer \
               " -f nc2hplib.awk \
                 -f nc_main.awk "vTempDir"DRL_HIT.TMP > "vFinalOutputFile)
}

function _WBSDefine(A) {
#
# 目的 : ワークボードサイズ情報,その他をファイルに出力する
#
# 制限 : (たぶん)なし
#
# 変数/配列/連想配列 :
#
    print A > vTempDir"WBS.TMP"
    split(A, aTemporary, ":")
    vStandardSG = aTemporary[4]
    vWBSDefine = A # この変数はどこからも参照していない
    close(vTempDir"WBS.TMP")

    # 後始末
    _DeleteArray(aTemporary)
}

function _DivideTool(A) {
#
# 目的 : ツール情報をファイルに出力する
#
# 制限 : (たぶん)なし
#
# 変数/配列/連想配列 : vFieldCount / ツール個数
#                    : aTemporary[...] / split() が生成するテンポラリ配列
#
    vFieldCount = split(A, aTemporary, " ")
    for (i = 1; i <= vFieldCount; i++) {
        if (vMainFile != "" && vCatFile == "")
            print aTemporary[i] > vTempDir"MAINTOOL.TMP"
        else if (vMainFile != "" && vCatFile != "" && vCatFile != "null")
            print aTemporary[i] > vTempDir"CAT_TOOL.TMP"
    }
    close(vTempDir"MAINTOOL.TMP")
    close(vTempDir"CAT_TOOL.TMP")

    # 後始末
    _DeleteArray(aTemporary)
}

function _DataInitialize() {
#
# 目的 : すでに設定されている変数/配列/連想配列を初期化する
#
# 制限 : (たぶん)なし
#
    vErrorFlag = ""
    vDataType = ""
    vMainFile = ""
    vWBSDefine = ""
    vPCBLayer = ""
    vCatFile = ""
}

function _MkField(i, o) {
#
# 目的 : 書式を整える
#
    vFS = FS # フィールドセパレータを記憶
    vRS = RS # レコードセパレータを記憶
    FS = " " # フィールドセパレータをスペースに設定
    RS = "\n" # レコードセパレータを改行に設定
    split("A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z", str, ",")
    while (getline < i > 0) {
        gsub(/[ %]/, "")
        if (/^T[0-9]$/) gsub(/T/, "T0")
        for (n in str)
            gsub(str[n], " "str[n]"_")
        gsub(/^ /, "")
        if ($0 != "") print $0 > o
    }
    close(i)
    close(o)
    FS = vFS # フィールドセパレータを戻す
    RS = vRS # レコードセパレータを戻す
}

function _RmTempFiles() {
#
# 目的 : テンポラリファイルを削除する
#
    vRmFiles = ""
    vTempFiles = "CAT_INF.TMP, \
                  CAT_TOOL.TMP, \
                  DRL_TMP1.TMP, \
                  EXPAND_1.TMP, \
                  EXPAND_2.TMP, \
                  DRL_HIT.TMP, \
                  MAIN.TMP, \
                  MAINTOOL.TMP, \
                  MAIN_INF.TMP, \
                  MARKUP.TMP, \
                  MK_FIELD.TMP, \
                  MULTIPLE.TMP, \
                  NCRPASS1.TMP, \
                  NCRPASS2.TMP, \
                  NCRPASS3.TMP, \
                  ORIGIN.TMP, \
                  ORIGIN.TMP, \
                  SORT.TMP, \
                  WBS.TMP, \
                  T_HOLE.HP, \
                  N_T_HOLE.HP"
    gsub(/ /, "", vTempFiles)
    split(vTempFiles, TempFile, ",")
    for (i in TempFile) {
        vErrorFlag = _Test(vTempDir TempFile[i])
        if (vErrorFlag != -1) {
#            system(vRM" "vTempDir TempFile[i])
            vRmFiles = vRmFiles" "vTempDir TempFile[i]
        }
    }
    system(vRM vRmFiles)
    system(vRM " " vNCDir vMainFile)
    if (vCatFile != "null") system(vRM " " vNCDir vCatFile)
}
