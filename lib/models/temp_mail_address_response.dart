import 'package:json_annotation/json_annotation.dart';

part 'temp_mail_address_response.g.dart';

@JsonSerializable()
class TempMailAddressResponse {
  final String address;

  TempMailAddressResponse({required this.address});

  factory TempMailAddressResponse.fromJson(Map<String, dynamic> json) =>
      _$TempMailAddressResponseFromJson(json);
}
