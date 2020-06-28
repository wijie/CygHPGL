#
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ړI : �e�X�N���v�g�ŋ��ʂ̕ϐ�, �֐����܂Ƃ߂�
#
BEGIN {
    vCP = "cp"     # �t�@�C�����R�s�[����R�}���h��
    vMV = "mv"     # �t�@�C�����ړ�����R�}���h��
    vRM = "rm"     # �t�@�C�����폜����R�}���h��
    vCAT = "cat"   # �t�@�C�������_�C���N�g����R�}���h��
    vSORT = "sort" # �\�[�g�R�}���h��
                   # sort��GNU sort���g����(Windows��sort.exe�͕s��)
    vCLEAR = "clear" # ��ʂ���������R�}���h��
}

function _DeleteArray(A) {
#
# �ړI : ���� A �Ŏw�肳�ꂽ�z��̑S�v�f���폜����
#
    for (item in A) {
        delete A[item]
    }
}

function _Test(file) {
#
# �ړI : �t�@�C���̗L���𒲂ׂ�
#
    vFS = FS # �t�B�[���h�Z�p���[�^���L��
    vRS = RS # ���R�[�h�Z�p���[�^���L��
    FS = " " # �t�B�[���h�Z�p���[�^���X�y�[�X�ɐݒ�
    RS = "\n" # ���R�[�h�Z�p���[�^�����s�ɐݒ�

    err = getline < file
    close(file)
    FS = vFS # �t�B�[���h�Z�p���[�^��߂�
    RS = vRS # ���R�[�h�Z�p���[�^��߂�
    return err
}

function _TempDir() {
#
# �ړI : �e���|�����f�B���N�g���̏ꏊ���m�F����
#
# ���� : ���ϐ���"TEMP"���ݒ肳��Ă��Ȃ���΂Ȃ�Ȃ�
#      : ���ϐ����ݒ�̏ꍇ�̓J�����g�f�B���N�g���ɏo�͂���
#
# �ϐ�/�z��/�A�z�z�� : vTempDir / �e���|�����f�B���N�g���̃t�@�C���n���h��
#
    vTempDir = ENVIRON["TEMP"]
    gsub(/\\/, "/", vTempDir)
    if (substr(vTempDir, length(vTempDir), 1) == "/")
        ;
    else if (vTempDir == "")
        ;
    else
        vTempDir = vTempDir"/"
}
