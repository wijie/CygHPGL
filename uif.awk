#
# ���̃v���O������WATABE Eiji���Ǝ��ɕύX�������Ă���܂�
# �J����: Cygwin-1.3.2, GNU Awk 3.0.4
#
# ���[�U�[�C���^�[�t�F�C�X���W���[��/�����[�X3(AWK��)
#
#   �ړI : ���͂����X�̃t�@�C���Ɋւ���p�����[�^�����肷��
#
#   ���� : �e�T�u���[�`��(�֐�)�̐������ڂ��Q�Ƃ̎�
#
BEGIN {
    CatFlag = 0
    ToolCount = 0
    CatToolCount = 0
#    DataType = "NC"

    _TempDir()
    _ReadPenTable()
    _ReadWBSTable()

    for (;;) {
        system(vCLEAR) # ��ʂ���������
        _DataType()
        _InputFile()
        _ToolCheck(MainFile)
        _WorkBoardSize()
        if (DataType == "NC") {
            _PCBLayer()
            _Cat()
        } else if (DataType == "NC_R")
            ;
        _ParameterCheck()
        _StartConvert()
    }
    exit
}

{}

END {
    _RmTempFiles()
}

function _PrintParameter() {
#
# �ړI : _ParameterCheck() �̉������T�u���[�`��
#        ���͂��ꂽ�p�����[�^(�ϐ�/�z��/�A�z�z��)��,�����𐮂��ďo�͂���
#
# ���� : (���Ԃ�)�Ȃ�
#
    system (vCLEAR) # ��ʂ���������

    if (DataType == "NC") # ���̓t�@�C���̎�ނ́H
        Temporary = "NC�f�[�^"
    else if (DataType == "NC_R")
        Temporary = "NC���[�^�[�f�[�^"

    print "1: ���̓f�[�^ = "Temporary
    print "2: ���̓t�@�C���� = "MainFile # ���̓t�@�C�����̂́H
    print "3: �c�[���ԍ� �y���ԍ� �h�����a" # ToolDef[...] �̕\��
    for (i = 1; i <= ToolCount; i++) {
        split(ToolDef[i], _Temp, ":")
        printf("%3s%-11s%-9s%s\n", " ", _Temp[1], _Temp[2], _Temp[3])
    }

    if (DataType == "NC") { # ���[�N�{�[�h�p�����[�^�̕\��
        split(WBSDefine, _Temp, ":")
        print "4: ���[�N�{�[�h�T�C�Y = "_Temp[1]"mm * "_Temp[2]"mm" # ���[�N�{�[�h�T�C�Y�́H
        if (_Temp[3] == 0) # �X�^�b�N�́H
            print _Space(3)"�X�^�b�N = �ʏ�"
        else if (_Temp[3] == 1)
            print _Space(3)"�X�^�b�N = ���ʔ�/180mm"
        else if (_Temp[3] == 2)
            print _Space(3)"�X�^�b�N = ���ʔ�/205mm"
        else if (_Temp[3] == 3)
            print _Space(3)"�X�^�b�N = ���w��/"_Temp[4]"mm"
    } else if (DataType == "NC_R") {
        split(WBSDefine, _Temp, ":")
        print "4: ���[�N�{�[�h�T�C�Y = "_Temp[1]"mm * "_Temp[2]"mm" # ���[�N�{�[�h�T�C�Y�́H
        if (_Temp[3] == "Outside") # �K�C�h���́H
            print _Space(2)"�K�C�h�� = �O��"
        else if (_Temp[3] == "Inside")
            print _Space(2)"�K�C�h�� = ����"

        if (_Temp[4] == "LeftBottom") # �SG�́H
            print _Space(2)"�SG = ����"
        else if (_Temp[4] == "RightBottom")
            print _Space(2)"�SG = �E��"
        else if (_Temp[4] == "RightTop")
            print _Space(2)"�SG = �E��"
        else if (_Temp[4] == "LeftTop")
            print _Space(2)"�SG = ����"

        if (_Temp[3] == "Outside") # �SG����̃I�t�Z�b�g�́H
            print _Space(2)"�SG����̃I�t�Z�b�g = 5mm �� 5mm"
        else if (_Temp[3] == "Inside") {
            if (_Temp[5] == 0 && _Temp[6] == 0) {
                print _Space(2)"�SG����̃I�t�Z�b�g�͐ݒ肳��Ă��܂���."
                print _Space(2)"���[�N�{�[�h�͕`�悳��܂���."
            } else if (_Temp[5] != 0 && _Temp[6] != 0)
                print _Space(2)"�SG����̃I�t�Z�b�g = "_Temp[5]"mm * "_Temp[6]"mm"
        }
    }

    if (DataType == "NC" && PCBLayer == "Dual") # ��w���̕\��
        print "5: ��w�� = 2�w"
    else if (DataType == "NC" && PCBLayer == "Multi")
        print "5: ��w�� = ���w"

    if (DataType == "NC" && CatFile == "null") # ��������t�@�C���̕\��
        print "6: ��������t�@�C�� = �������Ȃ�"
    else if (DataType == "NC" && CatFile != "null") {
        print "6: ��������t�@�C�� = "CatFile
        print "7: ��������t�@�C����"
        print "   �c�[���ԍ� �y���ԍ� �h�����a"
        for (i = 1; i <= CatToolCount; i++) {
            split(CatToolDef[i], _Temp, ":")
            gsub("_", "", _Temp[1])
            printf("%3s%-11s%-9s%s\n", " ", _Temp[1], _Temp[2], _Temp[3])
        }
    }

    print ""
    print "����ł����ł����H"
    printf _Space(2)"(0)OK(Default) / (4)��蒼�� / (9)�L�����Z�� : "
    getline Temporary < "/dev/stdin"
    return Temporary
}

