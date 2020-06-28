#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# �ϊ����C�����W���[��/�����[�X4(AWK��)
#
#   �ړI : ���[�U�[�C���^�[�t�F�C�X���W���[��/�����[�X4�̏o�̓t�@�C��
#          (TempDir/NC2HPGL.TBL)��ǂݍ���NC�f�[�^/NC���[�^�[�f�[�^��
#          HP-GL_1�t�H�[�}�b�g�ɕϊ�����
#
#   ���� : �e�f�[�^���[�N�{�[�h�T�C�Y�ɂ����,����̌��_����̃V�t�g�l(����)���قȂ�
#           �X���[�z�[��/���ʊ�� => 1) ���[�N�{�[�h�Z��400mm���� = X:Y <=> 4mm : 0mm
#                                    2) ���[�N�{�[�h�Z��400mm�ȏ� = X:Y <=> 4mm : 25mm
#           �X���[�z�[��/���w��� => 1) ���[�N�{�[�h�Z��400mm�ȉ� = X:Y <=> 5mm : ���[�N�{�[�hY��/2
#                                    2) ���[�N�{�[�h�Z��400mm��   = X:Y <=> 5mm : 205mm
#           �m���X���[�z�[������� ===============================> X:Y <=> 4mm : 0mm
#
#        : NC���[�^�[�f�[�^�̌��_�V�t�g�v�Z�͉��L�̒ʂ�
#           �O�K�C�h => 5mm * 5mm
#           ���K�C�h => (�SG�����X + 5mm) * (�SG�����Y + 5mm)
#
#        : Cygwin�t��Awk��, system()�̃V�F����sh.exe�ł���
#
BEGIN {
    FS = "\n"            # �t�B�[���h�Z�p���[�^�͉��s
    RS = ""              # ���R�[�h�Z�p���[�^�͋�s
    vAWK = "gawk"        # AWK�̎��s�t�@�C����
    vNCDir = "./NC/"     # NC�f�[�^��u���f�B���N�g��
    vHPGLDir = "./HPGL/" # *.HP���o�͂���f�B���N�g��
    _TempDir()
    vUserInterfaceTable = vTempDir"NC2HPGL.TBL" # UIF.AWK �o�̓t�@�C��

    system(vCLEAR) # ��ʂ���������
    system("echo �ϊ����D�D�D\\(-.-\\)y-~~")

    while (getline < vUserInterfaceTable > 0) {
        if ($0 !~/^$/) {
            _DataInitialize()
            vDataType = $1
            vMainFile = $2
            split(vMainFile, aTemporary, ".")
            vBaseFileName = aTemporary[1]
            _DivideTool($3)
            _WBSDefine($4)
            vPCBLayer = $5
            vCatFile = $6
            _DivideTool($7)
        }

        # �f�[�^�ϊ��J�n
#        vOutputDev = "lpt2" # �v�����^�|�[�g�ɏo��
#        vOutputDev = vHPGLDir vBaseFileName".HP" # �t�@�C���ɏo��
	vOutputDev = vTempDir "TEMP.HP" # �e���|�����ɏo��
        if (vDataType == "NC") {
            if (vCatFile == "null") { # �������Ȃ�����
                _ConvertNC(vMainFile, 0, vOutputDev) # NC�f�[�^���C���t�@�C��
            } else if (vCatFile != "null") { # �����t�@�C������
                _ConvertNC(vMainFile, 0, vTempDir"T_HOLE.HP") # NC�f�[�^���C���t�@�C��
                _ConvertNC(vCatFile, 1, vTempDir"N_T_HOLE.HP") # NC�f�[�^�����t�@�C��
                system(vCAT" "vTempDir"T_HOLE.HP "vTempDir"N_T_HOLE.HP > "vOutputDev)
            }
        } else if (vDataType == "NC_R") { # NC���[�^�[�f�[�^�ϊ��J�n
            _ConvertNC_R()
        }
#        print "PRINT "vBaseFileName".HP" >> "P_OUT.BAT"
        _RmTempFiles()
    }
    exit
}

