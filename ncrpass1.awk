#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ړI : NC���[�^�[�f�[�^��HP-GL_1�t�H�[�}�b�g�ɕϊ�����
#           �����ړ�,�y���I��,���[�N�{�[�h�`��,�f�[�^���_
#           �w�b�_���,���J��,�^�~�ړ�,�X�p�C�����ړ�
#
# �ϐ�/�z�� :
#
# ���� : HPGL-1_format ��1�P��(�v���b�^���j�b�g)��0.025mm�ł���
#      : A1�T�C�Y�� 840mm * 594mm �ł���
#      : HP-7586B �̕`��͈͂� (-420 , -297) ���� (420 , 297) �ł���
#
BEGIN {
    # �ϐ���������
    vPI = atan2(0, -1)
    fPenMode = "Up"
    fPenFunction = "Straight"

    # �O����
    _TempDir() # �e���|�����f�B���N�g���̊m�F
    vDataOrigin = _ReadWBSInformation() # ���̓f�[�^���_�̒�`
    _ReadToolInformation()

    # �w�b�_�[������
    _MakeHeader()
}

{
    if ($0 ~/^$/) # �J�����g�s�͋�s
        next
    else if ($1 != "HPGL") {
        if ($1 ~/T_/) { # �c�[������
            _GetTool($0)
            print "HPGL SP "vCurrentPenNumber";"
        } else if ($0 == "G_28 X_0 Y_0 " || $1 == "G_100") # �f�[�^���_�փW�����v
            print vDataOrigin
        else if ($1 == "mk_wbs") { # ���[�N�{�[�h����
            if (vStandardSGXOffset == 0 && vStandardSGYOffset == 0)
                ;
            else
                _MakeWBS()
        } else { # ��������{��
            _MakeIJRXY() # �t���O,�ϐ�����������
            _CallFunction() # �t���O,�ϐ��Ɋ�Â�,�K�؂ȃT�u���[�`�����Ăяo��
        }
    } else
        print $0
}

END {}

function _Spiral(A) {
#
# �ړI : _CallFunction() �̉������T�u���[�`��
#      : ���� A �Ŏw�肳���`��ł̃X�p�C�����̋ߎ�
#
# �ϐ�/�z�� :
#
    if (A == "Spiral") { # �ۃX�p�C����
        SpiralXLength = (((vI - 0.2) * 2) / 0.025) # �ۃX�p�C����/���a����
        print "HPGL CI "SpiralXLength";"
        print "HPGL PU "(-1 * (SpiralXLength / 2))","(SpiralXLength / 2)";"
        print "HPGL PD "(SpiralXLength)","(-1 * SpiralXLength)";"
        print "HPGL PU 0,"(SpiralXLength)";"
        print "HPGL PD "(-1 * SpiralXLength)","(-1 * SpiralXLength)";"
        print "HPGL PU "(SpiralXLength / 2)","(SpiralXLength / 2)";"
    }
    if (A == "SquareSpiral") { # �p�X�p�C����
        SpiralXLength = ((vX / 2) / 0.025) # �p�X�p�C����/X������
        SpiralYLength = ((vY / 2) / 0.025) # �p�X�p�C����/Y������
        print "HPGL PU "(-1 * (SpiralXLength / 2))","(-1 * (SpiralYLength / 2))";" # �p�X�p�C����/�f�[�^�o�͊J�n
        print "HPGL PD "SpiralXLength",0;"
        print "HPGL PD 0,"SpiralYLength";"
        print "HPGL PD "(-1 * (SpiralXLength))",0;"
        print "HPGL PD 0,"(-1 * (SpiralYLength))";"
        print "HPGL PD "SpiralXLength","SpiralYLength";"
        print "HPGL PU "(-1 * SpiralXLength)",0;"
        print "HPGL PD "SpiralXLength","(-1 * SpiralYLength)";"
        print "HPGL PU "((-1 * SpiralXLength) / 2)","(SpiralYLength / 2)";" # �p�X�p�C����/�f�[�^�o�͏I��
    }
}

