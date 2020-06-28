#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# ユーザーインターフェイスモジュール/リリース3(AWK版)
#
#   目的 : 入力される個々のファイルに関するパラメータを決定する
#
#   制限 : 各サブルーチン(関数)の制限項目を参照の事
#
BEGIN {
    CatFlag = 0
    ToolCount = 0
    CatToolCount = 0
#    DataType = "NC"

    _TempDir()
    _ReadPenTable()
    _ReadWBSTable()

    for (;;) {
        system(vCLEAR) # 画面を消去する
        _DataType()
        _InputFile()
        _ToolCheck(MainFile)
        _WorkBoardSize()
        if (DataType == "NC") {
            _PCBLayer()
            _Cat()
        } else if (DataType == "NC_R")
            ;
        _ParameterCheck()
        _StartConvert()
    }
    exit
}

{}

END {
    _RmTempFiles()
}

function _PrintParameter() {
#
# 目的 : _ParameterCheck() の下請けサブルーチン
#        入力されたパラメータ(変数/配列/連想配列)を,書式を整えて出力する
#
# 制限 : (たぶん)なし
#
    system (vCLEAR) # 画面を消去する

    if (DataType == "NC") # 入力ファイルの種類は？
        Temporary = "NCデータ"
    else if (DataType == "NC_R")
        Temporary = "NCルーターデータ"

    print "1: 入力データ = "Temporary
    print "2: 入力ファイル名 = "MainFile # 入力ファイル名称は？
    print "3: ツール番号 ペン番号 ドリル径" # ToolDef[...] の表示
    for (i = 1; i <= ToolCount; i++) {
        split(ToolDef[i], _Temp, ":")
        printf("%3s%-11s%-9s%s\n", " ", _Temp[1], _Temp[2], _Temp[3])
    }

    if (DataType == "NC") { # ワークボードパラメータの表示
        split(WBSDefine, _Temp, ":")
        print "4: ワークボードサイズ = "_Temp[1]"mm * "_Temp[2]"mm" # ワークボードサイズは？
        if (_Temp[3] == 0) # スタックは？
            print _Space(3)"スタック = 通常"
        else if (_Temp[3] == 1)
            print _Space(3)"スタック = 両面板/180mm"
        else if (_Temp[3] == 2)
            print _Space(3)"スタック = 両面板/205mm"
        else if (_Temp[3] == 3)
            print _Space(3)"スタック = 多層板/"_Temp[4]"mm"
    } else if (DataType == "NC_R") {
        split(WBSDefine, _Temp, ":")
        print "4: ワークボードサイズ = "_Temp[1]"mm * "_Temp[2]"mm" # ワークボードサイズは？
        if (_Temp[3] == "Outside") # ガイド穴は？
            print _Space(2)"ガイド穴 = 外側"
        else if (_Temp[3] == "Inside")
            print _Space(2)"ガイド穴 = 内側"

        if (_Temp[4] == "LeftBottom") # 基準SGは？
            print _Space(2)"基準SG = 左下"
        else if (_Temp[4] == "RightBottom")
            print _Space(2)"基準SG = 右下"
        else if (_Temp[4] == "RightTop")
            print _Space(2)"基準SG = 右上"
        else if (_Temp[4] == "LeftTop")
            print _Space(2)"基準SG = 左上"

        if (_Temp[3] == "Outside") # 基準SGからのオフセットは？
            print _Space(2)"基準SGからのオフセット = 5mm ＊ 5mm"
        else if (_Temp[3] == "Inside") {
            if (_Temp[5] == 0 && _Temp[6] == 0) {
                print _Space(2)"基準SGからのオフセットは設定されていません."
                print _Space(2)"ワークボードは描画されません."
            } else if (_Temp[5] != 0 && _Temp[6] != 0)
                print _Space(2)"基準SGからのオフセット = "_Temp[5]"mm * "_Temp[6]"mm"
        }
    }

    if (DataType == "NC" && PCBLayer == "Dual") # 基板層数の表示
        print "5: 基板層数 = 2層"
    else if (DataType == "NC" && PCBLayer == "Multi")
        print "5: 基板層数 = 多層"

    if (DataType == "NC" && CatFile == "null") # 合成するファイルの表示
        print "6: 合成するファイル = 合成しない"
    else if (DataType == "NC" && CatFile != "null") {
        print "6: 合成するファイル = "CatFile
        print "7: 合成するファイルの"
        print "   ツール番号 ペン番号 ドリル径"
        for (i = 1; i <= CatToolCount; i++) {
            split(CatToolDef[i], _Temp, ":")
            gsub("_", "", _Temp[1])
            printf("%3s%-11s%-9s%s\n", " ", _Temp[1], _Temp[2], _Temp[3])
        }
    }

    print ""
    print "これでいいですか？"
    printf _Space(2)"(0)OK(Default) / (4)やり直し / (9)キャンセル : "
    getline Temporary < "/dev/stdin"
    return Temporary
}

