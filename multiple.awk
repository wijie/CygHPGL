#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ړI : ���L����R�[�h���l�𐳂��������̏����_�t�����l�ɒ���
#
#           ��) X_.1 Y_-10. --> X_0.1 Y_-10
#
#           1 : I
#           2 : J
#           3 : R
#           4 : U
#           5 : V
#           6 : X
#           7 : Y
#
#      : ���L�̐���R�[�h�ȊO���폜����
#
#           01 : G00  : ��؍�/�ړ��̂�
#           02 : G01  : �؍�/�����ړ�
#           03 : G02  : �؍�/�E���Ȉړ�
#           04 : G03  : �؍�/�����Ȉړ�
#           05 : G12  : �ۃX�p�C����
#           06 : G14  : �p�X�p�C����
#           07 : G28  : ���_���A(G100�Ɠ���)
#           08 : G64  : �؍�/�X���b�g���H
#           08 : G75  : Z���㏸
#           09 : G100 : ���_���A(G28�Ɠ���)
#           10 : G114 : �U�O�����H
#
#           11 : M04  : Z�����~
#           12 : M05  : �h�����T�C�N��
#           12 : M12  : �h�����T�C�N��
#           13 : M14  : Z���㏸
#           14 : M121 : ��ʌv��
#           15 : M122 : �v���I��
#
#           16 : Txxx : �c�[���i���o�[
#
#      : ���[�_���`�� ==> �m�����[�_���`���ɕύX����
#
# �ϐ�/�z��/�A�z�z�� : vTempDir / �O���ϐ�,�e���|�����f�B���N�g���̈ʒu
#                    : vTemporary[...] / split() ����������e���|�����z��
#                    : vBuffer / �ꎞ�ۊǗp�ϐ�
#
BEGIN { _TempDir() }

{
    for (i = 1; i <= NF; i++) { # �����𐮂���
        # ����R�[�h��T��
        # G�R�[�h (G00,G01,G02,G03,G12,G14,G28,G64,G75,G100,G114)
        # M�R�[�h (M04,M05,M12,M14,M121,M122)
        # T�R�[�h (T_*)
        # ���̑��̃R�[�h(I,J,R,U,V,X,Y) --> �����𐮂���

        if ($i ~/G_(00|01|02|03|12|14|28|64|75|100|114)/)
            vBuffer = vBuffer $i" "
        else if ($i ~/M_(04|05|12|14|121|122)/)
            vBuffer = vBuffer $i" "
        else if ($i ~/T_/)
            vBuffer = vBuffer $i" "
        else if ($i ~/I_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        } else if ($i ~/J_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        } else if ($i ~/R_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        } else if ($i ~/U_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        } else if ($i ~/V_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        } else if ($i ~/X_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        } else if ($i ~/Y_/) {
            split($i, aTemporary, "_")
            vBuffer = vBuffer aTemporary[1]"_"(aTemporary[2] * 1)" "
        }
    }
    gsub(/ $/, "", vBuffer)
    print vBuffer
    vBuffer = ""
}

END {}
