#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ړI : NC���[�^�[�f�[�^��HP-GL_1�t�H�[�}�b�g�ɕϊ�����
#           �Ȑ��ړ�
#
# �ϐ�/�z��/�A�z�z�� :
#
BEGIN {
    PI = atan2(0, -1) # �~�������`
    PenModeFlag = "Up"
    PenFunctionFlag = "Straight"
}

{
    if ($0 ~/^$/) # �J�����g�s�͋�s
        ;
    else if ($1 ~/T_/) # �c�[������
        ;
    else if ($0 == "G_28 X_0 Y_0 " || $1 == "G_100") # �f�[�^���_�փW�����v
        ;
    else if ($NF ~/M_(05|07|12)/) # �q�b�g�R�[�h����
        ;
    else { # ��������{��
        # �e�ϐ���������
        I = 0
        J = 0
        R = 0
        X = 0
        Y = 0

        # �t���O���`����
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

        # �t���O�ɏ]��,�T�u���[�`�����Ăяo��
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
# �ړI : _CurveTrack_IJXY() �̉������T�u���[�`��
#      : _Curve_TRack_RXY() �̉������T�u���[�`��
#      : ��n�_�p�x�Ɛ�I�_�p�x���v�Z����
#
# ���� : �T�u���[�`�����Ŏg�p���Ă���temporary1(��n�_�p�x),temporary2(��I�_�p�x)��
#        �O���[�o���ϐ��ł���,return�l�ł͂Ȃ�
#
    Angle_IJ = 0
    Angle_XY = 0

    Angle_IJ = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
    Angle_XY = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
}

function _CurveTrack_IJXY_Area4() {
#
# �ړI : _CurveTrack_IJXY() �̉������T�u���[�`��
#      : ��n�_/��l�ۊ�
#
    if (TempX > 0 && TempY >= 0) { # ��I�_�͑��ی�
        if (TempY == 0) { # ��I�_Y���͖���
            Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
            Angle = (-1 * Angle)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        } else if (TempY != 0) { # ��I�_Y���͗L��
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = ((-1 * Angle_IJ) + Angle_XY)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        }
    } else if (TempX <= 0 && TempY > 0) { # ��I�_�͑��ی�
        _ArcAngle(TempI, TempJ, TempX, TempY)
        Angle = ((-1 * Angle_IJ) + Angle_XY)
        if (PenFunctionFlag == "ClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
        else if (PenFunctionFlag == "CounterClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","Angle";"
    } else if (TempX < 0 && TempY <= 0) { # ��I�_�͑�O�ی�
        if (TempY == 0) { # ��I�_Y���͖���
            Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
            Angle = (180 - (-1 * Angle))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempY != 0) { # ��I�_Y���͗L��
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = ((-1 * Angle_XY) - (-1 * Angle_IJ))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX >= 0 && TempY < 0) { # ��I�_�͑�l�ی�
        _ArcAngle(TempI, TempJ, TempX, TempY)
        if (TempI > TempX && TempJ > TempY) { # ��n�_�͐�I�_�̏�ɂ���
            Angle = ((-1 * Angle_XY) - (-1 * Angle_IJ))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempI < TempX && TempJ < TempY) { # ��n�_�͐�I�_�̉��ɂ���
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
# �ړI : _CurveTrack_IJXY() �̉������T�u���[�`��
#      : ��n�_/��O�ۊ�
#
    if (TempX > 0 && TempY >= 0) { # ��I�_�͑��ی�
        if (TempJ == 0 && TempY == 0) { # ��n/�I�_Y���͖���
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)",-180;"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)",180;"
        } else if (TempJ != 0 && TempY == 0) { # ��I�_Y���̂ݖ���
            Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
            Angle = (180 + (-1 * Angle))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempJ == 0 && TempY != 0) { #>> ��n�_Y���̂ݖ���
            Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
            Angle = (180 - Angle)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempJ != 0 && TempX != 0) { # ��n/�I�_Y���͗L��
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = (360 - ((-1 * Angle_IJ) + Angle_XY))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX <= 0 && TempY > 0) { # ��I�_�͑��ی�
        if (TempJ != 0) { # ��n�_Y���͗L��
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = (360 - ((-1 * Angle_IJ) + Angle_XY))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempJ == 0) { # ��n�_Y���͖���
            Angle = sprintf("%3.1f" , atan2(TempY , TempX) / PI * 180)
            Angle = (180 - Angle)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX < 0 && TempY == 0 && TempJ == 0) # ��I�_�͑�O�ی�,��n/�I�_Y���͖���
        _StraightTrack()
    else if (TempX < 0 && TempY == 0 && TempJ < 0) { # ��I�_�͑�O�ی�,��n�_Y���̂ݗL��
        Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
        Angle = (180 - (-1 * Angle))
        if (PenFunctionFlag == "ClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
        else if (PenFunctionFlag == "CounterClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
    } else if (TempX < 0 && TempY < 0 && TempJ == 0) { # ��I�_�͑�O�ی�,��I�_Y���̂ݗL��
        Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
        Angle = (180 - (-1 * Angle))
        if (PenFunctionFlag == "ClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        else if (PenFunctionFlag == "CounterClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","Angle";"
    } else if (TempX < 0 && TempY < 0 && TempJ < 0) { # ��I�_�͑�O�ی�,��n/�I�_�͗L��
        _ArcAngle(TempI, TempJ, TempX, TempY)
        if (TempI < TempX && TempJ > TempY) { # ��n�_�͐�I�_�̏�ɂ���
            Angle = ((-1 * Angle_IJ) - (-1 * Angle_XY))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        } else if (TempI > TempX && TempJ < TempY) { # ��n�_�͐�I�_�̉��ɂ���
            Angle = ((-1 * Angle_XY) - (-1 * Angle_IJ))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX >= 0 && TempY < 0) { # ��I�_�͑�l�ی�
        if (TempJ == 0) { # ��n�_Y���͖���
            Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
            Angle = (180 - (-1 * Angle))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        } else if (TempJ != 0) { # ��n�_Y���͗L��
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
# �ړI : _CurveTrack_IJXY() �̉������T�u���[�`��
#      : ��n�_/���ۊ�
#
    if (TempX > 0 && TempY >= 0) { # ��I�_�͑��ی�
        if (TempY == 0) { # ��I�_Y���͖���
            Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempY != 0) { # ��I�_Y���͗L��
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = (Angle_IJ - Angle_XY)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX <= 0 && TempY > 0) { # ��I�_�͑��ی�
        _ArcAngle(TempI, TempJ, TempX, TempY)
        if (TempI < TempX && TempJ < TempY) { # ��n�_�͐�I�_�̉��ɂ���
            Angle = (Angle_IJ - Angle_XY)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempI > TempX && TempJ > TempY) { # ��n�_�͐�I�_�̏�ɂ���
            Angle = (Angle_XY - Angle_IJ)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        }
    } else if (TempX < 0 && TempY <= 0) { # ��I�_�͑�O�ی�
        if (TempY != 0) { # ��I�_Y���͗L��
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = (Angle_IJ + (-1 * Angle_XY))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempY == 0) { # ��I�_Y���͖���
            Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
            Angle = (180 + Angle)
            if (Flag _PenFunction == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX >= 0 && TempY < 0) { # ��I�_�͑�l�ی�
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
# �ړI : _CurveTrack_IJXY() �̉������T�u���[�`��
#      : ��n�_/���ۊ�
#
    if (TempX > 0 && TempY == 0 && TempJ == 0) { # ��I�_�͑��ی�,��n/�I�_Y���͖���
        _StraightTrack()
    } else if (TempX > 0 && TempY == 0 && TempJ > 0) { # ��I�_�͑��ی�,��n�_Y���̂ݗL��
        Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
        if (PenFunctionFlag == "ClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
        else if (PenFunctionFlag == "CounterClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
    } else if (TempX > 0 && TempY > 0 && TempJ == 0) { # ��I�_�͑��ی�,��I�_Y���̂ݗL��
        Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
        if (PenFunctionFlag == "ClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
        else if (PenFunctionFlag == "CounterClockWise")
            print "AR "(I / 0.025)","(J / 0.025)","Angle";"
    } else if (TempX > 0 && TempY > 0 && TempJ > 0) { # ��I�_�͑��ی�,��n/�I�_Y���͗L��
        _ArcAngle(TempI, TempJ, TempX, TempY)
        Angle = (Angle_IJ - Angle_XY)
        if (TempI < TempX && TempJ > TempY) { # ��n�_�͐�I�_�̏�ɂ���
            Angle = (Angle_IJ - Angle_XY)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempI > TempX && TempJ < TempY) { # ��n�_�͐�I�_�̉��ɂ���
            Angle = (Angle_XY - Angle_IJ)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        }
    } else if (TempX <= 0 && TempY > 0) { # ��I�_�͑��ی�
        if (TempJ == 0) { # ��n�_Y���͖���
            Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        } else if (TempJ != 0) { # ��n�_Y���͗L��
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = (Angle_XY - Angle_IJ)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        }
    } else if (TempX < 0 && TempY <= 0) { # ��I�_�͑�O�ی�
        if (TempJ == 0 && TempY == 0) { # ��n/�I�_Y���͖���
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)",-180;"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)",180;"
        } else if (TempJ != 0 && TempY == 0) { # ��I�_Y���̂ݖ���
            Angle = sprintf("%3.1f", atan2(TempJ, TempI) / PI * 180)
            Angle = (180 - Angle)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        } else if (TempJ == 0 && TempY != 0) { #>> ��n�_Y���̂ݖ���
            Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
            Angle = (180 + (180 - (-1 * Angle)))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * (360 - Angle))";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","Angle";"
        } else if (TempJ != 0 && TempX != 0) { # ��n/�I�_Y���͗L��
            _ArcAngle(TempI, TempJ, TempX, TempY)
            Angle = (Angle_IJ + (-1 * Angle_XY))
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        }
    } else if (TempX >= 0 && TempY < 0) { # ��I�_�͑�l�ی�
        if (TempJ == 0) { # ��n�_Y���͖���
            Angle = sprintf("%3.1f", atan2(TempY, TempX) / PI * 180)
            Angle = (-1 * Angle)
            if (PenFunctionFlag == "ClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(-1 * Angle)";"
            else if (PenFunctionFlag == "CounterClockWise")
                print "AR "(I / 0.025)","(J / 0.025)","(360 - Angle)";"
        } else if (TempJ != 0) { # ��n�_Y���͗L��
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
# �ړI : �Ȑ��ړ����[�h(���S���W�ƃX�^�[�g/�G���h���W�������Ă���ꍇ�̉~��)
#
# ���� : ���v���~��(G02/G_02)�̐�S�p�x�͕��ɂȂ�
#      : �����v���~��(G03/G_03)�̐�S�p�x�͐��ɂȂ�
#
# ���ӊ��� : �� ���コ�� ���肪�Ƃ��[�[
#          : ���� �������� ���肪�Ƃ��[�[
#          : ����(�p)���� ���肪�Ƃ��[�[
#
    TempI = (-1 * I) # ��n�_X���W
    TempJ = (-1 * J) # ��n�_Y���W
    TempX = (X - I)  # ��I�_X���W
    TempY = (Y - J)  # ��I�_Y���W
    Angle = 0        # ��S�p�x

    print "PD;" # _CurveTrack_IJXY() �͕`��̎������Ăяo����Ȃ�
    if (TempI > 0 && TempJ >= 0) # ��n�_�͑��ی�
        _CurveTrack_IJXY_Area1()
    else if (TempI <= 0 && TempJ > 0) # ��n�_�͑��ی�
        _CurveTrack_IJXY_Area2()
    else if (TempI < 0 && TempJ <= 0) # ��n�_�͑�O�ی�
        _CurveTrack_IJXY_Area3()
    else if (TempI >= 0 && TempJ < 0) # ��n�_�͑�l�ی�
        _CurveTrack_IJXY_Area4()
    else
        print $0
}