function _CircleTrack() {
#
# �ړI : _CallFunction() �̉������T�u���[�`��
#      : �^�~�ړ����[�h
#
    if (vCurrentI == "null") { # �����ړ��ł̐^�~���[�h
        if (vJ < 0) {
            print "HPGL PU 0,"((-1 * vJ) / 0.025)";"
            print "HPGL CI "((-1 * vJ) / 0.025)";"
            print "HPGL PU 0,"(vJ / 0.025)";"
        } else {
            print "HPGL PU 0,"(vJ / 0.025)";"
            print "HPGL CI "(vJ / 0.025)";"
            print "HPGL PU 0,"((-1 * vJ) / 0.025)";"
        }
    }
    if (vCurrentJ == "null") { # �����ړ��ł̐^�~���[�h
        if (vI < 0) {
            print "HPGL PU "((-1 * vI) / 0.025)",0;"
            print "HPGL CI "((-1 * vI) / 0.025)";"
            print "HPGL PU "(vI / 0.025)",0;"
        } else {
            print "HPGL PU "(vI / 0.025)",0;"
            print "HPGL CI "(vI / 0.025)";"
            print "HPGL PU "((-1 * vI) / 0.025)",0;"
        }
    }
}

function _StraightTrack(A) {
#
# �ړI : �����ړ����[�h
#
    if (A == "Up") {print "HPGL PU "(vX / 0.025)","(vY / 0.025)";"} # �`�悵�Ȃ��ꍇ�̏���
    if (A == "Down") {print "HPGL PD "(vX / 0.025)","(vY / 0.025)";"} # �`�悷��ꍇ�̏���
}

function _Hit() {
#
# �ړI : ���J�����ߏ���
#
    print "HPGL PU "(vX / 0.025)","(vY / 0.025)";"
    print "HPGL CI "((vCurrentToolSize / 2) / 0.025)";"
}

function _CallFunction() {
#
# �ړI : �J�����g�s��, _MakeIJRXY() �����������t���O�ƕϐ��Ɋ�Â�,�K�؂ȃT�u���[�`�����Ăяo��
#      : �J�����g�s�ŏI�t�B�[���h���q�b�g���߂Ȃ� _Hit() ���Ăяo��
#
    # �����J�n
    if ($NF ~/M_(05|07|12)/) # ���J������
        _Hit()
    else if ($0 ~/I_/ || $0 ~/J_/ || $0 ~/R_/ || $0 ~/X_/ || $0 ~/Y_/) { # ���̔���͕K�v���H
        if (fPenMode == "Up") # �`�悵�Ȃ��ꍇ�̏���
            _StraightTrack(fPenMode)
        else if (fPenMode == "Down") { # �`�悷��ꍇ�̏���
            if (fPenFunction == "Straight")
                _StraightTrack(fPenMode)
            else if (fPenFunction != "Spiral" && \
                     vCurrentX == "null" && \
                     vCurrentY == "null" && \
                     vCurrentR == "null")
                _CircleTrack()
            else if (vCurrentR == "null" && fPenFunction == "CW")
                print $0
            else if (vCurrentR == "null" && fPenFunction == "CCW")
                print $0
            else if (vCurrentR != "null" && fPenFunction == "CW")
                print $0
            else if (vCurrentR != "null" && fPenFunction == "CCW")
                print $0
            else if (fPenFunction == "Spiral")
                _Spiral(fPenFunction)
            else if (fPenFunction == "SquareSpiral")
                _Spiral(fPenFunction)
        }
    }
}

function _MakeIJRXY() {
#
# �ړI : �J�����g�s�𕪉�����,���̃X�e�b�v�ׂ̈̏���������
#
# ���� : _CallFunction() �Ƒ΂̃T�u���[�`��
#
    # �ϐ���������
    vCurrentI = vCurrentJ = vCurrentR = vCurrentX = vCurrentY = "null"
    vI = vJ = vR = vX = vY = 0

    # �t���O,�ϐ����`����
    for (i = 1; i <= NF; i++) {
        if ($i == "G_00") {
            fPenMode = "Up"
            fPenFunction = "Straight"
        } else if ($i == "G_01") {
            fPenMode = "Down"
            fPenFunction = "Straight"
        } else if ($i == "G_02") {
            fPenMode = "Down"
            fPenFunction = "CW"
        } else if ($i == "G_03") {
            fPenMode = "Down"
            fPenFunction = "CCW"
        } else if ($i == "G_12") {
            fPenMode = "Down"
            fPenFunction = "Spiral"
        } else if ($i == "G_14") {
            fPenMode = "Down"
            fPenFunction = "SquareSpiral"
        } else if ($i == "M_04")
            fPenMode = "Down"
        else if ($i == "M_14")
            fPenMode = "Up"
        else if ($i ~/I_/) {
            split($i, aTemporary, "_")
            vCurrentI = aTemporary[2]
        } else if ($i ~/J_/) {
            split($i, aTemporary, "_")
            vCurrentJ = aTemporary[2]
        } else if ($i ~/R_/) {
            split($i, aTemporary, "_")
            vCurrentR = aTemporary[2]
        } else if ($i ~/X_/) {
            split($i, aTemporary, "_")
            vCurrentX = aTemporary[2]
        } else if ($i ~/Y_/) {
            split($i, aTemporary, "_")
            vCurrentY = aTemporary[2]
        }
    }

    # �e�T�u���[�`�������W�l�Ƃ��ė��p����ϐ�����������
    if (vCurrentI != "null") {vI = vCurrentI}
    if (vCurrentJ != "null") {vJ = vCurrentJ}
    if (vCurrentR != "null") {vR = vCurrentR}
    if (vCurrentX != "null") {vX = vCurrentX}
    if (vCurrentY != "null") {vY = vCurrentY}
}