END {
    system(vRM " " vUserInterfaceTable)
#    if (vOutputDev !~/^lpt[1-9]$/) {
#        gsub("/", "\\", vHPGLDir)
#        system("start '" vHPGLDir "'")
#    }
#getline PAUSE < "/dev/stdin" # �v���O�������~�߂�(�f�o�b�O�p)
}

function _ConvertNC_R() {
#
# �ړI : NC���[�^�[�f�[�^�ϊ�
#
# �ϐ�/�z��/�A�z�z�� :
#
    _MkField(vNCDir vMainFile, vTempDir"MK_FIELD.TMP")
    system(vAWK" -v vDataType="vDataType \
               " -f nc2hplib.awk \
                 -f divide.awk "vTempDir"MK_FIELD.TMP")

    vErrorFlag = _Test(vTempDir"MAIN.TMP")

    if (vErrorFlag == -1) {
        system(vMV" "vTempDir"MK_FIELD.TMP "vTempDir"EXPAND_2.TMP")
    } else {
        system(vAWK" -v vDataType="vDataType \
                   " -f nc2hplib.awk \
                     -f expand.awk "vTempDir"MAIN.TMP > "vTempDir"EXPAND_1.TMP")
        system(vAWK" -v vDataType="vDataType \
                   " -f nc2hplib.awk \
                     -f expand.awk "vTempDir"EXPAND_1.TMP > "vTempDir"EXPAND_2.TMP")
    }

    system(vAWK" -f nc2hplib.awk \
                 -f multiple.awk "vTempDir"EXPAND_2.TMP > "vTempDir"MULTIPLE.TMP")
    system(vAWK" -v vDataType="vDataType \
               " -f nc2hplib.awk \
                 -f drl_hit.awk "vTempDir"MULTIPLE.TMP")
    system(vAWK" -v vCatFlag=0 \
                 -v vDataType="vDataType \
               " -f nc2hplib.awk \
                 -f t_count.awk "vTempDir"DRL_HIT.TMP")
    system(vAWK" -f nc2hplib.awk \
                 -f origin.awk "vTempDir"DRL_HIT.TMP")

    vSortInput = vTempDir"ORIGIN.TMP"
    vSortOutput = vTempDir"SORT.TMP"
    vX = "null"
    vY = "null"
    vHitCount = "null"
    vCurrentX = "null"
    vCurrentY = "null"
    vCurrentHitCount = "null"
    FS = " " # �t�B�[���h�Z�p���[�^�����Z�b�g
    RS = "\n" # ���R�[�h�Z�p���[�^�����Z�b�g
    if (vStandardSG == "LeftBottom")
        system(vSORT" -n -t: -k1,2 "vSortInput" > "vSortOutput)
    else if (vStandardSG == "RightBottom") {
        while (getline < vSortInput > 0) {
            split($0, aTemporary, ":")
            if (vX == "null") {
                vX = aTemporary[1]
                vY = aTemporary[2]
                vHitCount = aTemporary[3]
            } else if (vX != "null") {
                vCurrentX = aTemporary[1]
                vCurrentY = aTemporary[2]
                vCurrentHitCount = aTemporary[3]
                if (vCurrentX >= vX && vCurrentY <= vY) {
                    vX = vCurrentX
                    vY = vCurrentY
                    vHitCount = vCurrentHitCount
                }
            }
        }
        print vX":"vY":"vHitCount > vSortOutput
    } else if (vStandardSG == "RightTop")
        system(vSORT" -r -n -t: -k1,2 "vSortInput" > "vSortOutput)
    else if (vStandardSG == "LeftTop") {
        while (getline < vSortInput > 0) {
            split($0, aTemporary, ":")
            if (vX == "null") {
                vX = aTemporary[1]
                vY = aTemporary[2]
                vHitCount = aTemporary[3]
            } else if (vX != "null") {
                vCurrentX = aTemporary[1]
                vCurrentY = aTemporary[2]
                vCurrentHitCount = aTemporary[3]
                if (vCurrentX <= vX && vCurrentY >= vY) {
                    vX = vCurrentX
                    vY = vCurrentY
                    vHitCount = vCurrentHitCount
                }
            }
        }
        print vX":"vY":"vHitCount > vSortOutput
    }
    FS = "\n" # �t�B�[���h�Z�p���[�^�̓��^�[��
    RS = "" # ���R�[�h�Z�p���[�^�͋�s
    close(vSortOutput)

    system(vAWK" -f nc2hplib.awk \
                 -f markup.awk "vTempDir"DRL_HIT.TMP > "vTempDir"MARKUP.TMP")
    system(vAWK" -v vInputFile="vMainFile \
               " -f nc2hplib.awk \
                 -f ncrpass1.awk "vTempDir"MARKUP.TMP > "vTempDir"NCRPASS1.TMP")
    system(vAWK" -f ncrpass2.awk "vTempDir"NCRPASS1.TMP > "vTempDir"NCRPASS2.TMP")
    system(vAWK" -f ncrpass3.awk "vTempDir"NCRPASS2.TMP > "vTempDir"NCRPASS3.TMP")
    system(vAWK" -f ncrpass4.awk "vTempDir"NCRPASS3.TMP > "vOutputDev)
}

