class AppConstants {
  static const String appTitle = 'Nordic Auto DFU';

  static const int scanTimeoutSeconds = 10;
  static const int scanUpdateIntervalMs = 500;
  static const int maxSerialLength = 5;
  static const int deviceListHeight = 400;

  static const String hiCardiPrefix = 'HiCardi-';
  static const String allFilter = '전체';

  static const List<String> modelFilters = [
    '전체',
    'HiCardi-',
    'HiCardi-A',
    'HiCardi-C',
    'HiCardi-D',
    'HiCardi-E',
    'HiCardi-M',
    'HiCardi-N'
  ];
}