function _LeftTop(A) {
#
# �ړI : _MakeWBS() �̉������T�u���[�`��
#      : ���[�N�{�[�h�`��(�O�K�C�h/����)
#
# �ϐ�/�z�� :
#
    print ""
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(vStandardSGXOffset / 0.025)","(vStandardSGYOffset / 0.025)";"
    print "HPGL PU "(-1 * (5 / 0.025))","(5 / 0.025)";"
    print "HPGL PD 0,"(-1 * (vWBSYLength / 0.025))";"
    print "HPGL PD "(vWBSXLength / 0.025)",0;"
    print "HPGL PD 0,"(vWBSYLength / 0.025)";"
    print "HPGL PD "(-1 * (vWBSXLength / 0.025))",0;"
    print "HPGL PU "(5 / 0.025)","(-1 * (5 / 0.025))";"
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(-1 * (vStandardSGXOffset / 0.025))","(-1 * (vStandardSGYOffset / 0.025))";"
    print ""
}

function _RightTop(A) {
#
# �ړI : _MakeWBS() �̉������T�u���[�`��
#      : ���[�N�{�[�h�`��(�O�K�C�h/�E��)
#
# �ϐ�/�z��/�A�z�z�� :
#
    print ""
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(vStandardSGXOffset / 0.025)","(vStandardSGYOffset / 0.025)";"
    print "HPGL PU "(5 / 0.025)","(5 / 0.025)";"
    print "HPGL PD "(-1 * (vWBSXLength / 0.025))",0;"
    print "HPGL PD 0,"(-1 * (vWBSYLength / 0.025))";"
    print "HPGL PD "(vWBSXLength / 0.025)",0;"
    print "HPGL PD 0,"(vWBSYLength / 0.025)";"
    print "HPGL PU "(-1 * (5 / 0.025))","(-1 * (5 / 0.025))";"
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(-1 * (vStandardSGXOffset / 0.025))","(-1 * (vStandardSGYOffset / 0.025))";"
    print ""
}

function _RightBottom(A) {
#
# �ړI : _MakeWBS() �̉������T�u���[�`��
#      : ���[�N�{�[�h�`��(�O�K�C�h/�E��)
#
# �ϐ�/�z��/�A�z�z�� :
#
    print ""
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(vStandardSGXOffset / 0.025)","(vStandardSGYOffset / 0.025)";"
    print "HPGL PU "(5 / 0.025)","(-1 * (5 / 0.025))";"
    print "HPGL PD 0,"(vWBSYLength / 0.025)";"
    print "HPGL PD "(-1 * (vWBSXLength / 0.025))",0;"
    print "HPGL PD 0,"(-1 * (vWBSYLength / 0.025))";"
    print "HPGL PD "(vWBSXLength / 0.025)",0;"
    print "HPGL PU "(-1 * (5 / 0.025))","(5 / 0.025)";"
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(-1 * (vStandardSGXOffset / 0.025))","(-1 * (vStandardSGYOffset / 0.025))";"
    print ""
}

function _LeftBottom(A) {
#
# �ړI : _MakeWBS() �̉������T�u���[�`��
#      : ���[�N�{�[�h�`��(�O�K�C�h/����)
#
# �ϐ�/�z��/�A�z�z�� :
#
    print ""
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(vStandardSGXOffset / 0.025)","(vStandardSGYOffset / 0.025)";"
    print "HPGL PU "(-1 * (5 / 0.025))","(-1 * (5 / 0.025))";"
    print "HPGL PD "(vWBSXLength / 0.025)",0;"
    print "HPGL PD 0,"(vWBSYLength / 0.025)";"
    print "HPGL PD "(-1 * (vWBSXLength / 0.025))",0;"
    print "HPGL PD 0,"(-1 * (vWBSYLength / 0.025))";"
    print "HPGL PU "(5 / 0.025)","(5 / 0.025)";"
    if (A == "Outside")
        ;
    else if (A == "Inside")
        print "HPGL PU "(-1 * (vStandardSGXOffset / 0.025))","(-1 * (vStandardSGYOffset / 0.025))";"
    print ""
}