function _ParameterCheck() {
#
# 目的 : 入力パラメータの確認を促し,結果を反映する
#
# 制限 : 入力は半角英数字のみ
#
# 変数/配列/連想配列 : Temporary / 一時変数
#
# 変更希望 : ツール修正を選択した場合に無条件で全部やり直しはつらい
#          : ツールを個別に修正できないか？
#
    for (;;) {
        Temporary = _PrintParameter() # 一回目のリターン
        if (Temporary == "")
            break
        else if (Temporary == 0)
            break
        else if (Temporary == 4) {
            printf "修正したい項目(番号)を選んで下さい : "
            getline Temporary < "/dev/stdin"
            if (Temporary == 1)
                _DataType()
            else if (Temporary == 2)
                _InputFile()
            else if (Temporary == 3) {
                ToolCount = 0
                _ToolCheck(MainFile)
            } else if (Temporary == 4)
                _WorkBoardSize()
            else if (Temporary == 5)
                _PCBLayer()
            else if (Temporary == 6) {
                for (item in CatToolDef) {
                    delete CatToolDef[item]
                }
                _Cat()
            } else if (Temporary == 7) {
                CatFlag = 1
                CatToolCount = 0
                _ToolCheck(CatFile)
            } else if (Temporary == 9)
                break
            else {
                _Error()
                continue
            }
            continue
        } else if (Temporary == 9)
            exit
        else {
            _Error()
            continue
        }
    }
}

function _FileNameCheck() {
#
# 目的 : _InputFile() & _Cat() の下請けサブルーチン
#      : ファイル名は MS-DOS の制限を守っているか？
#
# 制限 : 入力は半角英数字のみ
#
# 変数/配列/連想配列 : Temporary / 一時変数
#
    print ""
    for (;;) {
        printf "ファイル名は？ : "
        getline Temporary < "/dev/stdin"
        Temporary = toupper(Temporary)
        if (Temporary == "") {
            _Error()
            continue
        } else if (Temporary ~ /\ /) {
            _Error()
            continue
        } else if (length(Temporary) > 8) {
            _Error()
            continue
        } else if (Temporary ~ /[^A-Z0-9_-]/) {
            _Error()
            continue
        } else {
            return Temporary".DAT"
            break
        }
    }
}

function _Cat() {
#
# 目的 : 合成ファイル処理(NCデータのみ)
#
# 制限 : トータル文字数のみチェックしている
#      : ファイル名にはアルファベット/数字以外を使用してはいけない
#
# 変数/配列/連想配列 : Temporary / 一時変数
#                    : CatFlag / 合成ファイルの有無を示すフラグ
#                    : CatFile / 合成ファイル名
#
    print "\nほかのファイルと合成しますか？"
    printf _Space(2)"1 = 合成する / 9 = 合成しない(Default) : "
    getline Temporary < "/dev/stdin"

    for (;;) {
        if (Temporary == 1) { # 合成処理開始
            CatFlag = 1
            CatFile = _FileNameCheck()
            _ToolCheck(CatFile)
            break
        } else if (Temporary == 9 || Temporary == "") { # 合成しない処理開始
            CatFile = "null"
            for (item in CatToolDef) {
                delete CatToolDef[item]
            }
            break
        } else {
            _Error()
            continue
        }
    }
}