function _ParameterCheck() {
#
# �ړI : ���̓p�����[�^�̊m�F�𑣂�,���ʂ𔽉f����
#
# ���� : ���͔͂��p�p�����̂�
#
# �ϐ�/�z��/�A�z�z�� : Temporary / �ꎞ�ϐ�
#
# �ύX��] : �c�[���C����I�������ꍇ�ɖ������őS����蒼���͂炢
#          : �c�[�����ʂɏC���ł��Ȃ����H
#
    for (;;) {
        Temporary = _PrintParameter() # ���ڂ̃��^�[��
        if (Temporary == "")
            break
        else if (Temporary == 0)
            break
        else if (Temporary == 4) {
            printf "�C������������(�ԍ�)��I��ŉ����� : "
            getline Temporary < "/dev/stdin"
            if (Temporary == 1)
                _DataType()
            else if (Temporary == 2)
                _InputFile()
            else if (Temporary == 3) {
                ToolCount = 0
                _ToolCheck(MainFile)
            } else if (Temporary == 4)
                _WorkBoardSize()
            else if (Temporary == 5)
                _PCBLayer()
            else if (Temporary == 6) {
                for (item in CatToolDef) {
                    delete CatToolDef[item]
                }
                _Cat()
            } else if (Temporary == 7) {
                CatFlag = 1
                CatToolCount = 0
                _ToolCheck(CatFile)
            } else if (Temporary == 9)
                break
            else {
                _Error()
                continue
            }
            continue
        } else if (Temporary == 9)
            exit
        else {
            _Error()
            continue
        }
    }
}

function _FileNameCheck() {
#
# �ړI : _InputFile() & _Cat() �̉������T�u���[�`��
#      : �t�@�C������ MS-DOS �̐���������Ă��邩�H
#
# ���� : ���͔͂��p�p�����̂�
#
# �ϐ�/�z��/�A�z�z�� : Temporary / �ꎞ�ϐ�
#
    print ""
    for (;;) {
        printf "�t�@�C�����́H : "
        getline Temporary < "/dev/stdin"
        Temporary = toupper(Temporary)
        if (Temporary == "") {
            _Error()
            continue
        } else if (Temporary ~ /\ /) {
            _Error()
            continue
        } else if (length(Temporary) > 8) {
            _Error()
            continue
        } else if (Temporary ~ /[^A-Z0-9_-]/) {
            _Error()
            continue
        } else {
            return Temporary".DAT"
            break
        }
    }
}