function _MakeWBS() {
#
# �ړI : ���[�N�{�[�h�𐶐�����
#
# �ϐ�/�z��/�A�z�z�� :
#
    if (vGuideHole == "Outside") {
        if (vStandardSG == "LeftBottom")
            _LeftBottom(vGuideHole)
        else if (vStandardSG == "RightBottom")
            _RightBottom(vGuideHole)
        else if (vStandardSG == "RightTop")
            _RightTop(vGuideHole)
        else if (vStandardSG == "LeftTop")
            _LeftTop(vGuideHole)
    } else if (vGuideHole == "Inside") {
        if (vStandardSG == "LeftBottom")
            _LeftBottom(vGuideHole)
        else if (vStandardSG == "RightBottom")
            _RightBottom(vGuideHole)
        else if (vStandardSG == "RightTop")
            _RightTop(vGuideHole)
        else if (vStandardSG == "LeftTop")
            _LeftTop(vGuideHole)
    }
}

function _GetTool(A) {
#
# �ړI : ���� A �Ŏw�肳�ꂽ�f�[�^����c�[���𐶐�����
#      : �c�[���ԍ�,�c�[���T�C�Y�𐶐�����
#
# �ϐ�/�z�� : vCurrentPenNumber / ���ݑI������Ă���c�[����`�悷��ׂ̃y���ԍ�
#           : vCurrentToolSize / ���ݑI������Ă���c�[���̒��a
#
# ���� : _ReadToolInformation() �Ɉˑ�����
#
    vToolInformation = aToolInformation[A] # _ReadToolInformation() �����������z�񂩂�
    split(vToolInformation, aTemporary, ":") # �c�[���ԍ�,�c�[���T�C�Y�����o��        
    vCurrentPenNumber = aTemporary[1]
    vCurrentToolSize = aTemporary[2]
}

function _MakeHeader() {
#
# �ړI : HP_GL_1�f�[�^�̃w�b�_�[���𐶐�����
#      : �f�[�^���_�܂ŃW�����v����
#      : �t�@�C����,�c�[�������o�͂���
#
# ���� : �t�@�C�����̓��[�N�{�[�h���_����6.35mm�������ӏ��ɐ�������
#      : �t�@�C�����͕�����3cm/��������4cm(���ׂđ啶���̏ꍇ)�ŕ`�悷��
#      : �c�[�����̓t�@�C��������5.08mm�������ӏ����琶������
#      : �c�[�����͕�����1.5cm/��������2cm(���ׂđ啶���̏ꍇ)�ŕ`�悷��
#
    print "HPGL DF;PR;PU;" # HPGL�f�[�^�w�b�_�[�o��
    print vDataOrigin # �f�[�^���_�܂ŃW�����v
    print "HPGL SP 1;" # �t�@�C����,�c�[�����o�͂��J�n
    print "HPGL PU 0,"(-1 * (6.35 / 0.025))";"
    print "HPGL SI.30,.40;LB"vInputFile"" # �t�@�C�����o��

    vStepDownFlag = 1 # �c�[�����o�͂��J�n
    while (getline < vToolInformationFile > 0) { # ���[�v�I���Ńc�[�����o�͏I��
        split($0, aTemporary, ":")
        gsub("_", "", aTemporary[1])

        print vDataOrigin
        print "HPGL PU 0,"(-1 * (6.35 / 0.025))";"
        print "HPGL PU 0,"(-1 * ((5.08 * vStepDownFlag) / 0.025))";"
        print "HPGL SP "aTemporary[2]";"
        printf("HPGL SI.15,.20;LB%s/%-5smm/%6s\n", aTemporary[1], aTemporary[3], aTemporary[4])
        vStepDownFlag++
    }
    close(vToolInformationFile)
    print "" # �t�@�C����,�c�[�����o�͂͏I��
}