function _ConvertNC(vTargetFile, vCatFlag, vFinalOutputFile) {
#
# �ړI : NC�f�[�^�ϊ�
#
# �ϐ�/�z��/�A�z�z�� : vTargetFile / ���C���t�@�C��,�����t�@�C��
#                    : vCatFlag / �����t�@�C������p�t���O
#                    : vFinalOutputFile / �e���|�����o�̓t�@�C����
#                    : vErrorFlag / �����ύX�p�t���O
#
    _MkField(vNCDir vTargetFile, vTempDir"MK_FIELD.TMP")
    system(vAWK" -v vDataType="vDataType \
               " -f nc2hplib.awk \
                 -f divide.awk "vTempDir"MK_FIELD.TMP")

    vErrorFlag = _Test(vTempDir"MAIN.TMP")

    if (vErrorFlag == -1) {
        system(vMV" "vTempDir"MK_FIELD.TMP "vTempDir"EXPAND_1.TMP")
    } else {
        system(vAWK" -v vDataType="vDataType \
                   " -f nc2hplib.awk \
                     -f expand.awk "vTempDir"MAIN.TMP > "vTempDir"EXPAND_1.TMP")
    }

    system(vAWK" -v vDataType="vDataType \
               " -f nc2hplib.awk \
                 -f drl_hit.awk "vTempDir"EXPAND_1.TMP")
    system(vAWK" -v vDataType="vDataType \
               " -v vCatFlag="vCatFlag \
               " -f nc2hplib.awk \
                 -f t_count.awk "vTempDir"DRL_HIT.TMP")
    system(vAWK" -v vInputFile="vTargetFile \
               " -v vCatFlag="vCatFlag \
               " -v vCatFile="vCatFile \
               " -v vPCBLayer="vPCBLayer \
               " -f nc2hplib.awk \
                 -f nc_main.awk "vTempDir"DRL_HIT.TMP > "vFinalOutputFile)
}

function _WBSDefine(A) {
#
# �ړI : ���[�N�{�[�h�T�C�Y���,���̑����t�@�C���ɏo�͂���
#
# ���� : (���Ԃ�)�Ȃ�
#
# �ϐ�/�z��/�A�z�z�� :
#
    print A > vTempDir"WBS.TMP"
    split(A, aTemporary, ":")
    vStandardSG = aTemporary[4]
    vWBSDefine = A # ���̕ϐ��͂ǂ�������Q�Ƃ��Ă��Ȃ�
    close(vTempDir"WBS.TMP")

    # ��n��
    _DeleteArray(aTemporary)
}

