#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 目的 : NCルーターデータをHP-GL_1フォーマットに変換する
#
# 変数/配列/連想配列 :
#
BEGIN {
    PI = atan2(0, -1) # 円周率を定義
    PenModeFlag = "Up"
    PenFunctionFlag = "Straight"
}

{
    if ($0 ~/^$/) # カレント行は空行
        ;
    else if ($1 ~/T_/) # ツール発見
        ;
    else if ($0 == "G_28 X_0 Y_0" || $1 == "G_100") # データ原点へジャンプ
        ;
    else if ($NF ~/M_(05|07|12)/) # ヒットコード発見
        ;
    else { # ここから本番
        # 各変数を初期化
        I = 0
        J = 0
        R = 0
        X = 0
        Y = 0

        # フラグを定義する
        for (i = 1; i <= NF; i++) {
            if ($i ~/G_00/) {
                PenModeFlag = "Up"
                PenFunctionFlag = "Straight"
            } else if ($i ~/G_01/) {
                PenModeFlag = "Down"
                PenFunctionFlag = "Straight"
            } else if ($i ~/G_02/) {
                PenModeFlag = "Down"
                PenFunctionFlag = "ClockWise"
            } else if ($i ~/G_03/) {
                PenModeFlag = "Down"
                PenFunctionFlag = "CounterClockWise"
            } else if ($i ~/G_12/) {
                PenModeFlag = "Down"
                PenFunctionFlag = "Spiral"
            } else if ($i ~/G_14/) {
                PenModeFlag = "Down"
                PenFunctionFlag = "SquareSpiral"
            } else if ($i ~/M_04/)
                PenModeFlag = "Down"
            else if ($i ~/M_14/)
                PenModeFlag = "Up"
            else if ($i ~/I_/) {
                split($i, Temporary, "_")
                I = Temporary[2]
            } else if ($i ~/J_/) {
                split($i, Temporary, "_")
                J = Temporary[2]
            } else if ($i ~/R_/) {
                split($i, Temporary, "_")
                R = Temporary[2]
            } else if ($i ~/X_/) {
                split($i, Temporary, "_")
                X = Temporary[2]
            } else if ($i ~/Y_/) {
                split($i, Temporary, "_")
                Y = Temporary[2]
            }
        }

        # フラグに従い,サブルーチンを呼び出す
        if ($0 ~/I_/ || $0 ~/J_/ || $0 ~/R_/ || $0 ~/X_/ || $0 ~/Y_/) {
            if (PenModeFlag == "Up")
                ;
            else if (PenModeFlag == "Down") {
                if (PenFunctionFlag == "ClockWise")
                    _CurveTrack_IJXY()
                else if (PenFunctionFlag == "CounterClockWise")
                    _CurveTrack_IJXY()
                else if (PenFunctionFlag == "Spiral")
                    ;
                else if (PenFunctionFlag == "SquareSpiral")
                    ;
            } else
                print $0
        } else
            print $0
    }
}

END {}

function _ArcAngle(TempI, TempJ, TempX, TempY) {
#
# 目的 : _CurveTrack_IJXY() の下請けサブルーチン
#      : _Curve_TRack_RXY() の下請けサブルーチン
#      : 扇始点角度と扇終点角度を計算する
#
# 注意 : サブルーチン内で使用しているtemporary1(扇始点角度),temporary2(扇終点角度)は
#        グローバル変数であり,return値ではない
#
    Angle_IJ = 0
    Angle_XY = 0

    Angle_IJ = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
    Angle_XY = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
}