function _ReadToolInformation() {
#
# �ړI : �c�[�������c�[���ԍ����L�[�ɂ����A�z�z��ɓǂݍ���,
#        �`��ׂ̈̎Q�Ɨp�A�z�z��𐶐�����
#
# �ϐ�/�z�� : vToolInformationFile / �c�[������[�߂��t�@�C��
#           : aToolInformation[...] /
#           : vToolCount / �ǂݍ��񂾃c�[����
#
    # �ϐ���������
    vToolInformationFile = vTempDir"MAIN_INF.TMP"
    vToolCount = 0

    # �����J�n
    while (getline < vToolInformationFile > 0) {
        split($0 , aTemporary , ":")
        aToolInformation[aTemporary[1]] = aTemporary[2]":"aTemporary[3]
        vToolCount++
    }
    close(vToolInformationFile)
}

function _SetDataOrigin() {
#
# �ړI : _ReadWBSInformation() �̉������T�u���[�`��
#      : ���̓f�[�^�̌��_���`��,��ʃ��[�`���֕Ԃ�
#
    # �����J�n
    if (vDataXOffset <= 0) {vDataXOffset = (-1 * vDataXOffset)} # ��ʒu/X���W�̕␳
    if (vDataYOffset <= 0) {vDataYOffset = (-1 * vDataYOffset)} # ��ʒu/Y���W�̕␳
    if (vStandardSGXOffset <= 0) {vStandardSGXOffset = (-1 * vStandardSGXOffset)} # SG�I�t�Z�b�g/X���W�̕␳
    if (vStandardSGYOffset <= 0) {vStandardSGYOffset = (-1 * vStandardSGYOffset)} # SG�I�t�Z�b�g/Y���W�̕␳

    # �K�C�h���ʒu/��O�`�T�C�Y���Ɋ�Â�,�f�[�^���_����������
    if (vGuideHole = "Outside") { # �O�K�C�h�̏ꍇ
        if (vStandardSGOffset = "LeftBottom") {
            vDataXOffset = (((vWBSXLength / 2) * -1) / 0.025)
            vDataYOffset = 0
        } else if (vStandardSGOffset = "RightBottom")
            ;
        else if (vStandardSGOffset = "RightTop")
            ;
        else if (vStandardSGOffset = "LeftTop")
            ;
    } else if (vGuideHole = "Inside") { # ���K�C�h�̏ꍇ
        if (vStandardSGOffset = "LeftBottom") {
            vDataXOffset = (((vWBSXLength / 2) * -1) / 0.025)
            vDataYOffset = 0
        } else if (vStandardSGOffset = "RightBottom")
            ;
        else if (vStandardSGOffset = "RightTop")
            ;
        else if (vStandardSGOffset = "LeftTop")
            ;
    }
    # �f�[�^���_���`����,��ʃ��[�`���ɕԂ�
    return "HPGL PA;PU "vDataXOffset","vDataYOffset";PR;"
}

function _ReadWBSInformation() {
#
# �ړI : ���[�N�{�[�h�f�[�^�����O���t�@�C������ǂݍ���,�ϐ��ɕ��ނ���
#      : �e�ϐ��Ɋ�Â�,���̓f�[�^���_���`����(_SetDataOrigin())
#      : ���̓f�[�^���_����ʃ��[�`���ɕԂ�
#
# �ϐ�/�z�� : vWBSInformationFile /
#           : vTemporary /
#           : aTemporary[...] /
#           : vWBSXLength / ���[�N�{�[�hX��
#           : vWBSYLength / ���[�N�{�[�hY��
#           : vGuideHole / �K�C�h���̈ʒu
#           : vStandardSG / �SG�̈ʒu
#           : vStandardSGXOffset / �SG��X�����I�t�Z�b�g�l
#           : vStandardSGYOffset / �SG��Y�����I�t�Z�b�g�l
#           : vDataXOffset / ��ʒuX���W
#           : vDataYOffset / ��ʒuY���W
#
    # ���[�N�{�[�h����ǂݍ���,�ϐ�����������
    vWBSInformationFile = vTempDir"WBS.TMP"
    while (getline < vWBSInformationFile > 0) {
        vTemporary = $0
        split(vTemporary, aTemporary, ":")
        vWBSXLength = aTemporary[1]
        vWBSYLength = aTemporary[2]
        vGuideHole = aTemporary[3]
        vStandardSG = aTemporary[4]
        vStandardSGXOffset = aTemporary[5]
        vStandardSGYOffset = aTemporary[6]
        vDataXOffset = aTemporary[7]
        vDataYOffset = aTemporary[8]
    }
    close(vWBSInformationFile)
    return _SetDataOrigin()
}
