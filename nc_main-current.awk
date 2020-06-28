#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ړI : ���̓t�@�C����HP-GL_1�t�H�[�}�b�g�ɕϊ�����
#           --> ���[�N�{�[�h��`�悷��
#           --> �t�@�C������`�悷��
#           --> �c�[����/���a/������`�悷��
#           --> M02�̍��W�ɓ���̃}�[�N��`�悷��
#
# �ϐ�/�z��/�A�z�z�� : vWBSXLength / ���[�N�{�[�hX��
#                    : vWBSYLength / ���[�N�{�[�hY��
#                    : vWBSXOffset / �I�t�Z�b�gX��
#                    : vWBSYOffset / �I�t�Z�b�gY��
#                    : vCatFlag / �O���ϐ�,���C���t�@�C��,�����t�@�C�������ύX�p
#                    : vCatFile / �O���ϐ�,�����t�@�C����
#                    : vToolInformationFile / �c�[�����t�@�C��
#                    : vInputFile / ���̓t�@�C����
#                    : vStepDownFlag / �c�[���`��p�ϐ�
#                    : vTab / �c�[���`��p�ϐ�
#                    : vTotalCount / �������v�p�ϐ�
#                    : vToolSize / �h�����a
#                    : vRadius / CI�̔��a
#                    : vPenWidth / �y���̑���
#                    : aToolInformation[...] / �c�[���R�[�h���L�[�Ƃ����c�[�����(�F,�T�C�Y)
#                    : vPenModeFlag / �y���A�b�v�_�E���t���O
#                    : aTemporary[...] / split() ����������e���|�����z��
#                    : vABS_INC / ABS or INC����p�ϐ�
#                    : vPrefix / �v���t�B�b�N�X�p�ϐ�
#                    : vPrefixFlag / �v���t�B�b�N�X���K�v������p�t���O
#                    : vWB_OriginX / ���[�N�{�[�h����X���W
#                    : vWB_OriginY / ���[�N�{�[�h����Y���W
#                    : vNC_OriginX / NC���_X���W
#                    : vNC_OriginY / NC���_Y���W
#
# �T�|�[�g����NC�f�[�^����R�[�h
#
#    1 : Txxx   = �c�[���w��                                    : SP
#    2 : M0[57] = �h�����T�C�N��(�h�����q�b�g)                  : CI
#    3 : G2[56] = �T�u�u���b�N�I��/�J�n                         : �X�N���v�g�őO���������{
#    4 : Nxx    = �T�u�u���b�N�V�[�P���X�ԍ�                    : �X�N���v�g�őO���������{
#    5 : G8[01] = �����h�����T�C�N��(�����h�����q�b�g)�I��/�J�n : PU/PD
#    6 : M02    = �f�[�^�I���R�[�h                              : �������߂����s
#    7 : M89    = �t�Z�b�g�h�~�R�[�h                            : CI
#
# ���� : HP-GL_1�t�H�[�}�b�g��1�P��(�v���b�^�[���j�b�g)��0.025mm�ł���
#      : A1�T�C�Y�� 840mm * 594mm �ł���
#      : HP-7586B �̕`��͈͂� (-420, -297) ���� (420, 297) �ł���
#
BEGIN {
    print "\nDF;\n"

    _TempDir()
    _ReadWBSInformation()
    _MakeWBS()
    _InputDataInformation()
    _JumpToDataOrigin()

    # �y�����쐧��p�t���O�̐ݒ�
    # G80 = 0 / G81 = 1
    vPenModeFlag = 0

    # ��΍��W�ɐݒ�   / ���΍��W�ɐݒ�
    # vABS_INC = "ABS" / vABS_INC = "INC"
    vABS_INC = "INC"

    # ���W�ɕt����v���t�B�b�N�X(PA; or PU;)
    vPrefix = ""

    # �v���t�B�b�N�X���K�v�����肷��t���O
    # �K�v = 0 / �s�v = 1
    vPrefixFlag = 1

    # �y���̑���
    vPenWidth = 0.5
}