function _CurveTrack_IJXY() {
#
# 目的 : 曲線移動モード(中心座標とスタート/エンド座標が解っている場合の円弧)
#
# 注意 : 時計回り円弧(G02/G_02)の扇中心角度は負になる
#      : 反時計回り円弧(G03/G_03)の扇中心角度は正になる
#
# 感謝感謝 : 許 恩偵さん ありがとぉーー
#          : 小林 克美さん ありがとぉーー
#          : 佐藤(英)さん ありがとぉーー
#
    TempI = (-1 * I) # 扇始点X座標
    TempJ = (-1 * J) # 扇始点Y座標
    TempX = (X - I)  # 扇終点X座標
    TempY = (Y - J)  # 扇終点Y座標
    Angle = 0        # 扇中心角度

    print "PD;" # _CurveTrack_IJXY() は描画の時しか呼び出されない
    if (TempI > 0 && TempJ >= 0) # 扇始点は第一象限
        ;
    else if (TempI <= 0 && TempJ > 0) # 扇始点は第二象限
        ;
    else if (TempI < 0 && TempJ <= 0) # 扇始点は第三象限
        ;
    else if (TempI >= 0 && TempJ < 0) # 扇始点は第四象限
        ;
    else
        _CurveTrack_RXY()
}

function _CurveTrack_RXY_CW() {
#
# 目的 : _CurveTrack_RXY() の下請けサブルーチン
#      : 時計回り
#
    if (TempX > 0 && TempY >= 0) { # 扇終点は第一象限
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            Angle = (-1 * Angle)
            print "AR "(TempX / 0.025)",0,"Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180.0
            Angle = (-1 * Angle)
            print "AR "((TempX / 2) / 0.025)",0,"Angle";"
        }
    } else if (TempX <= 0 && TempY > 0) { # 扇終点は第二象限
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            Angle = (-1 * Angle)
            print "AR 0,"(TempY / 0.025)","Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180
            Angle = (-1 * Angle)
            print "AR 0,"((TempY / 2) / 0.025)","Angle";"
        }
    } else if (TempX < 0 && TempY <= 0) { # 扇終点は第三象限
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            # Angle = (-1 * Angle)
            print "AR "(TempX / 0.025)",0,"Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180
            Angle = (-1 * Angle)
            print "AR "((TempX / 2) / 0.025)",0,"Angle";"
        }
    } else if (TempX >= 0 && TempY < 0) { # 扇終点は第四象限
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            # Angle = (-1 * Angle)
            print "AR 0,"(TempY / 0.025)","Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180
            Angle = (-1 * Angle)
            print "AR 0,"((TempY / 2) / 0.025)","Angle";"
        }
    }
}

function _CurveTrack_RXY_CCW() {
#
# 目的 : _CurveTrack_RXY() の下請けサブルーチン
#      : 反時計回り
#
    if (TempX > 0 && TempY >= 0) { # 扇終点は第一象限
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            print "AR 0,"(TempY / 0.025)","Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180.0
            print "AR 0,"((TempY / 2) / 0.025)","Angle";"
        }
    } else if (TempX <= 0 && TempY > 0) { # 扇終点は第二象限
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            print "AR "(TempX / 0.025)",0,"Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180
            print "AR "((TempX / 2) / 0.025)",0,"Angle";"
        }
    } else if (TempX < 0 && TempY <= 0) { # 扇終点は第三象限
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            Angle = (-1 * Angle)
            print "AR 0,"(TempY / 0.025)","Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180
            Angle = (-1 * Angle)
            print "AR 0,"((TempY / 2) / 0.025)","Angle";"
        }
    } else if (TempX >= 0 && TempY < 0) { # 扇終点は第四象限
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            Angle = (-1 * Angle)
            print "AR "(TempX / 0.025)",0,"Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180
            Angle = (-1 * Angle)
            print "AR "((TempX / 2) / 0.025)",0,"Angle";"
        }
    }
}

function _CurveTrack_RXY() {
#
# 目的 : 曲線移動モード(半径とスタート/エンド座標が解っている場合の円弧)
#
# 注意 : 時計回り円弧(G02/G_02)の扇中心角度は負になる
#      : 反時計回り円弧(G03/G_03)の扇中心角度は正になる
#
# 感謝感謝 : 佐藤(英)さん ありがとぉーー
#
    TempI = 0 # 扇始点X座標
    TempJ = 0 # 扇始点Y座標
    TempX = X # 扇終点X座標
    TempY = Y # 扇終点Y座標
    Angle = 0 # 扇中心角度

    if (PenFunctionFlag == "CounterClockWise") # まず反時計回りから
        _CurveTrack_RXY_CCW()
    else if (PenFunctionFlag == "ClockWise") # つぎに時計回り
        _CurveTrack_RXY_CW()
}
