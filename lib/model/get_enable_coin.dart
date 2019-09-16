// To parse this JSON data, do
//
//     final getEnabledCoin = getEnabledCoinFromJson(jsonString);

import 'dart:convert';

GetEnabledCoin getEnabledCoinFromJson(String str) =>
    GetEnabledCoin.fromJson(json.decode(str));

String getEnabledCoinToJson(GetEnabledCoin data) {
  final Map<String, dynamic> dyn = data.toJson();
  if (data.swapContractAddress.isEmpty) {
    dyn.remove('swap_contract_address');
  }
  return json.encode(dyn);
}

class GetEnabledCoin {
  GetEnabledCoin({
    this.userpass,
    this.method = 'enable',
    this.coin,
    this.urls,
    this.txHistory,
    this.swapContractAddress,
  });

  factory GetEnabledCoin.fromJson(Map<String, dynamic> json) =>
      GetEnabledCoin(
        userpass: json['userpass'] ?? '',
        method: json['method'] ?? '',
        coin: json['coin'] ?? '',
        txHistory: json['tx_history'] ?? false,
        urls: List<String>.from(json['urls'].map((dynamic x) => x)) ?? <String>[],
        swapContractAddress: json['swap_contract_address'] ?? '',
      );

  String userpass;
  String method;
  String coin;
  List<String> urls;
  String swapContractAddress;
  bool txHistory;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userpass': userpass ?? '',
        'method': method ?? '',
        'coin': coin ?? '',
        'tx_history': txHistory ?? false,
        'urls': List<dynamic>.from(urls.map<dynamic>((String x) => x)) ?? <String>[],
        'swap_contract_address': swapContractAddress ?? '',
      };
}
