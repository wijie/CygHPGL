#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ړI : ���̓t�@�C������M05/M07/M12/M89���܂܂�Ă���ꍇ�̏����������Ȃ�
#        �Ȃ�,���̏����� _Drl_Hit(TargetFile) �������Ȃ�
#
# �ϐ�/�z��/�A�z�z�� : vDataType / �O���ϐ�,���̓f�[�^��NC��NC���[�^�[���H
#                    : vConvertFlag / M0[57]/M12/M89�����p����t���O
#                    : vTempDir / �O���ϐ�,�e���|�����f�B���N�g���̈ʒu
#                    : �T�u���[�`�����̕ϐ�/�z��/�A�z�z���,�T�u���[�`�����̃R�����g���Q�Ƃ��鎖
#
BEGIN {
    _TempDir()
    vOutputFile = vTempDir"DRL_HIT.TMP"
}

{
   if ($1 ~/M_(05|07|12)/) { # M_05/M_07/M_12 ����
        vConvertFlag = 1
        exit
    } else if ($1 == "M_89" && vDataType == "NC") { # M_89 ����
        vConvertFlag = 1
        exit
    }
}

END {
    close(FILENAME)
    if (vConvertFlag == 0) { # M05/M07/M12/M89�͊܂܂�Ă��Ȃ�
        system(vCP" "FILENAME" "vTempDir"DRL_HIT.TMP")
        close(vTempDir"DRL_HIT.TMP")
    } else if (vConvertFlag == 1) # M05/M07/M12/M89���܂܂�Ă���
        _Drl_Hit(FILENAME)
}

function _Drl_Hit(A) {
#
# �ړI : ���̓t�@�C������M05/M07/M12/M89���܂܂�Ă���ꍇ�̏����������Ȃ�
#
#        �T���v��_1) X_xxxx Y_yyyy ---------------> X_xxxx Y_yyyy M_0[57]
#                     M_0[57] / M12
#
#        �T���v��_2) X_xxxx Y_yyyy M_0[57] / M12 -> ����͂��̂܂�
#
# ���� : NC�f�[�^/NC���[�^�[�f�[�^���Ɋ܂܂��G81/M05/M07?M12��
#        �h�����T�C�N��(�h�����q�b�g)���߂ł��邪,���ꂼ��̓���ɂ͑��Ⴊ����.
#
#         G81   ���̐���R�[�h�ȉ���X/Y���W�ɑ΂��Č����J����
#               ���̖��߂�G80�ɂ���ĉ��������܂ŗL���ł���
#
# M05/M07/M12   ���̐���R�[�h�̒��O/����s��X/Y���W�ɂ̂݌����J����
#               ���̖��߂͒��O/����s��X/Y���W�ɑ΂��Ă̂ݗL���ł���
#
#         M89   ���̐���R�[�h�̒��O/����s��X/Y���W�ɂ̂݌����J����
#               ���̖��߂͒��O/����s��X/Y���W�ɑ΂��Ă̂ݗL���ł���
#               M89�͋t�Z�b�g����R�[�h�ł��邪,�h�����q�b�g���s���̂�
#               �h�����q�b�g���߂Ƃ��Ĉ���
#
#      : �����̖��߂��f�[�^���ɍ��݂��Ă���\�������鎖�ɗ��ӂ���.
#
# �ϐ�/�z��/�A�z�z�� : A : ���̓t�@�C���n���h��
#                    : vOutputFile : �o�̓t�@�C���n���h��
#                    : vLineBuffer : M_0[57]/M12/M89 ����p�ϐ�
#
    n = 0 # �ǂݍ��񂾍s��
    while (getline < A > 0) {
        if (NF == 1) {
            if ($1 ~/M_(05|07|12)/)
                printf " "$0 > vOutputFile
            else if ($1 == "M_89" && vDataType == "NC")
                printf " "$0 > vOutputFile
            else {
                if (n > 0) # 1�s�ڂɋ�s������̂����Ȃ̂�
                    printf "\n"$0 > vOutputFile
                else
                    printf $0 > vOutputFile
            }
        } else {
            if (n > 0) # 1�s�ڂɋ�s������̂����Ȃ̂�
                printf "\n"$0 > vOutputFile
            else
                printf $0 > vOutputFile
        }
        n++
    }
    print "" > vOutputFile
    close(A)
    close(vOutputFile)
}
