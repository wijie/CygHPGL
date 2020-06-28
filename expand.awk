#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ړI : �u���b�N�W�J
#
# �ϐ�/�z�� : vTempDir / �e���|�����f�B���N�g���̈ʒu
#           : vDataType / �O���ϐ�,�f�[�^�^
#           : vSubBlock / �T�u�u���b�N�t�@�C����
#           : vSubBlockCount / �T�u�u���b�N�Ăяo����
#           : vSubBlockList / �T�u�u���b�N�t�@�C�����̃��X�g
#           : vRM / �t�@�C�����폜����R�}���h��
#
# ���� : NC���[�^�[�f�[�^�̓T�u�u���b�N���ŕʂ̃T�u�u���b�N���Ăяo���Ă��鎖������.
#      : 2��ȏ�̃T�u�u���b�N�Ăяo���ɂ͑Ή����Ă��Ȃ�.
#
BEGIN {
    _TempDir()
}

{
    if (vDataType == "NC") {
        if ($0 ~/M_(4[4-9]|[5-8][0-9]|9[0-7])/ && $0 != "M_89") { # �T�u�u���b�N�Ăяo��
            vSubBlock = vTempDir $1".SUB"
            if (vSubBlockList !~$1".SUB,")
                vSubBlockList = vSubBlockList $1".SUB,"
            while (getline < vSubBlock > 0)
                print $0
            close(vSubBlock)
        } else
            print $0
    } else if (vDataType == "NC_R") {
        if ($0 ~/M_98/ && $0 ~/P_/ && $0 ~/L_/) { # �T�u�u���b�N�����Ăяo��
            for (i = 1; i <= NF; i++) {
                if ($i ~/P_/) {
                    vSubBlock = vTempDir $i".SUB"
                    if (vSubBlockList !~$i".SUB,")
                        vSubBlockList = vSubBlockList $i".SUB,"
                } else if ($i ~/L_/) {
                    split($i, aTemporary, "_")
                    vSubBlockCount = aTemporary[2]
                    for (ii = 1; ii <= vSubBlockCount * 1; ii++) {
                        while (getline < vSubBlock > 0)
                            print $0
                        close(vSubBlock)
                    }
                    close(vSubBlock)
                }
            }
        } else if ($0 ~/M_98/ && $0 ~/P_/ && $0 !~/L_/) { # �T�u�u���b�N�Ăяo��
            for (i = 1; i <= NF; i++) {
                if ($i ~/P_/) {
                    vSubBlock = vTempDir $i".SUB"
                    if (vSubBlockList !~$i".SUB,")
                        vSubBlockList = vSubBlockList $i".SUB,"
                    while (getline < vSubBlock > 0)
                        print $0
                    close(vSubBlock)
                }
            }
        } else if ($0 ~/G_114/) { # �U�O�����H�p�T�u�u���b�N�Ăяo��
            for (i = 1; i <= NF; i++) {
                if ($i ~/M_/) {
                    split($i, aTemporary, "_")
                    vSubBlock = vTempDir"P_"aTemporary[2]".SUB"
                    if (vSubBlockList !~"P_"aTemporary[2]".SUB,")
                        vSubBlockList = vSubBlockList "P_"aTemporary[2]".SUB,"
                    while (getline < vSubBlock > 0)
                        print $0
                    close(vSubBlock)
                }
            }
            close(vSubBlock)
        } else
            print $0
    }
}

END {
    _RmSubBlock()
}

function _RmSubBlock() {
#
# �ړI : �e���|�����t�@�C�����폜����
#
    vRmFiles = ""
    split(vSubBlockList, TempFile, ",")
    for (i in TempFile) {
        vErrorFlag = _Test(vTempDir TempFile[i])
        if (vErrorFlag != -1)
#            system(vRM" "vTempDir TempFile[i])
            vRmFiles = vRmFiles" "vTempDir TempFile[i]
    }
    system(vRM vRmFiles)
}
