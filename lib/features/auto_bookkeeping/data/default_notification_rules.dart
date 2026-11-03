import 'package:equity_tracker/features/auto_bookkeeping/domain/models/notification_rule.dart';

const List<String> commonNegativeKeywords = [
  '驗證碼',
  'OTP',
  '動態密碼',
  '登入',
  '帳單',
  '繳費',
  '應繳',
  '最低應繳',
  '自動扣繳',
  '失敗',
  '未成功',
  '取消',
  '退款',
  '退貨',
  '優惠',
  '活動',
  '抽獎',
  '行銷',
  '廣告',
];

const List<String> commonExpenseKeywords = [
  '消費',
  '刷卡',
  '授權',
  '交易',
  '付款',
  '支付',
  '扣款',
  'NT\$',
  'TWD',
  '元',
];

final List<NotificationRule> defaultNotificationRules = [
  // 1. 玉山銀行 (包含實機實際出現之 com.esunbank 與 com.esunbank.ESUNWALLET)
  NotificationRule(
    id: 'preset_esun',
    name: '玉山銀行',
    packageNames: [
      'com.esunbank',
      'com.esunbank.ESUNWALLET',
      'com.esunbank.ewallet',
      'com.esunbank.android',
    ],
    titleKeywords: ['玉山', 'ESUN', '玉山Wallet'],
    bodyKeywords: commonExpenseKeywords,
    negativeKeywords: commonNegativeKeywords,
    defaultTransactionTitle: '玉山銀行刷卡',
    isSystemPreset: true,
  ),

  // 2. 國泰世華
  NotificationRule(
    id: 'preset_cathay',
    name: '國泰世華',
    packageNames: [
      'com.cathaybk.mymobibank.android',
      'com.cathaybk.koko.android',
    ],
    titleKeywords: ['國泰世華', 'CUBE', 'KOKO'],
    bodyKeywords: commonExpenseKeywords,
    negativeKeywords: commonNegativeKeywords,
    defaultTransactionTitle: '國泰世華刷卡',
    isSystemPreset: true,
  ),

  // 3. 中國信託
  NotificationRule(
    id: 'preset_ctbc',
    name: '中國信託',
    packageNames: [
      'com.chinatrust.mobilebank',
    ],
    titleKeywords: ['中國信託', '中信', 'CTBC'],
    bodyKeywords: commonExpenseKeywords,
    negativeKeywords: commonNegativeKeywords,
    defaultTransactionTitle: '中國信託刷卡',
    isSystemPreset: true,
  ),

  // 4. 台新銀行
  NotificationRule(
    id: 'preset_taishin',
    name: '台新銀行',
    packageNames: [
      'tw.com.taishinbank.mobile',
      'tw.com.taishinbank.richart',
    ],
    titleKeywords: ['台新', 'Richart', 'Taishin'],
    bodyKeywords: commonExpenseKeywords,
    negativeKeywords: commonNegativeKeywords,
    defaultTransactionTitle: '台新銀行刷卡',
    isSystemPreset: true,
  ),

  // 5. 台北富邦
  NotificationRule(
    id: 'preset_fubon',
    name: '台北富邦',
    packageNames: [
      'com.fubon.mbank',
    ],
    titleKeywords: ['台北富邦', '富邦', 'Fubon'],
    bodyKeywords: commonExpenseKeywords,
    negativeKeywords: commonNegativeKeywords,
    defaultTransactionTitle: '富邦銀行刷卡',
    isSystemPreset: true,
  ),

  // 6. 永豐銀行
  NotificationRule(
    id: 'preset_sinopac',
    name: '永豐銀行',
    packageNames: [
      'com.sinopac.mwallet',
      'com.sinopac.dawho',
    ],
    titleKeywords: ['永豐', 'DAWHO', '大戶'],
    bodyKeywords: commonExpenseKeywords,
    negativeKeywords: commonNegativeKeywords,
    defaultTransactionTitle: '永豐銀行刷卡',
    isSystemPreset: true,
  ),

  // 7. 聯邦銀行
  NotificationRule(
    id: 'preset_ubot',
    name: '聯邦銀行',
    packageNames: [
      'com.ubot.mbank',
    ],
    titleKeywords: ['聯邦', 'UBOT'],
    bodyKeywords: commonExpenseKeywords,
    negativeKeywords: commonNegativeKeywords,
    defaultTransactionTitle: '聯邦銀行刷卡',
    isSystemPreset: true,
  ),

  // 8. LINE Pay
  NotificationRule(
    id: 'preset_linepay',
    name: 'LINE Pay',
    packageNames: [
      'jp.naver.line.android',
      'com.linepayplus.mobileapp',
    ],
    titleKeywords: ['LINE Pay', 'LINE 錢包', 'LINE 錢包通知'],
    bodyKeywords: ['付款', '消費', '支付', '扣款', '扣款成功', '付款完成', 'NT\$', '元'],
    negativeKeywords: commonNegativeKeywords,
    defaultTransactionTitle: 'LINE Pay 消費',
    isSystemPreset: true,
  ),

  // 9. 街口支付
  NotificationRule(
    id: 'preset_jkopay',
    name: '街口支付',
    packageNames: [
      'com.jkos.app',
    ],
    titleKeywords: ['街口支付', '街口', 'JKOPAY'],
    bodyKeywords: commonExpenseKeywords,
    negativeKeywords: commonNegativeKeywords,
    defaultTransactionTitle: '街口支付消費',
    isSystemPreset: true,
  ),

  // 10. 全支付
  NotificationRule(
    id: 'preset_pxpayplus',
    name: '全支付',
    packageNames: [
      'com.pxpayplus.wallet',
      'com.pxmart.pxmartapp',
    ],
    titleKeywords: ['全支付', 'PXPay Plus'],
    bodyKeywords: commonExpenseKeywords,
    negativeKeywords: commonNegativeKeywords,
    defaultTransactionTitle: '全支付消費',
    isSystemPreset: true,
  ),

  // 11. 台灣 Pay
  NotificationRule(
    id: 'preset_taiwanpay',
    name: '台灣 Pay',
    packageNames: [
      'tw.com.twmp.mwallet',
    ],
    titleKeywords: ['台灣Pay', '台灣 Pay', 'Taiwan Pay'],
    bodyKeywords: commonExpenseKeywords,
    negativeKeywords: commonNegativeKeywords,
    defaultTransactionTitle: '台灣 Pay 消費',
    isSystemPreset: true,
  ),
];