function _Cat() {
#
# �ړI : �����t�@�C������(NC�f�[�^�̂�)
#
# ���� : �g�[�^���������̂݃`�F�b�N���Ă���
#      : �t�@�C�����ɂ̓A���t�@�x�b�g/�����ȊO���g�p���Ă͂����Ȃ�
#
# �ϐ�/�z��/�A�z�z�� : Temporary / �ꎞ�ϐ�
#                    : CatFlag / �����t�@�C���̗L���������t���O
#                    : CatFile / �����t�@�C����
#
    print "\n�ق��̃t�@�C���ƍ������܂����H"
    printf _Space(2)"1 = �������� / 9 = �������Ȃ�(Default) : "
    getline Temporary < "/dev/stdin"

    for (;;) {
        if (Temporary == 1) { # ���������J�n
            CatFlag = 1
            CatFile = _FileNameCheck()
            _ToolCheck(CatFile)
            break
        } else if (Temporary == 9 || Temporary == "") { # �������Ȃ������J�n
            CatFile = "null"
            for (item in CatToolDef) {
                delete CatToolDef[item]
            }
            break
        } else {
            _Error()
            continue
        }
    }
}

function _PCBLayer() {
#
# �ړI : ���̓t�@�C���̊�w�����m�F����
#
# ���� : ���͔͂��p�����̂�
#
# �ϐ�/�z��/�A�z�z�� : Temporary / �ꎞ�ϐ�
#                    : PCBLayer / ��w��
#
    for (;;) {
        print "\n��w��"
        printf _Space(2)"��w������͂��ĉ����� : "
        getline Temporary < "/dev/stdin"
        if (Temporary > 0 && Temporary < 3) {
            PCBLayer = "Dual"
            break
        } else if (Temporary > 2) {
            PCBLayer = "Multi"
            break
        } else {
            _Error()
            continue
        }
    }
}

function _StackTypeNC_R() {
#
# �ړI : _WorkBoardSize() �̉������T�u���[�`��
#      : ���[�N�{�[�h�̃X�^�b�N�����肷��(for NC���[�^�[�f�[�^)
#
# ���� : ���͔͂��p�����̂�
#      : �SG����̍ő�I�t�Z�b�g�T�C�Y�� 0 < StandardSGOffset <= 840 �Ɖ��肷��
#
# �ϐ�/�z��/�A�z�z�� : Temporary / �ꎞ�ϐ�
#                    : WBSDefine / WBSXLength:WBSYLength:GuideHole:StandardSG:StandardSGXOffset:StandardSGYOffset
#
    for (;;) { # �K�C�h���͂ǂ��H
        print ""
        print "�K�C�h���͂ǂ��ɂ���܂����H"
        print _Space(2)"1: �O�� / 2: ����"
        printf _Space(5)"�ԍ���I��ŉ����� : "
        getline Temporary < "/dev/stdin"
        if (Temporary == 1) {
            GuideHole = "Outside"
            WBSDefine = WBSDefine":Outside"
            break
        } else if (Temporary == 2) {
            GuideHole = "Inside"
            WBSDefine = WBSDefine":Inside"
            break
        } else {
            _Error()
            continue
        }
    }

    for(;;) { # �SG�͂ǂ��H
        print ""
        print "�SG�͂ǂ��ɂ���܂����H"
        print _Space(2)"1 : ����"
        print _Space(2)"2 : �E��"
        print _Space(2)"3 : �E��"
        print _Space(2)"4 : ����"
        printf _Space(6)"�ԍ���I��ŉ����� : "
        getline Temporary < "/dev/stdin"
        if (Temporary == 1) {
            WBSDefine = WBSDefine":LeftBottom"
            break
        } else if (Temporary == 2) {
            WBSDefine = WBSDefine":RightBottom"
            break
        } else if (Temporary == 3) {
            WBSDefine = WBSDefine":RightTop"
            break
        } else if (Temporary == 4) {
            WBSDefine = WBSDefine":LeftTop"
            break
        } else {
            _Error()
            continue
        }
    }

    if (GuideHole == "Outside") { # �SG����̃I�t�Z�b�g�l�́H
        WBSDefine = WBSDefine":5:5"
    } else if (GuideHole == "Inside") {
        for (;;) {
            print "\n�SG����̃I�t�Z�b�g�l"
            printf _Space(2)"X�����I�t�Z�b�g = "
            getline Temporary < "/dev/stdin"
            if (Temporary == "") {
                WBSDefine = WBSDefine":"0
                break
            } else if (Temporary > 0 || Temporary <= 840) {
                WBSDefine = WBSDefine":"Temporary
                break
            } else {
                _Error()
                continue
            }
        }

        for (;;) {
            printf _Space(2)"Y�����I�t�Z�b�g = "
            getline Temporary < "/dev/stdin"
            if (Temporary == "") {
                WBSDefine = WBSDefine":"0
                break
            } else if (Temporary > 0 || Temporary <= 840) {
                WBSDefine = WBSDefine":"Temporary
                break
            } else {
                _Error()
                continue
            }
        }
    }
}

