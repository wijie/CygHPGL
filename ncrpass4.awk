#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ړI : NC���[�^�[�f�[�^��HP-GL_1�t�H�[�}�b�g�ɕϊ�����
#           �ŏI�f�[�^�`���o��
#
# �ϐ�/�z�� :
#
# ���� : HPGL-1_format ��1�P��(�v���b�^���j�b�g)��0.025mm�ł���
#      : A1�T�C�Y�� 840mm * 594mm �ł���
#      : HP-7586B �̕`��͈͂� (-420, -297) ���� (420, 297) �ł���
#
BEGIN {}

{
    if ($1 == "HPGL") {
        gsub(/^HPGL /, "")
        print $0
    } else
        print $0
}

END {
    print "\nPU;SP 0;\n"
}
