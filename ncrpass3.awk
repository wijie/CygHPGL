#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ړI : NC���[�^�[�f�[�^��HP-GL_1�t�H�[�}�b�g�ɕϊ�����
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
    else if ($0 == "G_28 X_0 Y_0" || $1 == "G_100") # �f�[�^���_�փW�����v
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
        ;
    else if (TempI <= 0 && TempJ > 0) # ��n�_�͑��ی�
        ;
    else if (TempI < 0 && TempJ <= 0) # ��n�_�͑�O�ی�
        ;
    else if (TempI >= 0 && TempJ < 0) # ��n�_�͑�l�ی�
        ;
    else
        _CurveTrack_RXY()
}

function _CurveTrack_RXY_CW() {
#
# �ړI : _CurveTrack_RXY() �̉������T�u���[�`��
#      : ���v���
#
    if (TempX > 0 && TempY >= 0) { # ��I�_�͑��ی�
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            Angle = (-1 * Angle)
            print "AR "(TempX / 0.025)",0,"Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180.0
            Angle = (-1 * Angle)
            print "AR "((TempX / 2) / 0.025)",0,"Angle";"
        }
    } else if (TempX <= 0 && TempY > 0) { # ��I�_�͑��ی�
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            Angle = (-1 * Angle)
            print "AR 0,"(TempY / 0.025)","Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180
            Angle = (-1 * Angle)
            print "AR 0,"((TempY / 2) / 0.025)","Angle";"
        }
    } else if (TempX < 0 && TempY <= 0) { # ��I�_�͑�O�ی�
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            # Angle = (-1 * Angle)
            print "AR "(TempX / 0.025)",0,"Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180
            Angle = (-1 * Angle)
            print "AR "((TempX / 2) / 0.025)",0,"Angle";"
        }
    } else if (TempX >= 0 && TempY < 0) { # ��I�_�͑�l�ی�
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
# �ړI : _CurveTrack_RXY() �̉������T�u���[�`��
#      : �����v���
#
    if (TempX > 0 && TempY >= 0) { # ��I�_�͑��ی�
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            print "AR 0,"(TempY / 0.025)","Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180.0
            print "AR 0,"((TempY / 2) / 0.025)","Angle";"
        }
    } else if (TempX <= 0 && TempY > 0) { # ��I�_�͑��ی�
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            print "AR "(TempX / 0.025)",0,"Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180
            print "AR "((TempX / 2) / 0.025)",0,"Angle";"
        }
    } else if (TempX < 0 && TempY <= 0) { # ��I�_�͑�O�ی�
        if (TempX != 0 && TempY != 0) {
            Angle = sprintf("%3.1f", atan2(TempY, 0) / PI * 180)
            Angle = (-1 * Angle)
            print "AR 0,"(TempY / 0.025)","Angle";"
        } else if (TempX == 0 || TempY == 0) {
            Angle = 180
            Angle = (-1 * Angle)
            print "AR 0,"((TempY / 2) / 0.025)","Angle";"
        }
    } else if (TempX >= 0 && TempY < 0) { # ��I�_�͑�l�ی�
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
# �ړI : �Ȑ��ړ����[�h(���a�ƃX�^�[�g/�G���h���W�������Ă���ꍇ�̉~��)
#
# ���� : ���v���~��(G02/G_02)�̐�S�p�x�͕��ɂȂ�
#      : �����v���~��(G03/G_03)�̐�S�p�x�͐��ɂȂ�
#
# ���ӊ��� : ����(�p)���� ���肪�Ƃ��[�[
#
    TempI = 0 # ��n�_X���W
    TempJ = 0 # ��n�_Y���W
    TempX = X # ��I�_X���W
    TempY = Y # ��I�_Y���W
    Angle = 0 # ��S�p�x

    if (PenFunctionFlag == "CounterClockWise") # �܂������v��肩��
        _CurveTrack_RXY_CCW()
    else if (PenFunctionFlag == "ClockWise") # ���Ɏ��v���
        _CurveTrack_RXY_CW()
}
