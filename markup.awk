#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ړI : �SG�̈ʒu�ɏ]��,���̓t�@�C�����}�[�N�A�b�v����
#
# �ϐ�/�z��/�A�z�z�� :
#
BEGIN {
    _TempDir()

    # �ϐ��̏�����
    vMarkupInput = vTempDir"SORT.TMP"
    vTargetStandardSG = ""
    vT06Flag = 0
    vT06Count = 0

    # �\�[�g�ς݂� T06[...] ��ǂݍ���,�ϐ���p�ӂ���
    while (getline < vMarkupInput > 0) {
        split($0 , aTemporary , ":")
        vTargetStandardSG = aTemporary[3]
        break
    }
}

{
    print $0
    if ($0 == "T_06")
        vT06Flag = 1
    else if (vT06Flag == 1) {
        if ($NF == "M_05" || $NF == "M_07" || $NF == "M_12") {
            vT06Count++
            if (vT06Count == vTargetStandardSG)
                print "mk_wbs"
        }
    }
}

END {}