function _PCBLayer() {
#
# 目的 : 入力ファイルの基板層数を確認する
#
# 制限 : 入力は半角数字のみ
#
# 変数/配列/連想配列 : Temporary / 一時変数
#                    : PCBLayer / 基板層数
#
    for (;;) {
        print "\n基板層数"
        printf _Space(2)"基板層数を入力して下さい : "
        getline Temporary < "/dev/stdin"
        if (Temporary > 0 && Temporary < 3) {
            PCBLayer = "Dual"
            break
        } else if (Temporary > 2) {
            PCBLayer = "Multi"
            break
        } else {
            _Error()
            continue
        }
    }
}

function _StackTypeNC_R() {
#
# 目的 : _WorkBoardSize() の下請けサブルーチン
#      : ワークボードのスタックを決定する(for NCルーターデータ)
#
# 制限 : 入力は半角数字のみ
#      : 基準SGからの最大オフセットサイズは 0 < StandardSGOffset <= 840 と仮定する
#
# 変数/配列/連想配列 : Temporary / 一時変数
#                    : WBSDefine / WBSXLength:WBSYLength:GuideHole:StandardSG:StandardSGXOffset:StandardSGYOffset
#
    for (;;) { # ガイド穴はどこ？
        print ""
        print "ガイド穴はどこにありますか？"
        print _Space(2)"1: 外側 / 2: 内側"
        printf _Space(5)"番号を選んで下さい : "
        getline Temporary < "/dev/stdin"
        if (Temporary == 1) {
            GuideHole = "Outside"
            WBSDefine = WBSDefine":Outside"
            break
        } else if (Temporary == 2) {
            GuideHole = "Inside"
            WBSDefine = WBSDefine":Inside"
            break
        } else {
            _Error()
            continue
        }
    }

    for(;;) { # 基準SGはどこ？
        print ""
        print "基準SGはどこにありますか？"
        print _Space(2)"1 : 左下"
        print _Space(2)"2 : 右下"
        print _Space(2)"3 : 右上"
        print _Space(2)"4 : 左上"
        printf _Space(6)"番号を選んで下さい : "
        getline Temporary < "/dev/stdin"
        if (Temporary == 1) {
            WBSDefine = WBSDefine":LeftBottom"
            break
        } else if (Temporary == 2) {
            WBSDefine = WBSDefine":RightBottom"
            break
        } else if (Temporary == 3) {
            WBSDefine = WBSDefine":RightTop"
            break
        } else if (Temporary == 4) {
            WBSDefine = WBSDefine":LeftTop"
            break
        } else {
            _Error()
            continue
        }
    }

    if (GuideHole == "Outside") { # 基準SGからのオフセット値は？
        WBSDefine = WBSDefine":5:5"
    } else if (GuideHole == "Inside") {
        for (;;) {
            print "\n基準SGからのオフセット値"
            printf _Space(2)"X方向オフセット = "
            getline Temporary < "/dev/stdin"
            if (Temporary == "") {
                WBSDefine = WBSDefine":"0
                break
            } else if (Temporary > 0 || Temporary <= 840) {
                WBSDefine = WBSDefine":"Temporary
                break
            } else {
                _Error()
                continue
            }
        }

        for (;;) {
            printf _Space(2)"Y方向オフセット = "
            getline Temporary < "/dev/stdin"
            if (Temporary == "") {
                WBSDefine = WBSDefine":"0
                break
            } else if (Temporary > 0 || Temporary <= 840) {
                WBSDefine = WBSDefine":"Temporary
                break
            } else {
                _Error()
                continue
            }
        }
    }
}

