#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ړI : ���̓t�@�C�������C��/�T�u�u���b�N�ɕ�������
#
# �ϐ�/�z��/�A�z�z�� : vDataType / �O���ϐ�,�f�[�^�^
#                    : aTemporary[...] / split() ����������e���|�����z��
#                    : vTempDir / �e���|�����f�B���N�g���̈ʒu
#                    : vSubBlock / �T�u�u���b�N�o�̓t�@�C���n���h��
#                    : vNextLine / �����ϐ�,�u���b�N�I������p�ϐ�
#                    : vMainBlock / ���C���u���b�N�o�̓t�@�C���n���h��
#
BEGIN { _TempDir() }

{
    if (vDataType == "NC") { # NC�f�[�^�̏ꍇ
        if ($1 ~/N_(4[4-9]|[5-8][0-9]|9[0-7])/) { # �ʃT�u�u���b�N�J�n
            split($1, aTemporary, "_") # �T�u�u���b�N�ԍ��𓾂�
            vSubBlock = vTempDir"M_"aTemporary[2]".SUB"
            for ( ; ; ) { # �T�u�u���b�N�o�͊J�n
                getline vNextLine
                if (vNextLine == "M_99") { # �T�u�u���b�N�I��
                    break
                } else {
                    print vNextLine > vSubBlock
                    continue
                }
            }
            close(vSubBlock)
        } else if ($0 == "G_25") { # �T�u�u���b�N�I��,���C���u���b�N�J�n
            vMainBlock = vTempDir"MAIN.TMP"
            for ( ; ; ) { # ���C���u���b�N�o�͊J�n
                getline vNextLine
                if (vNextLine == "M_02") { # �f�[�^�I��
                    print vNextLine > vMainBlock
                    break
                } else {
                   print vNextLine > vMainBlock
                   continue
                }
            }
            close(vMainBlock)
            exit
        }
    } else if (vDataType == "NC_R") { # NC���[�^�[�f�[�^�̏ꍇ
        if ($1 ~/O_/ && $1 != "O_99") { # �ʃT�u�u���b�N�J�n
            split($1, aTemporary, "_") # �T�u�u���b�N�ԍ��𓾂�
            if (aTemporary[2] + 0 <= 2) { # ���C���u���b�N�J�n
                vSubBlock = vTempDir"MAIN.TMP"
            } else if (aTemporary[2] + 0 != 99) { # �T�u�u���b�N�J�n
                vSubBlock = vTempDir"P_"aTemporary[2]".SUB"
            }
            for ( ; ; ) { # �u���b�N�o�͊J�n
                getline vNextLine
                if (vNextLine == "M_99" || vNextLine == "M_02") { # �ʃT�u�u���b�N�I��
                    break
                } else if (vSubBlock == vTempDir"MAIN.TMP") {
                    # �����Œǉ��������݃��[�h�ɐݒ肷��̂�,NC���[�^�[�f�[�^��
                    # O_1(O1)��O_2(O2)�̓�����C���u���b�N�ɂȂ邩��ł���
                    print vNextLine >> vSubBlock
                    continue
                } else {
                    print vNextLine > vSubBlock
                    continue
                }
            }
            close(vSubBlock)
        }
    }
}

END {
    if (vDataType == "NC_R")
        print "M_02" >> vTempDir"MAIN.TMP"
}
