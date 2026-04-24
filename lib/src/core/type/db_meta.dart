// ignore_for_file: non_constant_identifier_names

class DBMeta {
  static final int Flag_Delete = 0;
  static final int Flag_Active = 1;

  static bool isActive(int flag) {
    return flag == Flag_Active ? true : false;
  }

  static bool isDeleted(int flag) {
    return flag == Flag_Delete ? true : false;
  }
}