function _StackTypeNC() {
#
# 目的 : _WorkBoardSize() の下請けサブルーチン
#      : ワークボードのスタックを決定する(for NCデータ)
#
# 制限 : 入力は半角数字のみ
#      : 最大スタックサイズは 0 < StackSize <= 840 と仮定する
#
# 変数/配列/連想配列 : Temporary / 一時変数
#                    : WBSDefine / WBSXLength:WBSYLength:WBSXOffset:WBSYOffset
#
    for (;;) {
        print ""
        printf "スタックを指示して下さい (1:通常(Default) 2:指定) : "
        getline Temporary < "/dev/stdin"
        if (Temporary == 1) {
            WBSDefine = WBSDefine":"0
            break
        } else if (Temporary == 2) {
            for (;;) {
                print ""
                print _Space(2)"スタックはユーザー指定です."
                print _Space(4)"1: 両面板/180mm"
                print _Space(4)"2: 両面板/205mm"
                print _Space(4)"3: 多層板"
                printf _Space(7)"番号を選んで下さい : "
                getline Temporary < "/dev/stdin"
                if (Temporary == 1) {
                    WBSDefine = WBSDefine":"1
                    break
                } else if (Temporary == 2) {
                    WBSDefine = WBSDefine":"2
                    break
                } else if (Temporary == 3) {
                    for (;;) {
                        print ""
                        printf _Space(6)"Y方向のオフセット値はどれぐらいですか？ : "
                        getline Temporary < "/dev/stdin"
                        if (Temporary > 0 && Temporary <= 840) {
                            WBSDefine = WBSDefine":3:"Temporary
                            break
                        } else {
                            _Error()
                            continue
                        }
                    }
                } else {
                    _Error()
                    continue
                }
                break
            }
        }
        break
    }
}

function _WBSUserDefine() {
#
# 目的 : _WorkBoardSize() の下請けサブルーチン
#        ユーザー定義ワークボードを生成する
#
# 制限 : ワークボード最大領域は 840mm * 840mm と仮定する
#      : 0 < WBSLength <= 840 と仮定する
#      : 入力は半角数字のみ
#
# 変数/配列/連想配列 : Temporary / 一時変数
#                    : WBSDefine / ワークボードサイズ,その他の情報
#
    print ""
    print _Space(2)"ユーザー定義が選ばれました."
    print ""
    print _Space(2)"ワークボードのXとYの寸法を指示して下さい."

    for (;;) { # ユーザー定義ワークボード / Xサイズ
        printf _Space(4)"X寸法 = "
        getline Temporary < "/dev/stdin"
        if (Temporary > 0) {
            WBSDefine = Temporary
            break
        } else {
            _Error()
            continue
        }
    }

    for (;;) { # ユーザー定義ワークボード / Yサイズ
        printf _Space(4)"Y寸法 = "
        getline Temporary < "/dev/stdin"
        if (Temporary > 0) {
            WBSDefine = WBSDefine":"Temporary
            break
        } else {
            _Error()
            continue
        }
    }
}

function _WBSDisplay() {
#
# 目的 : _WorkBoardSize() の下請けサブルーチン
#        _ReadWBSTable() が生成した配列の内容を表示する
#
# 制限 : (たぶん)なし
#
# 変数/配列/連想配列 : _Temp[...] / split() が生成するテンポラリ配列
#
    for (i = 1; i <= WBSTableCount; i++) {
        split(WBSDef[i], _Temp, ":")
        print _Space(2)i" : "_Temp[1]"mm * "_Temp[2]"mm"
    }
    print _Space(2)(WBSTableCount + 1)" : ワークボードはユーザーが定義する"
}

function _WorkBoardSize() {
#
# 目的 : 入力ファイルのワークボードサイズを決定する
#
# 制限 : あんまり厳密なエラー処理じゃない(と思う....)
#
# 変数/配列/連想配列 : Temporary / 一時変数
#                    : WBSDefine / ワークボードサイズ情報
#
    print "\nワークボードサイズ"

    _WBSDisplay()

    for (;;) {
        printf _Space(6)"番号を選んで下さい : "
        getline Temporary < "/dev/stdin"
        if (Temporary in WBSDef) {
            WBSDefine = WBSDef[Temporary]
            break
        } else if (Temporary == (WBSTableCount + 1)) {
            _WBSUserDefine()
            break
        } else {
            system(vCLEAR) # 画面を消去する
            _Error()
            _WBSDisplay()
            continue
        }
    }

    if (DataType == "NC")
        _StackTypeNC()
    else if (DataType == "NC_R")
        _StackTypeNC_R()
}

