class AppConstants {
  static const String tenMinuteMailBaseUrl = 'https://10minutemail.com';
  static const String couponViewUrl = 'https://api.couponcarrier.io/r/9LOxbo56';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const couponUrl =
      'https://4ae2fa2d.sibforms.com/serve/MUIFABh2PsygNz9jKC6q8zxEe0o1XXnXc91P1gftLQX58CLCNgQIExYezVJ9TuAtxu67Aofpz0Trfn2AwujSbXVAWNPpi0XCeyz5vFFs-A7XoZqMx5LGeMI968D-Uzqp9F3x5UHVoPFuyL2ZDGDU2Qny8duMSeMG0H2OYwRbJox41eHS9C75kpavQpS5uRsQLLOhauL3mIVrEUY=';
  static const int jobExpiringInMinutes = 10;
  static const int maxTries = 30;
  static const String emailSubject = "Kafijas kupons☕";
  static const String emailSender = "@pasts.narvesen.lv";
  static const String backgroundProcessCouponJobs = 'process_coupon_jobs';
}