function _StackTypeNC() {
#
# �ړI : _WorkBoardSize() �̉������T�u���[�`��
#      : ���[�N�{�[�h�̃X�^�b�N�����肷��(for NC�f�[�^)
#
# ���� : ���͔͂��p�����̂�
#      : �ő�X�^�b�N�T�C�Y�� 0 < StackSize <= 840 �Ɖ��肷��
#
# �ϐ�/�z��/�A�z�z�� : Temporary / �ꎞ�ϐ�
#                    : WBSDefine / WBSXLength:WBSYLength:WBSXOffset:WBSYOffset
#
    for (;;) {
        print ""
        printf "�X�^�b�N���w�����ĉ����� (1:�ʏ�(Default) 2:�w��) : "
        getline Temporary < "/dev/stdin"
        if (Temporary == 1) {
            WBSDefine = WBSDefine":"0
            break
        } else if (Temporary == 2) {
            for (;;) {
                print ""
                print _Space(2)"�X�^�b�N�̓��[�U�[�w��ł�."
                print _Space(4)"1: ���ʔ�/180mm"
                print _Space(4)"2: ���ʔ�/205mm"
                print _Space(4)"3: ���w��"
                printf _Space(7)"�ԍ���I��ŉ����� : "
                getline Temporary < "/dev/stdin"
                if (Temporary == 1) {
                    WBSDefine = WBSDefine":"1
                    break
                } else if (Temporary == 2) {
                    WBSDefine = WBSDefine":"2
                    break
                } else if (Temporary == 3) {
                    for (;;) {
                        print ""
                        printf _Space(6)"Y�����̃I�t�Z�b�g�l�͂ǂꂮ�炢�ł����H : "
                        getline Temporary < "/dev/stdin"
                        if (Temporary > 0 && Temporary <= 840) {
                            WBSDefine = WBSDefine":3:"Temporary
                            break
                        } else {
                            _Error()
                            continue
                        }
                    }
                } else {
                    _Error()
                    continue
                }
                break
            }
        }
        break
    }
}

function _WBSUserDefine() {
#
# �ړI : _WorkBoardSize() �̉������T�u���[�`��
#        ���[�U�[��`���[�N�{�[�h�𐶐�����
#
# ���� : ���[�N�{�[�h�ő�̈�� 840mm * 840mm �Ɖ��肷��
#      : 0 < WBSLength <= 840 �Ɖ��肷��
#      : ���͔͂��p�����̂�
#
# �ϐ�/�z��/�A�z�z�� : Temporary / �ꎞ�ϐ�
#                    : WBSDefine / ���[�N�{�[�h�T�C�Y,���̑��̏��
#
    print ""
    print _Space(2)"���[�U�[��`���I�΂�܂���."
    print ""
    print _Space(2)"���[�N�{�[�h��X��Y�̐��@���w�����ĉ�����."

    for (;;) { # ���[�U�[��`���[�N�{�[�h / X�T�C�Y
        printf _Space(4)"X���@ = "
        getline Temporary < "/dev/stdin"
        if (Temporary > 0) {
            WBSDefine = Temporary
            break
        } else {
            _Error()
            continue
        }
    }

    for (;;) { # ���[�U�[��`���[�N�{�[�h / Y�T�C�Y
        printf _Space(4)"Y���@ = "
        getline Temporary < "/dev/stdin"
        if (Temporary > 0) {
            WBSDefine = WBSDefine":"Temporary
            break
        } else {
            _Error()
            continue
        }
    }
}

