#
# このプログラムはWATABE Eijiが独自に変更を加えてあります
# 開発環境: Cygwin-1.3.2, GNU Awk 3.0.4
#
# 目的 : NCルーターデータをHP-GL_1フォーマットに変換する
#           曲線移動
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
    else if ($0 == "G_28 X_0 Y_0 " || $1 == "G_100") # データ原点へジャンプ
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

function _CurveTrack_IJXY_Area4() {
#
# 目的 : _CurveTrack_IJXY() の下請けサブルーチン
#      : 扇始点/第四象眼
#
    if (TempX > 0 && TempY >= 0) { # 扇終点は第一象限
        if (TempY == 0) { # 扇終点Y長は無効
            Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
            Angle = (-1 * Angle)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        } else if (TempY != 0) { # 扇終点Y長は有効
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = ((-1 * Angle_IJ) + Angle_XY)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        }
    } else if (TempX <= 0 && TempY > 0) { # 扇終点は第二象限
        _ArcAngle(TempI, TempJ, TempX, TempY)
        Angle = ((-1 * Angle_IJ) + Angle_XY)
        if (PenFunctionFlag == "ClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
        else if (PenFunctionFlag == "CounterClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","Angle";"
    } else if (TempX < 0 && TempY <= 0) { # 扇終点は第三象限
        if (TempY == 0) { # 扇終点Y長は無効
            Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
            Angle = (180 - (-1 * Angle))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempY != 0) { # 扇終点Y長は有効
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = ((-1 * Angle_XY) - (-1 * Angle_IJ))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX >= 0 && TempY < 0) { # 扇終点は第四象限
        _ArcAngle(TempI, TempJ, TempX, TempY)
        if (TempI > TempX && TempJ > TempY) { # 扇始点は扇終点の上にある
            Angle = ((-1 * Angle_XY) - (-1 * Angle_IJ))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempI < TempX && TempJ < TempY) { # 扇始点は扇終点の下にある
            Angle = ((-1 * Angle_IJ) - (-1 * Angle_XY))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        }
    }
}

function _CurveTrack_IJXY_Area3() {
#
# 目的 : _CurveTrack_IJXY() の下請けサブルーチン
#      : 扇始点/第三象眼
#
    if (TempX > 0 && TempY >= 0) { # 扇終点は第一象限
        if (TempJ == 0 && TempY == 0) { # 扇始/終点Y長は無効
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)",-180;"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)",180;"
        } else if (TempJ != 0 && TempY == 0) { # 扇終点Y長のみ無効
            Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
            Angle = (180 + (-1 * Angle))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempJ == 0 && TempY != 0) { #>> 扇始点Y長のみ無効
            Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
            Angle = (180 - Angle)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempJ != 0 && TempX != 0) { # 扇始/終点Y長は有効
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = (360 - ((-1 * Angle_IJ) + Angle_XY))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX <= 0 && TempY > 0) { # 扇終点は第二象限
        if (TempJ != 0) { # 扇始点Y長は有効
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = (360 - ((-1 * Angle_IJ) + Angle_XY))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempJ == 0) { # 扇始点Y長は無効
            Angle = sprintf("%3.1f" , atan2(TempY , TempX) / PI * 180)
            Angle = (180 - Angle)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX < 0 && TempY == 0 && TempJ == 0) # 扇終点は第三象限,扇始/終点Y長は無効
        _StraightTrack()
    else if (TempX < 0 && TempY == 0 && TempJ < 0) { # 扇終点は第三象限,扇始点Y長のみ有効
        Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
        Angle = (180 - (-1 * Angle))
        if (PenFunctionFlag == "ClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
        else if (PenFunctionFlag == "CounterClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
    } else if (TempX < 0 && TempY < 0 && TempJ == 0) { # 扇終点は第三象限,扇終点Y長のみ有効
        Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
        Angle = (180 - (-1 * Angle))
        if (PenFunctionFlag == "ClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        else if (PenFunctionFlag == "CounterClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","Angle";"
    } else if (TempX < 0 && TempY < 0 && TempJ < 0) { # 扇終点は第三象限,扇始/終点は有効
        _ArcAngle(TempI, TempJ, TempX, TempY)
        if (TempI < TempX && TempJ > TempY) { # 扇始点は扇終点の上にある
            Angle = ((-1 * Angle_IJ) - (-1 * Angle_XY))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        } else if (TempI > TempX && TempJ < TempY) { # 扇始点は扇終点の下にある
            Angle = ((-1 * Angle_XY) - (-1 * Angle_IJ))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX >= 0 && TempY < 0) { # 扇終点は第四象限
        if (TempJ == 0) { # 扇始点Y長は無効
            Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
            Angle = (180 - (-1 * Angle))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        } else if (TempJ != 0) { # 扇始点Y長は有効
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = ((-1 * Angle_IJ) - (-1 * Angle_XY))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        }
    }
}

function _CurveTrack_IJXY_Area2() {
#
# 目的 : _CurveTrack_IJXY() の下請けサブルーチン
#      : 扇始点/第二象眼
#
    if (TempX > 0 && TempY >= 0) { # 扇終点は第一象限
        if (TempY == 0) { # 扇終点Y長は無効
            Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempY != 0) { # 扇終点Y長は有効
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = (Angle_IJ - Angle_XY)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX <= 0 && TempY > 0) { # 扇終点は第二象限
        _ArcAngle(TempI, TempJ, TempX, TempY)
        if (TempI < TempX && TempJ < TempY) { # 扇始点は扇終点の下にある
            Angle = (Angle_IJ - Angle_XY)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempI > TempX && TempJ > TempY) { # 扇始点は扇終点の上にある
            Angle = (Angle_XY - Angle_IJ)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        }
    } else if (TempX < 0 && TempY <= 0) { # 扇終点は第三象限
        if (TempY != 0) { # 扇終点Y長は有効
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = (Angle_IJ + (-1 * Angle_XY))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempY == 0) { # 扇終点Y長は無効
            Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
            Angle = (180 + Angle)
            if (Flag _PenFunction == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX >= 0 && TempY < 0) { # 扇終点は第四象限
        _ArcAngle(TempI, TempJ, TempX, TempY)
        Angle = (Angle_IJ + (-1 * Angle_XY))
        if (PenFunctionFlag == "ClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
        else if (PenFunctionFlag == "CounterClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
    }
}

function _CurveTrack_IJXY_Area1() {
#
# 目的 : _CurveTrack_IJXY() の下請けサブルーチン
#      : 扇始点/第一象眼
#
    if (TempX > 0 && TempY == 0 && TempJ == 0) { # 扇終点は第一象限,扇始/終点Y長は無効
        _StraightTrack()
    } else if (TempX > 0 && TempY == 0 && TempJ > 0) { # 扇終点は第一象限,扇始点Y長のみ有効
        Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
        if (PenFunctionFlag == "ClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
        else if (PenFunctionFlag == "CounterClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
    } else if (TempX > 0 && TempY > 0 && TempJ == 0) { # 扇終点は第一象限,扇終点Y長のみ有効
        Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
        if (PenFunctionFlag == "ClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
        else if (PenFunctionFlag == "CounterClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","Angle";"
    } else if (TempX > 0 && TempY > 0 && TempJ > 0) { # 扇終点は第一象限,扇始/終点Y長は有効
        _ArcAngle(TempI, TempJ, TempX, TempY)
        Angle = (Angle_IJ - Angle_XY)
        if (TempI < TempX && TempJ > TempY) { # 扇始点は扇終点の上にある
            Angle = (Angle_IJ - Angle_XY)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempI > TempX && TempJ < TempY) { # 扇始点は扇終点の下にある
            Angle = (Angle_XY - Angle_IJ)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        }
    } else if (TempX <= 0 && TempY > 0) { # 扇終点は第二象限
        if (TempJ == 0) { # 扇始点Y長は無効
            Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        } else if (TempJ != 0) { # 扇始点Y長は有効
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = (Angle_XY - Angle_IJ)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        }
    } else if (TempX < 0 && TempY <= 0) { # 扇終点は第三象限
        if (TempJ == 0 && TempY == 0) { # 扇始/終点Y長は無効
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)",-180;"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)",180;"
        } else if (TempJ != 0 && TempY == 0) { # 扇終点Y長のみ無効
            Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
            Angle = (180 - Angle)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        } else if (TempJ == 0 && TempY != 0) { #>> 扇始点Y長のみ無効
            Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
            Angle = (180 + (180 - (-1 * Angle)))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        } else if (TempJ != 0 && TempX != 0) { # 扇始/終点Y長は有効
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = (Angle_IJ + (-1 * Angle_XY))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX >= 0 && TempY < 0) { # 扇終点は第四象限
        if (TempJ == 0) { # 扇始点Y長は無効
            Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
            Angle = (-1 * Angle)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempJ != 0) { # 扇始点Y長は有効
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = (Angle_IJ + (-1 * Angle_XY))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    }
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
        _CurveTrack_IJXY_Area1()
    else if (TempI <= 0 && TempJ > 0) # 扇始点は第二象限
        _CurveTrack_IJXY_Area2()
    else if (TempI < 0 && TempJ <= 0) # 扇始点は第三象限
        _CurveTrack_IJXY_Area3()
    else if (TempI >= 0 && TempJ < 0) # 扇始点は第四象限
        _CurveTrack_IJXY_Area4()
    else
        print $0
}
