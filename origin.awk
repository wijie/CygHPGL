#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ړI : NC���[�^�[�f�[�^�̊�ʒu�����߂�
#
# �ϐ�/�z��/�A�z�z�� : vTemporary / �e��e���|�����f�[�^
#                    : vFieldCount
#                    : aTemporary[...] / split() ����������e���|�����z��
#                    : vDataXOffset / �f�[�^��ʒu(X���W)
#                    : vDataYOffset / �f�[�^��ʒu(Y���W)
#
# ���� : ���̓f�[�^��"G_100"���Ȃ���΂ǂ��Ȃ�H
#      : �Εӂ̒����������ɂȂ���W���f�[�^���ɑ��݂���ꍇ�͂ǂ����悤�H
#
BEGIN {
    _TempDir()

    # �ϐ����`����
    vDataXOffset = 0
    vDataYOffset = 0
    vAbsoluteX = 0
    vAbsoluteY = 0

    # ���[�N�{�[�h�����t�@�C�������荞��
    _GetWBSInformation()
}

{
    if ($1 == "G_100") {
        getline vTemporary

        # ��̊�ʒu�����߂�
        vFieldCount = split(vTemporary, aTemporary, " ")
        for (i = 1; i <= vFieldCount; i++) {
            if (aTemporary[i] ~/X_/)
                vDataXOffset = _GetCoordinate(aTemporary[i])
            else if (aTemporary[i] ~/Y_/)
                vDataYOffset = _GetCoordinate(aTemporary[i])
        }

        # ��n��
        _DeleteArray(aTemporary)
        exit
    }
}

END {
    # ���[�N�{�[�h�����o�͂���
    print vWBSDefine":"vDataXOffset":"vDataYOffset > vWBSInformationFile

    # ���ׂĂ� T_06 �̍��W�𓾂�
    _GetT06()
}

function _AbsoluteXY() {
#
# �ړI : _GetT06() �̉������T�u���[�`��
#      : X/Y���W���Βl�ŕԂ�
#
# �ϐ�/�z��/�A�z�z�� : vIncrementX / �J�����gX���W(���΍��W)
#                    : vIncrementY / �J�����gY���W(���΍��W)
# ���� : ��΍��W�������������^�C�~���O��,���̃T�u���[�`���̊O�Ō��肵�Ă���
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
# �ړI : T_06 �Ŏw�肳�ꂽ���ʒu��A�z�z��ɂ܂Ƃ߂�
#      : T_06 �A�z�z����t�@�C���ɗ��Ƃ�
#
# �ϐ�/�z��/�A�z�z�� : vInputFile / ���̓t�@�C���ւ̃n���h��
#                    : vAbsoluteX / �J�����gX���W(���΍��W)
#                    : vAbsoluteY / �J�����gY���W(���΍��W)
#                    : vGetT06Flag / �����s�m�F�p�t���O
#                    : aT06[...] / �������Ԃ��L�[�Ƃ��� T_06 �ȍ~�̌��J�����W
#
    # �ϐ��̏�����
    vInputFile = vTempDir"DRL_HIT.TMP"
    vGetT06Flag = 0
    vT06Count = 0
    vAbsoluteX = 0
    vAbsoluteY = 0

    # ���̓t�@�C����ǂݍ���, T06 �ȍ~�̍��W�f�[�^��z��ɂ܂Ƃ߂�
    while (getline < vInputFile > 0) {
        if ($0 == "T_06") # ����ȍ~�͏����Ώۃf�[�^�ł���
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

    # �t�@�C���ɗ��Ƃ�
    for (item in aT06) {
        print aT06[item]":"item > vTempDir"ORIGIN.TMP"
    }

    # ��n��
    _DeleteArray(aT06)
}

function _GetCoordinate(A) {
#
# �ړI : �����Ƃ��Ďw�肳�ꂽ�t�B�[���h����,��������؂蕪���ĕԂ�
#
# �ϐ�/�z��/�A�z�z�� : Temporary[...] / split() ����������e���|�����z��
#
# ���� : �����ɂ� *_* �̌`�����҂��Ă���
#
    # �����J�n
    split (A, aTemporary, "_")
    return aTemporary[2]

    # ��n��
    _DeleteArray(aTemporary)
}

function _GetWBSInformation() {
#
# �ړI : ���[�N�{�[�h���̓ǂݍ���
#      : �SG�̈ʒu���m�F
#
# �ϐ�/�z��/�A�z�z�� : vWBSInformationFile / ���[�N�{�[�h����[�߂��t�@�C���ւ̃n���h��
#                    : vWBSDefine / ���[�N�{�[�h���
#                    : aTemporary[...] / split() ����������e���|�����z��
#                    : vTargetArea / �SG�̈ʒu
#
    # �ϐ��ݒ�
    vWBSInformationFile = vTempDir"WBS.TMP"
    vTargetArea = ""

    # �t�@�C���ǂݍ���
    while (getline < vWBSInformationFile > 0) {
        vWBSDefine = $0
    }
    close(vWBSInformationFile)

    # ��ʒu��ϐ��Ɏ�荞��
    split(vWBSDefine, aTemporary, ":")
    vTargetArea = aTemporary[4]

    # ��n��
    _DeleteArray(aTemporary)
}