function _DivideTool(A) {
#
# �ړI : �c�[�������t�@�C���ɏo�͂���
#
# ���� : (���Ԃ�)�Ȃ�
#
# �ϐ�/�z��/�A�z�z�� : vFieldCount / �c�[����
#                    : aTemporary[...] / split() ����������e���|�����z��
#
    vFieldCount = split(A, aTemporary, " ")
    for (i = 1; i <= vFieldCount; i++) {
        if (vMainFile != "" && vCatFile == "")
            print aTemporary[i] > vTempDir"MAINTOOL.TMP"
        else if (vMainFile != "" && vCatFile != "" && vCatFile != "null")
            print aTemporary[i] > vTempDir"CAT_TOOL.TMP"
    }
    close(vTempDir"MAINTOOL.TMP")
    close(vTempDir"CAT_TOOL.TMP")

    # ��n��
    _DeleteArray(aTemporary)
}

function _DataInitialize() {
#
# �ړI : ���łɐݒ肳��Ă���ϐ�/�z��/�A�z�z�������������
#
# ���� : (���Ԃ�)�Ȃ�
#
    vErrorFlag = ""
    vDataType = ""
    vMainFile = ""
    vWBSDefine = ""
    vPCBLayer = ""
    vCatFile = ""
}

function _MkField(i, o) {
#
# �ړI : �����𐮂���
#
    vFS = FS # �t�B�[���h�Z�p���[�^���L��
    vRS = RS # ���R�[�h�Z�p���[�^���L��
    FS = " " # �t�B�[���h�Z�p���[�^���X�y�[�X�ɐݒ�
    RS = "\n" # ���R�[�h�Z�p���[�^�����s�ɐݒ�
    split("A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z", str, ",")
    while (getline < i > 0) {
        gsub(/[ %]/, "")
        if (/^T[0-9]$/) gsub(/T/, "T0")
        for (n in str)
            gsub(str[n], " "str[n]"_")
        gsub(/^ /, "")
        if ($0 != "") print $0 > o
    }
    close(i)
    close(o)
    FS = vFS # �t�B�[���h�Z�p���[�^��߂�
    RS = vRS # ���R�[�h�Z�p���[�^��߂�
}

function _RmTempFiles() {
#
# �ړI : �e���|�����t�@�C�����폜����
#
    vRmFiles = ""
    vTempFiles = "CAT_INF.TMP, \
                  CAT_TOOL.TMP, \
                  DRL_TMP1.TMP, \
                  EXPAND_1.TMP, \
                  EXPAND_2.TMP, \
                  DRL_HIT.TMP, \
                  MAIN.TMP, \
                  MAINTOOL.TMP, \
                  MAIN_INF.TMP, \
                  MARKUP.TMP, \
                  MK_FIELD.TMP, \
                  MULTIPLE.TMP, \
                  NCRPASS1.TMP, \
                  NCRPASS2.TMP, \
                  NCRPASS3.TMP, \
                  ORIGIN.TMP, \
                  ORIGIN.TMP, \
                  SORT.TMP, \
                  WBS.TMP, \
                  T_HOLE.HP, \
                  N_T_HOLE.HP"
    gsub(/ /, "", vTempFiles)
    split(vTempFiles, TempFile, ",")
    for (i in TempFile) {
        vErrorFlag = _Test(vTempDir TempFile[i])
        if (vErrorFlag != -1) {
#            system(vRM" "vTempDir TempFile[i])
            vRmFiles = vRmFiles" "vTempDir TempFile[i]
        }
    }
    system(vRM vRmFiles)
    system(vRM " " vNCDir vMainFile)
    if (vCatFile != "null") system(vRM " " vNCDir vCatFile)
}
