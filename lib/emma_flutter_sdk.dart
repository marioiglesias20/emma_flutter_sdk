import 'dart:async';

import 'package:flutter/services.dart';
import 'package:emma_flutter_sdk/src/defines.dart';
import 'package:emma_flutter_sdk/src/inapp_message_request.dart';
import 'package:emma_flutter_sdk/src/native_ad.dart';
import 'package:emma_flutter_sdk/src/order.dart';
import 'package:emma_flutter_sdk/src/product.dart';

export 'src/defines.dart';
export 'src/native_ad.dart';
export 'src/inapp_message_request.dart';
export 'src/order.dart';
export 'src/product.dart';

typedef void ReceivedNativeAdsHandler(List<EmmaNativeAd> nativeAds);
typedef void PermissionStatusHandler(PermissionStatus status);

class EmmaFlutterSdk {
  static EmmaFlutterSdk shared = new EmmaFlutterSdk();

  // method channels
  MethodChannel _channel = const MethodChannel('emma_flutter_sdk');

  // event handlers
  ReceivedNativeAdsHandler _onReceivedNativeAds;
  PermissionStatusHandler _onPermissionStatus;

  EmmaFlutterSdk() {
    this._channel.setMethodCallHandler(_manageCallHandler);
  }

  Future<Null> _manageCallHandler(MethodCall call) async {
    switch (call.method) {
      case "Emma#onReceiveNativeAds":
        List<dynamic> nativeAdsMap = call.arguments;
        this._onReceivedNativeAds(nativeAdsMap
            .map((nativeAdMap) =>
                new EmmaNativeAd.fromMap(nativeAdMap.cast<String, dynamic>()))
            .toList());
        break;
      case "Emma#onPermissionStatus":
        int permissionStatusIndex = call.arguments;
        this._onPermissionStatus(
            PermissionStatus.values[permissionStatusIndex]);
        break;
    }
    return null;
  }

  void setReceivedNativeAdsHandler(ReceivedNativeAdsHandler handler) =>
      _onReceivedNativeAds = handler;

  void setPermissionStatusHandler(PermissionStatusHandler handler) =>
      _onPermissionStatus = handler;

  /// Retrieves current EMMA SDK Version
  Future<String> getEMMAVersion() async {
    final String version = await _channel.invokeMethod('getEMMAVersion');
    return version;
  }

  /// Starts EMMA Session with a [sessionKey].
  ///
  /// You can use [debugEnabled] to enable logging on your device.
  /// This log is only visible on device consoles
  Future<void> startSession(String sessionKey,
      {bool debugEnabled = false}) async {
    return await _channel.invokeMethod('startSession',
        {'sessionKey': sessionKey, 'debugEnabled': debugEnabled});
  }

  /// Send an event to emma identified by [eventToken].
  /// You can also assign some attributtes to this event with [eventArguments]
  Future<void> trackEvent(String eventToken,
      {Map<String, String> eventArguments}) async {
    return await _channel.invokeMethod('trackEvent',
        {'eventToken': eventToken, 'eventArguments': eventArguments});
  }

  /// You can complete user profile with extra parameters
  Future<void> trackExtraUserInfo(Map<String, String> extraUserInfo) async {
    return await _channel
        .invokeMethod('trackExtraUserInfo', {'extraUserInfo': extraUserInfo});
  }

  /// Sends a login to EMMA
  /// [userId] is your customer id for this user
  /// [email] is a unique email of this user
  Future<void> loginUser(String userId, String email) async {
    return await _channel
        .invokeMethod('loginUser', {'userId': userId, 'email': email});
  }

  /// Sends register event to EMMA
  /// [userId] is your customer id for this user
  /// [email] is a unique email of this user
  Future<void> registerUser(String userId, String email) async {
    return await _channel
        .invokeMethod('registerUser', {'userId': userId, 'email': email});
  }

  /// Checks for an InApp Message
  /// You must pass [EmmaInAppMessageRequest] of message you're expecting
  Future<void> inAppMessage(EmmaInAppMessageRequest request) async {
    return await _channel.invokeMethod('inAppMessage', request.toMap());
  }

  /// Init EMMA Push system
  /// You must define [notificationIcon] for Android OS
  /// Optional param [notificationChannel] to define notification channel name for Android OS. Default app name.
  /// Optional param [notificationChannelId] to subscribe an existent channel.
  Future<void> startPushSystem(String notificationIcon,
      {String notificationChannel = null,
      String notificationChannelId = null}) async {
    return await _channel.invokeMethod('startPushSystem', {
      'notificationIcon': notificationIcon,
      'notificationChannel': notificationChannel,
      'notificationChannelId': notificationChannelId
    });
  }

  /// Sends impression associated with inapp campaign. This method is mainly used to send native Ad impressions.
  /// Formats startview, banner, adball send impression automatically
  /// [campaignId] The campaign identifier
  Future<void> sendInAppImpression(InAppType inAppType, int campaignId) async {
    String type = inAppType.toString().split(".")[1];
    return await _channel.invokeMethod(
        'sendInAppImpression', {"type": type, "campaignId": campaignId});
  }

  /// Sends click associated with inapp campaign. This method is mainly used to send native ad clicks.
  /// Formats startview, banner, adball send click automatically
  /// [campaignId] The campaign identifier
  Future<void> sendInAppClick(InAppType inAppType, int campaignId) async {
    String type = inAppType.toString().split(".")[1];
    return await _channel.invokeMethod(
        'sendInAppClick', {"type": type, "campaignId": campaignId});
  }

  /// Opens native ad CTA inapp or outapp. This method track native ad click automatically. It is not necessary call to sendInAppClick method.
  /// [nativeAd] The native ad
  Future<void> openNativeAd(EmmaNativeAd nativeAd) async {
    return await _channel.invokeMethod('openNativeAd', nativeAd.toMap());
  }

  /// [Android Only] Checks if rich push is available after push is opened.
  /// This method can be called anywhere in app.
  Future<void> checkForRichPush() async {
    return await _channel.invokeMethod('checkForRichPush');
  }

  /// This method starts the order and save it.
  Future<void> startOrder(EmmaOrder order) async {
    return await _channel.invokeMethod('startOrder', order.toMap());
  }

  /// This method adds one product to the initied order. If you want add multiple
  /// products, you call this method multiples times.
  Future<void> addProduct(EmmaProduct product) async {
    return await _channel.invokeMethod('addProduct', product.toMap());
  }

  /// This method commits the order and send to server.
  Future<void> trackOrder() async {
    return await _channel.invokeMethod('trackOrder');
  }

  /// [iOS only] This method requests the permission to collect the IDFA.
  Future<void> requestTrackingWithIdfa() async {
    return await _channel.invokeMethod('requestTrackingWithIdfa');
  }

  /// This method allows track location
  Future<void> trackUserLocation() async {
    return await _channel.invokeMethod('trackUserLocation');
  }

  /// This method sends the customerId without using an event.
  Future<void> setCustomerId(String customerId) async {
    return await _channel.invokeMethod('setCustomerId', customerId);
  }

  /// [Android only] This method returns if devices can receive notifications or not.
  Future<bool> areNotificationsEnabled() async {
    return await _channel.invokeMethod('areNotificationsEnabled');
  }

  /// [Android only] This method requests notifications permission on Android 13 or higher devices.
  Future<void> requestNotificationsPermission() async {
    return await _channel.invokeMethod('requestNotificationsPermission');
  }
}