function _DrillSize() {
#
# 目的 : _ToolCheck(TargetFile) の下請けサブルーチン
#
# 制限 : ?????
#
# 変数/配列/連想配列 : Temporary / 一時変数
#                    : ToolDef[...] / 現在のツール発見数を添字とする配列(メインファイル)
#                    : CatToolDef[...] / 現在のツール発見数を添字とする配列(合成ファイル)
#
# 変更希望 : _PenColor() に準ずる
#
    for (;;) {
        printf _Space(4)"ドリル径は？ : "
        getline Temporary < "/dev/stdin"
        if (Temporary == "") {
            _Error()
            continue
        } else if (Temporary ~ /[^0-9.]/) {
            _Error()
            continue
        } else if (Temporary <= 0) {
            _Error()
            continue
        } else if (CatFlag == 0) {
            ToolDef[MaxToolCount] = ToolDefine":"Temporary
            ToolCount++
            break
        } else if (CatFlag == 1) {
            CatToolDef[MaxToolCount] = CatToolDefine":"Temporary
            CatToolCount++
            break
        }
    }
}

function _PenColor() {
#
# 目的 : _ToolCheck(TargetFile) の下請けサブルーチン
#
# 制限 : ?????
#
# 変数/配列/連想配列 : Temporary / 一時変数
#                    : ToolDefine / 現在処理中のツールに関する情報(メインファイル)
#                    : CatToolDefine / 現在処理中のツールに関する情報(合成ファイル)
#
# 変更希望 : メインファイルと合成ファイルの二元管理をやめて,一元管理したい
#          : 結果を return で上位サブルーチンに返す様に変更する
#          : ToolDefine と CatToolDefine の二元管理は正しいアプローチか？
#
    for (;;) {
        printf _Space(4)"何色にしますか？ : "
        getline Temporary < "/dev/stdin"
        if (Temporary == "") {
            if (CatFlag == 0) {
               ToolDefine = CurrentTool":"_Temp[1]
               break
            } else if (CatFlag == 1) {
               CatToolDefine = CurrentTool":"_Temp[1]
               break
            }
        } else if (Temporary in PenColorE) {
            split(PenColorE[Temporary],_Temp,":")
            if (CatFlag == 0) {
                ToolDefine = CurrentTool":"_Temp[1]
                break
            } else if (CatFlag == 1) {
                CatToolDefine = CurrentTool":"_Temp[1]
                break
            }
        } else if (Temporary in PenColorJ) {
            split(PenColorJ[Temporary],_Temp,":")
            if (CatFlag == 0) {
                ToolDefine = CurrentTool":"_Temp[1]
                break
            } else if (CatFlag == 1) {
                CatToolDefine = CurrentTool":"_Temp[1]
                break
            }
        } else if (Temporary in PenNumber) {
            split(PenNumber[Temporary],_Temp,":")
            if (CatFlag == 0) {
                ToolDefine = CurrentTool":"_Temp[1]
                break
            } else if (CatFlag == 1) {
                CatToolDefine = CurrentTool":"_Temp[1]
                break
            }
        } else {
            _Error()
            continue
        }
    }
}

function _ConvertToolFormat() {
#
# 目的 : _ToolChrck(TargetFile) の下請けサブルーチン
#
# 変数/配列/連想配列 : ToolFile / 処理用テンポラリファイル(使い回し)
#                    : _Temp[...] / split() が生成するテンポラリ配列
#
    ToolFile2 = vTempDir"T2.TMP"
    ToolFile3 = vTempDir"T3.TMP"
    ToolFile4 = vTempDir"T4.TMP"

    while (getline < ToolFile2 > 0) {
        if (NF == 1) {
            if (length($0) == 2) {
                gsub(/T/, "T0")
                print $0 > ToolFile3
            } else
                print $0 > ToolFile3
        }
    }
    close(ToolFile3)
    system(vSORT" -u "ToolFile3" > "ToolFile4)
}