function _WBSDisplay() {
#
# �ړI : _WorkBoardSize() �̉������T�u���[�`��
#        _ReadWBSTable() �����������z��̓��e��\������
#
# ���� : (���Ԃ�)�Ȃ�
#
# �ϐ�/�z��/�A�z�z�� : _Temp[...] / split() ����������e���|�����z��
#
    for (i = 1; i <= WBSTableCount; i++) {
        split(WBSDef[i], _Temp, ":")
        print _Space(2)i" : "_Temp[1]"mm * "_Temp[2]"mm"
    }
    print _Space(2)(WBSTableCount + 1)" : ���[�N�{�[�h�̓��[�U�[����`����"
}

function _WorkBoardSize() {
#
# �ړI : ���̓t�@�C���̃��[�N�{�[�h�T�C�Y�����肷��
#
# ���� : ����܂茵���ȃG���[��������Ȃ�(�Ǝv��....)
#
# �ϐ�/�z��/�A�z�z�� : Temporary / �ꎞ�ϐ�
#                    : WBSDefine / ���[�N�{�[�h�T�C�Y���
#
    print "\n���[�N�{�[�h�T�C�Y"

    _WBSDisplay()

    for (;;) {
        printf _Space(6)"�ԍ���I��ŉ����� : "
        getline Temporary < "/dev/stdin"
        if (Temporary in WBSDef) {
            WBSDefine = WBSDef[Temporary]
            break
        } else if (Temporary == (WBSTableCount + 1)) {
            _WBSUserDefine()
            break
        } else {
            system(vCLEAR) # ��ʂ���������
            _Error()
            _WBSDisplay()
            continue
        }
    }

    if (DataType == "NC")
        _StackTypeNC()
    else if (DataType == "NC_R")
        _StackTypeNC_R()
}

function _DrillSize() {
#
# �ړI : _ToolCheck(TargetFile) �̉������T�u���[�`��
#
# ���� : ?????
#
# �ϐ�/�z��/�A�z�z�� : Temporary / �ꎞ�ϐ�
#                    : ToolDef[...] / ���݂̃c�[����������Y���Ƃ���z��(���C���t�@�C��)
#                    : CatToolDef[...] / ���݂̃c�[����������Y���Ƃ���z��(�����t�@�C��)
#
# �ύX��] : _PenColor() �ɏ�����
#
    for (;;) {
        printf _Space(4)"�h�����a�́H : "
        getline Temporary < "/dev/stdin"
        if (Temporary == "") {
            _Error()
            continue
        } else if (Temporary ~ /[^0-9.]/) {
            _Error()
            continue
        } else if (Temporary <= 0) {
            _Error()
            continue
        } else if (CatFlag == 0) {
            ToolDef[MaxToolCount] = ToolDefine":"Temporary
            ToolCount++
            break
        } else if (CatFlag == 1) {
            CatToolDef[MaxToolCount] = CatToolDefine":"Temporary
            CatToolCount++
            break
        }
    }
}

