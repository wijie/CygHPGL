#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ړI : �h�����q�b�g�񐔂��e�c�[�����ɏW�v����
#      : �c�[�����ƃh�����J�E���g������������
#
# �ϐ�/�z��/�A�z�z�� : vCatFlag / �O���ϐ�,�����t�@�C���̗L��
#                    : vOutputFile / �o�̓t�@�C���n���h��
#                    : vTempDir / �O���ϐ�,�e���|�����f�B���N�g���̈ʒu
#                    : vToolFile / �c�[����񂪔[�߂��Ă���t�@�C��
#                    : vToolCountFlag / �c�[���J�E���g�����p�t���O
#                    : aDrillCount[...] / �c�[�����L�[�Ƃ����h�����J�E���g���
#                    : aDrillFile[...] / split() ����������e���|�����z��
#                    : aToolFile[...] / split() ����������e���|�����z��
#                    : vDataType / �O���ϐ�,���̓f�[�^��NC��NC���[�^�[���H
#
BEGIN {
    _TempDir()
    vToolCountFlag = "Off" # �c�[���J�E���g�p�t���O�̏�����
    if (vCatFlag == 0) { # NC�f�[�^���C���t�@�C������
        vToolFile = vTempDir"MAINTOOL.TMP"
        vOutputFile = vTempDir"MAIN_INF.TMP"
    } else if (vCatFlag == 1) { # �����t�@�C������
        vToolFile = vTempDir"CAT_TOOL.TMP"
        vOutputFile = vTempDir"CAT_INF.TMP"
    }
}

{
    if ($1 ~/T_[0-9]+/) { # �c�[������
        vToolCountFlag = "Ready" # �c�[���J�E���g����
        vCurrentTool = $1 # �A�z�z��p�̃L�[��p�ӂ���
    } else if ($0 == "G_81") # �h�����T�C�N���J�n�R�[�h����
        vToolCountFlag = "On" # �c�[���J�E���g�J�n
    else if ($0 == "G_80") # �h�����T�C�N���I���R�[�h����
        vToolCountFlag = "Off" # �c�[���J�E���g�I��
    else if ($0 ~/M_0[57]/) { # �h�����q�b�g�R�[�h����
        if (vToolCountFlag == "Ready")
            aDrillCount[vCurrentTool] += 1
        else if (vToolCountFlag == "Off")
            ;
        else if (vToolCountFlag == "On")
            ;
    } else if (vDataType == "NC" && $3 == "M_89") { # �t�Z�b�g�h�~�R�[�h����
        if (vToolCountFlag == "Ready")
            aDrillCount[vCurrentTool] += 1
        else if (vToolCountFlag == "Off")
            ;
        else if (vToolCountFlag == "On")
            ;
    } else if ($1 ~/X_/ && $2 ~/Y_/) { # X/Y���W����
        if (vToolCountFlag == "Ready")
            ;
        else if (vToolCountFlag == "Off")
            ;
        else if (vToolCountFlag == "On")
            aDrillCount[vCurrentTool] += 1
    }
}

END {
    while (getline < vToolFile > 0) { # �c�[�����ǂݍ���
        split($0, aToolFile, ":")
        if (vDataType == "NC")
            print $0":"aDrillCount[aToolFile[1]] > vOutputFile
        else if (vDataType == "NC_R")
            print $0":"aDrillCount[aToolFile[1]] > vTempDir"DRL_TMP1.TMP"
    }
    if (vDataType == "NC_R") {
        system(vSORT" "vTempDir"DRL_TMP1.TMP > "vOutputFile)
        close(vTempDir"DRL_TMP1.TMP")
    }
    close(vToolFile)
}