{
    if ($0 == "G_80") # �y���A�b�v
        vPenModeFlag = 0
    else if ($0 == "G_81") # �y���_�E��
        vPenModeFlag = 1
    else if ($0 == "G_90") { # ��΍��W
        if (vABS_INC == "INC") {
            vABS_INC = "ABS"
            vPrefix = "PA;"
            vPrefixFlag = 0
        }
    } else if ($0 == "G_91") { # ���΍��W
        if (vABS_INC == "ABS") {
            vABS_INC = "INC"
            vPrefix = "PR;"
            vPrefixFlag = 0
        }
    } else if ($1 ~/T_/) { # �c�[���I��
        vTool = $1
        split(aToolInformation[vTool], aTemporary, ":")
        vPenColor = aTemporary[1]
        vToolSize = aTemporary[2]
	vRadius = ((vToolSize - vPenWidth) / 2) / 0.025
	if (vRadius < 0) vRadius = 0 # ���a0�ȉ���0�ŕ`��
        print "SP "vPenColor";"
    } else if ($1 ~/X_/ && $2 ~/Y_/) { # X/Y�ړ�
        if (NF == 3 && $3 ~/M_(05|07|89)/) { # �q�b�g�R�[�h
            _XYCoordinate()
            if (vPrefixFlag == 1) vPrefix = ""
            if (vABS_INC == "ABS")
                print vPrefix"PU "(((vXCoordinate + vNC_OriginX) / 100) / 0.025) \
                      ","(((vYCoordinate + vNC_OriginY) / 100) / 0.025)";"
            else
                print vPrefix"PU "((vXCoordinate / 100) / 0.025)","((vYCoordinate / 100) / 0.025)";" # 100�Ŋ���̂͂Ȃ��H
            print "CI "vRadius";"
            vPrefixFlag = 1
        } else if (NF == 2 && vPenModeFlag == 1) { # �y���_�E��
            _XYCoordinate()
            if (vPrefixFlag == 1) vPrefix = ""
            if (vABS_INC == "ABS")
                print vPrefix"PU "(((vXCoordinate + vNC_OriginX) / 100) / 0.025) \
                      ","(((vYCoordinate + vNC_OriginY) / 100) / 0.025)";"
            else
                print vPrefix"PU "((vXCoordinate / 100) / 0.025)","((vYCoordinate / 100) / 0.025)";" # 100�Ŋ���̂͂Ȃ��H
            print "CI "vRadius";"
            vPrefixFlag = 1
        } else if (NF == 2 && vPenModeFlag == 0) { # �y���A�b�v
            _XYCoordinate()
            if (vPrefixFlag == 1) vPrefix = ""
            if (vABS_INC == "ABS")
                print vPrefix"PU "(((vXCoordinate + vNC_OriginX) / 100) / 0.025) \
                      ","(((vYCoordinate + vNC_OriginY) / 100) / 0.025)";"
            else
                print vPrefix"PU "((vXCoordinate / 100) / 0.025)","((vYCoordinate / 100) / 0.025)";" # 100�Ŋ���̂͂Ȃ��H
            vPrefixFlag = 1
        }
    } else if ($0 == "M_02") { # �f�[�^�I���R�[�h
        if (vABS_INC == "ABS") vPrefix == "PR;"
        print "SP 1;"
        print vPrefix"PU "(-1 * (2.5 / 0.025))","(2.5 / 0.025)";"
        print "PD "(5 / 0.025)","(-1 * (5 / 0.025))";"
        print "PU 0,"(5 / 0.025)";"
        print "PD "(-1 * (5 / 0.025))","(-1 * (5 / 0.025))";"
    } else if ($0 == "M_89") # �t�Z�b�g�h�~�R�[�h
        print "CI "vRadius";"
}

END {
    if (vCatFile == "null" || vCatFlag == 1)
        print "\nPU;SP 0;\n"
}

function _XYCoordinate() {
#
# �ړI : X/Y���W�̈ړ��ʂ𓾂�
#
# �ϐ�/�z��/�A�z�z�� : aTemporart[...] / split() ����������e���|�����z��
#                    : vXCoordinate / X�ړ���
#                    : vYCoordinate / Y�ړ���
#
# ���� : (���Ԃ�)�Ȃ�
#
    split($1, aTemporary, "_") # X�ړ���
    vXCoordinate = aTemporary[2]

    split($2, aTemporary, "_") # Y�ړ���
    vYCoordinate = aTemporary[2]
}