function _PenColor() {
#
# �ړI : _ToolCheck(TargetFile) �̉������T�u���[�`��
#
# ���� : ?????
#
# �ϐ�/�z��/�A�z�z�� : Temporary / �ꎞ�ϐ�
#                    : ToolDefine / ���ݏ������̃c�[���Ɋւ�����(���C���t�@�C��)
#                    : CatToolDefine / ���ݏ������̃c�[���Ɋւ�����(�����t�@�C��)
#
# �ύX��] : ���C���t�@�C���ƍ����t�@�C���̓񌳊Ǘ�����߂�,�ꌳ�Ǘ�������
#          : ���ʂ� return �ŏ�ʃT�u���[�`���ɕԂ��l�ɕύX����
#          : ToolDefine �� CatToolDefine �̓񌳊Ǘ��͐������A�v���[�`���H
#
    for (;;) {
        printf _Space(4)"���F�ɂ��܂����H : "
        getline Temporary < "/dev/stdin"
        if (Temporary == "") {
            if (CatFlag == 0) {
               ToolDefine = CurrentTool":"_Temp[1]
               break
            } else if (CatFlag == 1) {
               CatToolDefine = CurrentTool":"_Temp[1]
               break
            }
        } else if (Temporary in PenColorE) {
            split(PenColorE[Temporary],_Temp,":")
            if (CatFlag == 0) {
                ToolDefine = CurrentTool":"_Temp[1]
                break
            } else if (CatFlag == 1) {
                CatToolDefine = CurrentTool":"_Temp[1]
                break
            }
        } else if (Temporary in PenColorJ) {
            split(PenColorJ[Temporary],_Temp,":")
            if (CatFlag == 0) {
                ToolDefine = CurrentTool":"_Temp[1]
                break
            } else if (CatFlag == 1) {
                CatToolDefine = CurrentTool":"_Temp[1]
                break
            }
        } else if (Temporary in PenNumber) {
            split(PenNumber[Temporary],_Temp,":")
            if (CatFlag == 0) {
                ToolDefine = CurrentTool":"_Temp[1]
                break
            } else if (CatFlag == 1) {
                CatToolDefine = CurrentTool":"_Temp[1]
                break
            }
        } else {
            _Error()
            continue
        }
    }
}

function _ConvertToolFormat() {
#
# �ړI : _ToolChrck(TargetFile) �̉������T�u���[�`��
#
# �ϐ�/�z��/�A�z�z�� : ToolFile / �����p�e���|�����t�@�C��(�g����)
#                    : _Temp[...] / split() ����������e���|�����z��
#
    ToolFile2 = vTempDir"T2.TMP"
    ToolFile3 = vTempDir"T3.TMP"
    ToolFile4 = vTempDir"T4.TMP"

    while (getline < ToolFile2 > 0) {
        if (NF == 1) {
            if (length($0) == 2) {
                gsub(/T/, "T0")
                print $0 > ToolFile3
            } else
                print $0 > ToolFile3
        }
    }
    close(ToolFile3)
    system(vSORT" -u "ToolFile3" > "ToolFile4)
}

function _ToolCheck(TargetFile) {
#
# �ړI : ���̓t�@�C�����̃c�[�����Ƀy���F/�h�����a���`����
#
# ���� : ����܂茵���ȃG���[��������Ȃ�(�Ǝv��)
#      : ���̓t�@�C���ɂ͓����c�[���������o�����Ȃ��Ɖ��肵�Ă���
#
# �ϐ�/�z��/�A�z�z�� : TargetFile / �T�u���[�`���ɑ΂������(���̓t�@�C����)
#                    : ToolFile / ���̓t�@�C���ɑ��݂��邷�ׂẴc�[����[�߂��t�@�C��
#                    : PenTableCount / ���܂łɓ��̓t�@�C�����甭�������c�[���̐�
#                    : MaxToolCount / ���̓t�@�C���Ɋ܂܂��c�[���̍ő吔
#                    : CurrentTool / ���ݏ������̃c�[��
#                    : _Temp[...] / split() ����������e���|�����z��
#                    : CatFlag / �����t�@�C���̗L���������t���O
#
# �ύX��] : ���̓t�@�C���ɓ����c�[���������o�������ꍇ�̏����́H(NC���[�^�[�f�[�^)
#
    PenTableCount = 1
    MaxToolCount = 1

    while (getline < TargetFile > 0) {
        if ($0 ~/^T[0-9]+$/)
            print > vTempDir"T2.TMP"
        else if ($0 ~/^O99$/)
            break
    }
    close(TargetFile)
    close(vTempDir"T2.TMP")

    _ConvertToolFormat()

    ToolFile = vTempDir"T4.TMP"
    while (getline < ToolFile > 0) {
        CurrentTool = $0
        if (PenTableCount > MaxPenNumber)
            PenTableCount = 1
        printf _Space(2)"�c�[�� "CurrentTool" �������܂���"
        split(PenNumber[PenTableCount],_Temp,":")
        print " (���݂̃y���F = "_Temp[3]")"

        _PenColor()
        _DrillSize()

        PenTableCount++
        MaxToolCount++
    }
    close(TargetFile)
    close(ToolFile)
    CatFlag = 0
}

