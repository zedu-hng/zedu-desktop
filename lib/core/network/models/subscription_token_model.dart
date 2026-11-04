/// A Centrifugo channel subscription token, pairing the requested channel with
/// the token returned by `POST /token/subscription`.
class SubscriptionTokenModel {
  const SubscriptionTokenModel({required this.channel, required this.token});

  final String channel;
  final String token;

  factory SubscriptionTokenModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionTokenModel(
      channel: json['channel']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'channel': channel, 'token': token};
}