function _ToolCheck(TargetFile) {
#
# 目的 : 入力ファイル中のツール毎にペン色/ドリル径を定義する
#
# 制限 : あんまり厳密なエラー処理じゃない(と思う)
#      : 入力ファイルには同じツールが複数出現しないと仮定している
#
# 変数/配列/連想配列 : TargetFile / サブルーチンに対する引数(入力ファイル名)
#                    : ToolFile / 入力ファイルに存在するすべてのツールを納めたファイル
#                    : PenTableCount / 今までに入力ファイルから発見したツールの数
#                    : MaxToolCount / 入力ファイルに含まれるツールの最大数
#                    : CurrentTool / 現在処理中のツール
#                    : _Temp[...] / split() が生成するテンポラリ配列
#                    : CatFlag / 合成ファイルの有無を示すフラグ
#
# 変更希望 : 入力ファイルに同じツールが複数出現した場合の処理は？(NCルーターデータ)
#
    PenTableCount = 1
    MaxToolCount = 1

    while (getline < TargetFile > 0) {
        if ($0 ~/^T[0-9]+$/)
            print > vTempDir"T2.TMP"
        else if ($0 ~/^O99$/)
            break
    }
    close(TargetFile)
    close(vTempDir"T2.TMP")

    _ConvertToolFormat()

    ToolFile = vTempDir"T4.TMP"
    while (getline < ToolFile > 0) {
        CurrentTool = $0
        if (PenTableCount > MaxPenNumber)
            PenTableCount = 1
        printf _Space(2)"ツール "CurrentTool" を見つけました"
        split(PenNumber[PenTableCount],_Temp,":")
        print " (現在のペン色 = "_Temp[3]")"

        _PenColor()
        _DrillSize()

        PenTableCount++
        MaxToolCount++
    }
    close(TargetFile)
    close(ToolFile)
    CatFlag = 0
}

function _InputFile() {
#
# 目的 : 入力ファイル名の確認
#
# 制限 : トータル文字数のみチェックしている
#      : ファイル名にはアルファベット/数字以外を使用してはいけない
#
# 変数/配列/連想配列 : MainFile / メインファイル
#
    MainFile = _FileNameCheck()
}

function _DataType() {
#
# 目的 : 入力ファイルの種別判定
#
# 制限 : オペレーターの入力を信じている
#      : 入力は半角数字のみ
#
# 変数/配列/連想配列 : Temporary / 一時変数
#                    : DataType / 入力データの型
#
    for (;;) {
        print "入力データ"
        print _Space(2)"1: NCデータ"
        print _Space(2)"2: NCルーターデータ"
        printf _Space(5)"番号を選んで下さい : "
        getline Temporary < "/dev/stdin"
        if (Temporary == "") {
            _Error()
            continue
        } else if (Temporary == 1) {
            DataType = "NC"
            break
        } else if (Temporary == 2) {
            DataType = "NC_R"
            break
        } else {
            _Error()
            continue
        }
    }
}

function _WBSInformation() {
#
# 目的 : _StartConvert() の下請けサブルーチン
#      : MainFile と PCBLayer の内容によって WBSDefine を分配する
#
# 制限 : (たぶん)なし
#
# 変数/配列/連想配列 : _Temp[...] / split() が生成するテンポラリ配列
#
# 変更希望 : うーーん！？
#
    if (DataType == "NC" && MainFile !~ /NT/) {
        split(WBSDefine, _Temp, ":")
        WBSXLength = _Temp[1]
        WBSYLength = _Temp[2]
        StackType = _Temp[3]
        if (StackType == 0) {
            if (PCBLayer == "Dual") {
                if (WBSYLength < 400) {
                    WBSXOffset = 4
                    WBSYOffset = 0
                } else if (WBSYLength >= 400) {
                    WBSXOffset = 4
                    WBSYOffset = 25
                }
            } else if (PCBLayer = "Multi") {
                if (WBSYLength <= 400) {
                    WBSXOffset = 5
                    WBSYOffset = (WBSYLength/2)
                } else if (WBSYLength > 400) {
                    WBSXOffset = 5
                    WBSYOffset = 205
                }
            }
        } else if (StackType == 1) {
            WBSXOffset = 4
            WBSYOffset = 0
        } else if (StackType == 2) {
            WBSXOffset = 4
            WBSYOffset = 25
        } else if (StackType == 3) {
            WBSXOffset = 5
            WBSYOffset = _Temp[4]
        }
        WBSDefine = "" # 一応初期化する
        WBSDefine = WBSXLength":"WBSYLength":"WBSXOffset":"WBSYOffset
    } else if (DataType == "NC_R")
        ;
}

function _StartConvert() {
#
# 目的 : パラメータ入力続行の問い合わせ
#
# 制限 : 入力は半角数字のみ
#
# 変数/配列/連想配列 : Temporary / 一時変数
#
    for (;;) {
        print "\nデータ変換を開始します"
        printf _Space(2)"(0)変換開始(Default) / (4)次のファイルを編集 / (9)変換せずに終了 : "
        getline Temporary < "/dev/stdin"
        if (Temporary == "" || Temporary == 0) {
            _FlashBuffer()
            exit
        } else if (Temporary == 4) {
            _FlashBuffer()
            break
        } else if (Temporary == 9) {
            exit
        } else {
            _Error()
            continue
        }
    }
}