function _InputFile() {
#
# �ړI : ���̓t�@�C�����̊m�F
#
# ���� : �g�[�^���������̂݃`�F�b�N���Ă���
#      : �t�@�C�����ɂ̓A���t�@�x�b�g/�����ȊO���g�p���Ă͂����Ȃ�
#
# �ϐ�/�z��/�A�z�z�� : MainFile / ���C���t�@�C��
#
    MainFile = _FileNameCheck()
}

function _DataType() {
#
# �ړI : ���̓t�@�C���̎�ʔ���
#
# ���� : �I�y���[�^�[�̓��͂�M���Ă���
#      : ���͔͂��p�����̂�
#
# �ϐ�/�z��/�A�z�z�� : Temporary / �ꎞ�ϐ�
#                    : DataType / ���̓f�[�^�̌^
#
    for (;;) {
        print "���̓f�[�^"
        print _Space(2)"1: NC�f�[�^"
        print _Space(2)"2: NC���[�^�[�f�[�^"
        printf _Space(5)"�ԍ���I��ŉ����� : "
        getline Temporary < "/dev/stdin"
        if (Temporary == "") {
            _Error()
            continue
        } else if (Temporary == 1) {
            DataType = "NC"
            break
        } else if (Temporary == 2) {
            DataType = "NC_R"
            break
        } else {
            _Error()
            continue
        }
    }
}

function _WBSInformation() {
#
# �ړI : _StartConvert() �̉������T�u���[�`��
#      : MainFile �� PCBLayer �̓��e�ɂ���� WBSDefine �𕪔z����
#
# ���� : (���Ԃ�)�Ȃ�
#
# �ϐ�/�z��/�A�z�z�� : _Temp[...] / split() ����������e���|�����z��
#
# �ύX��] : ���[�[��I�H
#
    if (DataType == "NC" && MainFile !~ /NT/) {
        split(WBSDefine, _Temp, ":")
        WBSXLength = _Temp[1]
        WBSYLength = _Temp[2]
        StackType = _Temp[3]
        if (StackType == 0) {
            if (PCBLayer == "Dual") {
                if (WBSYLength < 400) {
                    WBSXOffset = 4
                    WBSYOffset = 0
                } else if (WBSYLength >= 400) {
                    WBSXOffset = 4
                    WBSYOffset = 25
                }
            } else if (PCBLayer = "Multi") {
                if (WBSYLength <= 400) {
                    WBSXOffset = 5
                    WBSYOffset = (WBSYLength/2)
                } else if (WBSYLength > 400) {
                    WBSXOffset = 5
                    WBSYOffset = 205
                }
            }
        } else if (StackType == 1) {
            WBSXOffset = 4
            WBSYOffset = 0
        } else if (StackType == 2) {
            WBSXOffset = 4
            WBSYOffset = 25
        } else if (StackType == 3) {
            WBSXOffset = 5
            WBSYOffset = _Temp[4]
        }
        WBSDefine = "" # �ꉞ����������
        WBSDefine = WBSXLength":"WBSYLength":"WBSXOffset":"WBSYOffset
    } else if (DataType == "NC_R")
        ;
}

function _StartConvert() {
#
# �ړI : �p�����[�^���͑��s�̖₢���킹
#
# ���� : ���͔͂��p�����̂�
#
# �ϐ�/�z��/�A�z�z�� : Temporary / �ꎞ�ϐ�
#
    for (;;) {
        print "\n�f�[�^�ϊ����J�n���܂�"
        printf _Space(2)"(0)�ϊ��J�n(Default) / (4)���̃t�@�C����ҏW / (9)�ϊ������ɏI�� : "
        getline Temporary < "/dev/stdin"
        if (Temporary == "" || Temporary == 0) {
            _FlashBuffer()
            exit
        } else if (Temporary == 4) {
            _FlashBuffer()
            break
        } else if (Temporary == 9) {
            exit
        } else {
            _Error()
            continue
        }
    }
}