function _JumpToDataOrigin() {
#
# �ړI : ���̓f�[�^�ɑΉ������f�[�^���_�܂ŃW�����v����
#
# ���� : �X���[�z�[���f�[�^���_�̓��[�N�{�[�h�T�C�Y�ɂ���ĉς���I�t�Z�b�g�l������
#      : �m���X���[�z�[���f�[�^���_�̓��[�N�{�[�h�T�C�Y�Ɋ֌W�Ȃ���ӂɌ��肳���
#      : 57.15�̓c�[�����X�g�̕`��G���A�ł���
#      : 290�͕`��G���A�ł���(297�ɐݒ肷��Ɛ؂�Ă��܂��׏����ڂ̒l�ɂ���)
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
    if (vCatFlag == 0) { # �X���[�z�[���f�[�^�̏ꍇ
        print "PR;PU "(vWBSXOffset / 0.025)","(vWBSYOffset / 0.025)";"
        print ""
        vNC_OriginX = (vWB_OriginX + vWBSXOffset) * 100
        vNC_OriginY = (vWB_OriginY + vWBSYOffset) * 100
    } else if (vCatFlag == 1) { # �m���X���[�z�[���f�[�^�̏ꍇ
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
# �ړI : �t�@�C������/�h�������|�[�g�𐶐�����
#      : �`��ׂ̈̎Q�Ɨp�A�z�z��𐶐�����
#
# ���� : �t�@�C�����̓��[�N�{�[�h���_����6.35mm�������ӏ��ɐ�������
#      : �t�@�C�����͕�����3mm/��������4mm(���ׂđ啶���̏ꍇ)�ŕ`�悷��
#      : �c�[�����̓t�@�C��������5.08mm�������ӏ����琶������
#      : �c�[�����͕�����1.5mm/��������2mm(���ׂđ啶���̏ꍇ)�ŕ`�悷��
#      : �c�[�������c�[���ԍ����L�[�ɂ����A�z�z��ɓǂݍ���(�y���F�ƃc�[���̒��a)
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
    if (vCatFlag == 0) { # �X���[�z�[���f�[�^�̏ꍇ
        print "PA;PU "vListPossionX","vListPossionY";"
        vToolInformationFile = vTempDir"MAIN_INF.TMP"
        print "SI.30,.40;LB"vInputFile""
        print ""
    } else if (vCatFlag == 1) { # �m���X���[�z�[���f�[�^�̏ꍇ
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

        # T50�͌����ɐ����Ȃ�
        if (aTemporary[1] == "T50")
            aTemporary[4] = "("aTemporary[4]")"
        else
            vTotalCount += aTemporary[4]

        if (vStepDownFlag > 10) {
            vTab += 2000
            vStepDownFlag = 1
        }
        if (vCatFlag == 0) # �X���[�z�[���f�[�^�̏ꍇ
            print "PA;PU "vListPossionX + vTab","vListPossionY - ((5.08 * vStepDownFlag) / 0.025)";"
        else if (vCatFlag == 1) # �m���X���[�z�[���f�[�^�̏ꍇ
            print "PA;PU "0 + vTab"," vListPossionY - ((5.08 * vStepDownFlag) / 0.025)";"
        print "SP "aTemporary[2]";"
        if (aTemporary[1] == "T50")
            printf("SI.15,.20;LB%s/%-5smm/%7s\n", aTemporary[1], aTemporary[3], aTemporary[4])
        else
            printf("SI.15,.20;LB%s/%-5smm/%6s\n", aTemporary[1], aTemporary[3], aTemporary[4])
        vStepDownFlag++
    }
    if (vCatFlag == 0) # �X���[�z�[���f�[�^�̏ꍇ
        print "PA;PU "vListPossionX + vTab","vListPossionY - ((5.08 * vStepDownFlag) / 0.025)";"
    else if (vCatFlag == 1) # �m���X���[�z�[���f�[�^�̏ꍇ
        print "PA;PU "0 + vTab"," vListPossionY - ((5.08 * vStepDownFlag) / 0.025)";"
    print "SP 1;"
    printf("SI.15,.20;LB%4s%-7s/%6s\n", "", "Total", vTotalCount)
    print ""
    close(vToolInformationFile)
}

function _MakeWBS() {
#
# �ړI : ���[�N�{�[�h�𐶐�����
#
    print "PA;PU 420,297;"
    # �p���̌��_���烏�[�N�{�[�h���_�܂Ő�΍��W�ňړ�����
    if ((vWBSYLength / 2) + 57.15 > 290)
        print "PR;PU "(-1 * ((vWBSXLength / 2) / 0.025))","(-1 * ((vWBSYLength - 290) / 0.025))";"
    else
        print "PR;PU "(-1 * ((vWBSXLength / 2) / 0.025))","(-1 * ((vWBSYLength / 2) / 0.025))";"
    print "PR;"

    # �y���ԍ�1��I��
    print "SP 1;"

    # ���[�N�{�[�h�`��
    print "PD "(vWBSXLength / 0.025)",0;"
    print "PD 0,"(vWBSYLength / 0.025)";"
    print "PD "(-1 * (vWBSXLength / 0.025))",0;"
    print "PD 0,"(-1 * (vWBSYLength / 0.025))";"
    print ""
}

function _ReadWBSInformation() {
#
# �ړI : ���[�N�{�[�h���,�I�t�Z�b�g�l���t�@�C������ǂݍ����,�ϐ���p�ӂ���
#
# �ϐ�/�z��/�A�z�z�� :
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