function _FlashBuffer() {
#
# 目的 : 入力されたパラメータをファイルに落とす
#
# 制限 : (たぶん)なし
#
# 変数/配列/連想配列 : OutputFile / 出力ファイルハンドル
#
    OutputFile = vTempDir"NC2HPGL.TBL"
    if (DataType == "NC_R") {
        PCBLayer = "null"
        CatFile = "null"
    }

    print DataType > OutputFile
    print MainFile > OutputFile
    for (i = 1; i <= ToolCount; i++) {
        gsub(/T/, "T_", ToolDef[i])
        printf ToolDef[i] > OutputFile
        if (i < ToolCount) printf " " > OutputFile
    }
    printf "\n" > OutputFile
    ToolCount = 0
    _WBSInformation()
    print WBSDefine > OutputFile
    print PCBLayer > OutputFile
    print CatFile > OutputFile
    if (CatFile != "null") {
        for (i = 1; i <= CatToolCount; i++) {
            printf CatToolDef[i] > OutputFile
            if (i < CatToolCount) printf " " > OutputFile
        }
    } else if (CatFile == "null")
        printf "null" > OutputFile
    printf "\n\n" > OutputFile
    CatToolCount = 0
}

function _Error() {
#
# 目的 : オペレーターからの不正入力に対する一般エラーメッセージ
#
# 制限 : (たぶん)なし
#
    print "" > "/dev/stderr"
    print "ウムム.....！？" > "/dev/stderr"
    print "もう一度入力して下さい" > "/dev/stderr"
    print "" > "/dev/stderr"
}

function _ReadWBSTable() {
#
# 目的 : ワークボードサイズ定義ファイルを読み込んで配列を用意する
#
# 制限 : ワークボード定義ファイルはカレントディレクトリに存在しなければならない
#
# 変数/配列/連想配列 : WBSTableCount / ワークボードサイズ定義ファイルの最大登録数
#                    : WBSDef[...] / ワークボードサイズ登録順番を添字とする配列
#
    WBSTableCount = 0

    while (getline < "wbs.tbl" > 0) {
        if ($1 !~/\#/) {
            WBSTableCount++
            WBSDef[WBSTableCount] = $0
        }
    }
    close("wbs.tbl")
}

function _ReadPenTable() {
#
# 目的 : ペン定義ファイルを読み込んで配列/連想配列を用意する
#
# 制限 : ペン定義ファイルはカレントディレクトリに存在しなければならない
#
# 変数/配列/連想配列 : MaxPenNumber / ペン定義ファイルの最大登録数
#                    : _Temp[...] / split() が生成するテンポラリ配列
#                    : PenNumber[...] / ペン登録順番を添字とする配列
#                    : PenColorJ[...] / ペン色(日本語)を添字とする連想配列
#                    : PenColorE[...] / ペン色(英語)を添字とする連想配列
#
    MaxPenNumber = 0

    while (getline < "pen.tbl" > 0) {
        if ($0 !~/\#/) {
            MaxPenNumber++
            split($0, _Temp, ":")
            PenNumber[MaxPenNumber] = $0
            PenColorE[_Temp[2]] = $0
            PenColorJ[_Temp[3]] = $0
        }
    }
    close("pen.tbl")
}

function _Space(n) {
#
# 目的 : スペースをn個挿入する
#
    if (n == 0)
        return ("")
    else if (n == 1)
        return (" ")
    else
        return (" " _Space(n - 1))
}

function _RmTempFiles() {
#
# 目的 : テンポラリファイルを削除する
#
    vTempFiles = ToolFile2"," \
                 ToolFile3"," \
                 ToolFile4
    gsub(/ /, "", vTempFiles)
    split(vTempFiles, TempFile, ",")
    for (i in TempFile) {
        vErrorFlag = _Test(TempFile[i])
        if (vErrorFlag != -1)
            system(vRM" "TempFile[i])
    }
}