function _FlashBuffer() {
#
# �ړI : ���͂��ꂽ�p�����[�^���t�@�C���ɗ��Ƃ�
#
# ���� : (���Ԃ�)�Ȃ�
#
# �ϐ�/�z��/�A�z�z�� : OutputFile / �o�̓t�@�C���n���h��
#
    OutputFile = vTempDir"NC2HPGL.TBL"
    if (DataType == "NC_R") {
        PCBLayer = "null"
        CatFile = "null"
    }

    print DataType > OutputFile
    print MainFile > OutputFile
    for (i = 1; i <= ToolCount; i++) {
        gsub(/T/, "T_", ToolDef[i])
        printf ToolDef[i] > OutputFile
        if (i < ToolCount) printf " " > OutputFile
    }
    printf "\n" > OutputFile
    ToolCount = 0
    _WBSInformation()
    print WBSDefine > OutputFile
    print PCBLayer > OutputFile
    print CatFile > OutputFile
    if (CatFile != "null") {
        for (i = 1; i <= CatToolCount; i++) {
            printf CatToolDef[i] > OutputFile
            if (i < CatToolCount) printf " " > OutputFile
        }
    } else if (CatFile == "null")
        printf "null" > OutputFile
    printf "\n\n" > OutputFile
    CatToolCount = 0
}

function _Error() {
#
# �ړI : �I�y���[�^�[����̕s�����͂ɑ΂����ʃG���[���b�Z�[�W
#
# ���� : (���Ԃ�)�Ȃ�
#
    print "" > "/dev/stderr"
    print "�E����.....�I�H" > "/dev/stderr"
    print "������x���͂��ĉ�����" > "/dev/stderr"
    print "" > "/dev/stderr"
}

function _ReadWBSTable() {
#
# �ړI : ���[�N�{�[�h�T�C�Y��`�t�@�C����ǂݍ���Ŕz���p�ӂ���
#
# ���� : ���[�N�{�[�h��`�t�@�C���̓J�����g�f�B���N�g���ɑ��݂��Ȃ���΂Ȃ�Ȃ�
#
# �ϐ�/�z��/�A�z�z�� : WBSTableCount / ���[�N�{�[�h�T�C�Y��`�t�@�C���̍ő�o�^��
#                    : WBSDef[...] / ���[�N�{�[�h�T�C�Y�o�^���Ԃ�Y���Ƃ���z��
#
    WBSTableCount = 0

    while (getline < "wbs.tbl" > 0) {
        if ($1 !~/\#/) {
            WBSTableCount++
            WBSDef[WBSTableCount] = $0
        }
    }
    close("wbs.tbl")
}

function _ReadPenTable() {
#
# �ړI : �y����`�t�@�C����ǂݍ���Ŕz��/�A�z�z���p�ӂ���
#
# ���� : �y����`�t�@�C���̓J�����g�f�B���N�g���ɑ��݂��Ȃ���΂Ȃ�Ȃ�
#
# �ϐ�/�z��/�A�z�z�� : MaxPenNumber / �y����`�t�@�C���̍ő�o�^��
#                    : _Temp[...] / split() ����������e���|�����z��
#                    : PenNumber[...] / �y���o�^���Ԃ�Y���Ƃ���z��
#                    : PenColorJ[...] / �y���F(���{��)��Y���Ƃ���A�z�z��
#                    : PenColorE[...] / �y���F(�p��)��Y���Ƃ���A�z�z��
#
    MaxPenNumber = 0

    while (getline < "pen.tbl" > 0) {
        if ($0 !~/\#/) {
            MaxPenNumber++
            split($0, _Temp, ":")
            PenNumber[MaxPenNumber] = $0
            PenColorE[_Temp[2]] = $0
            PenColorJ[_Temp[3]] = $0
        }
    }
    close("pen.tbl")
}

function _Space(n) {
#
# �ړI : �X�y�[�X��n�}������
#
    if (n == 0)
        return ("")
    else if (n == 1)
        return (" ")
    else
        return (" " _Space(n - 1))
}

function _RmTempFiles() {
#
# �ړI : �e���|�����t�@�C�����폜����
#
    vTempFiles = ToolFile2"," \
                 ToolFile3"," \
                 ToolFile4
    gsub(/ /, "", vTempFiles)
    split(vTempFiles, TempFile, ",")
    for (i in TempFile) {
        vErrorFlag = _Test(TempFile[i])
        if (vErrorFlag != -1)
            system(vRM" "TempFile[i])
    }
}
