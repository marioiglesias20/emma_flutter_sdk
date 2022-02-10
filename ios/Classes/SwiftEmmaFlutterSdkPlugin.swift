import Flutter
import UIKit
import EMMA_iOS

extension FlutterAppDelegate : EMMAPushDelegate {
    public func onPushOpen(_ push: EMMAPush) {
        let _ = push.params
        // treat params
    }
}

/** This implementation replaces push methods on AppDelegate  */
class EMMAFlutterAppDelegate {
    
    let appDelegate = UIApplication.shared.delegate
    
    init() {
        
    }
    
    @objc
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        EMMA.registerToken(deviceToken)
        if appDelegate != nil && appDelegate!.responds(to: #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))) {
            appDelegate?.application?(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        }
    }
    
    @objc
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    @objc
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Error registering notifications \(error.localizedDescription)");
    }
    
    @objc
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,  willPresent notification: UNNotification, withCompletionHandler   completionHandler: @escaping (_ options:   UNNotificationPresentationOptions) -> Void) {
        EMMA.handlePush(userInfo: notification.request.content.userInfo)
        completionHandler([.badge, .sound])
    }
    
    @objc
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        EMMA.handlePush(userInfo: response.notification.request.content.userInfo, actionIdentifier: response.actionIdentifier)
        completionHandler()
    }
    
    @available(iOS 10.0, *)
    public func swizzlePushMethods() {
        let appDelegate = UIApplication.shared.delegate as! FlutterAppDelegate
        let appDelegateClass: AnyClass? = object_getClass(appDelegate)
        
        var swizzles = Array<(Selector, Selector)>()
        
        swizzles.append((#selector(FlutterAppDelegate.application(_:didRegister:)),
                         #selector(EMMAFlutterAppDelegate.self.application(_:didRegister:))))
        
        swizzles.append((#selector(FlutterAppDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:)),
                         #selector(EMMAFlutterAppDelegate.self.application(_:didFailToRegisterForRemoteNotificationsWithError:))))
        
        swizzles.append((#selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)),
                         #selector(EMMAFlutterAppDelegate.self.userNotificationCenter(_:willPresent:withCompletionHandler:))))
        
        swizzles.append((#selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)),
                         #selector(EMMAFlutterAppDelegate.self.userNotificationCenter(_:didReceive:withCompletionHandler:))))
        
        swizzles.append((#selector(FlutterAppDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)),
                         #selector(EMMAFlutterAppDelegate.self.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))))
        
        
        for s in swizzles {
            
            let originalSelector = s.0
            let swizzledSelector = s.1
            
            guard let swizzledMethod = class_getInstanceMethod(EMMAFlutterAppDelegate.self, swizzledSelector) else {
                return
            }
            
            if let originalMethod = class_getInstanceMethod(appDelegateClass, originalSelector)  {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            } else {
                class_addMethod(appDelegateClass, swizzledSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            }
        }
    }
}

public class SwiftEmmaFlutterSdkPlugin: NSObject, FlutterPlugin {
    
    private let channel: FlutterMethodChannel
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "emma_flutter_sdk", binaryMessenger: registrar.messenger())
        let instance = SwiftEmmaFlutterSdkPlugin(channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    public init(_ channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getEMMAVersion":
            result(EMMA.getSDKVersion())
            break
        case "startSession":
            startSession(call, result)
            break
        case "trackEvent":
            trackEvent(call, result)
            break
        case "trackExtraUserInfo":
            trackExtraUserInfo(call, result)
            break
        case "loginUser":
            loginUser(call, result)
            break
        case "registerUser":
            registerUser(call, result)
            break
        case "inAppMessage":
            inappMessage(call, result)
            break
        case "startPushSystem":
            setPushDelegates()
            result(nil)
            break
        case "sendInAppImpression":
            sendInAppImpressionOrClick(isInAppImpression:true , call, result)
            break
        case "sendInAppClick":
            sendInAppImpressionOrClick(isInAppImpression:false , call, result)
            break
        case "openNativeAd":
            openNativeAd(call, result)
            break
        case "startOrder":
            startOrder(call, result)
            break
        case "addProduct":
            addProduct(call, result)
            break
        case "trackOrder":
            trackOrder(call, result)
            break
        case "cancelOrder":
            cancelOrder(call, result)
            break
        case "requestTrackingWithIdfa":
            requestTrackingWithIdfa(call, result)
            break
        case "trackUserLocation":
            trackLocation(call, result);
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    func startSession(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, AnyObject> else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't find args",
                                     details: nil))
            return
        }
        
        guard let sessionKey = args["sessionKey"] as? String else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't find Session Key",
                                     details: nil))
            return
        }
        
        guard let debugEnabled = args["debugEnabled"] as? Bool else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Debug Enabled is not boolean",
                                     details: nil))
            return
        }
        
        let configuration = EMMAConfiguration()
        configuration.debugEnabled = debugEnabled
        configuration.sessionKey = sessionKey
        EMMA.startSession(with: configuration)
        
        result(nil)
    }
    
    func trackEvent(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, AnyObject> else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't find args",
                                     details: nil))
            return
        }
        
        guard let eventToken = args["eventToken"] as? String else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't find Event Token",
                                     details: nil))
            return
        }
        
        let eventRequest = EMMAEventRequest(token: eventToken)
        if let eventAttributes = args["eventAttributes"] as? Dictionary<String, AnyObject>  {
            eventRequest.attributes = eventAttributes
        }
        EMMA.trackEvent(request: eventRequest)
        result(nil)
    }
    
    func trackExtraUserInfo(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, AnyObject> else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't find args",
                                     details: nil))
            return
        }
        guard let userAttributes = args["extraUserInfo"] as? Dictionary<String, String> else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't user arguments",
                                     details: nil))
            return
        }
        EMMA.trackExtraUserInfo(info: userAttributes)
        result(nil)
    }
    
    func loginUser(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, AnyObject> else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't find args",
                                     details: nil))
            return
        }
        
        guard let userId = args["userId"] as? String else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't get userId",
                                     details: nil))
            return
        }
        
        let email = args["email"] as? String ?? ""
        let extras = args["extras"] as? Dictionary<String, String>
        
        EMMA.loginUser(userId: userId, forMail: email, andExtras: extras)
        result(nil)
    }
    
    func registerUser(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, AnyObject> else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't find args",
                                     details: nil))
            return
        }
        
        guard let userId = args["userId"] as? String else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't get userId",
                                     details: nil))
            return
        }
        
        let email = args["email"] as? String ?? ""
        let extras = args["extras"] as? Dictionary<String, String>
        
        EMMA.registerUser(userId:userId, forMail: email, andExtras: extras)
        result(nil)
    }
    
    func inappMessage(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, AnyObject> else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't find args",
                                     details: nil))
            return
        }
        
        guard let inAppType = args["inAppType"] as? String else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't get inAppType",
                                     details: nil))
            return
        }
        
        guard let requestType = EmmaSerializer.inAppTypeFromString(inAppType: inAppType) else {
            result(FlutterError.init(code: "BAD_INAPP_TYPE",
                                     message: "Unknown inapp type",
                                     details: nil))
            return
        }
        
        if (requestType == InAppType.NativeAd) {
            let request = EMMANativeAdRequest()
            
            guard let templateId = args["templateId"] as? String else {
                result(FlutterError.init(code: "BAD_TEMPLATE_ID",
                                         message: "Unknown template id in request",
                                         details: nil))
                return
            }
            
            let batch = args["batch"] as? Bool ?? false
            
            request.templateId = templateId
            request.isBatch = batch
            
            
            
            EMMA.inAppMessage(request: request, withDelegate: self)
        } else {
            let request = EMMAInAppRequest(type: requestType)
            EMMA.inAppMessage(request: request)
        }
        
        result(nil)
    }
    
    func setPushDelegates() {
        if let applicationDelegate = UIApplication.shared.delegate as? FlutterAppDelegate {
            let pushDelegate = EMMAFlutterAppDelegate()
            if #available(iOS 10.0, *) {
                pushDelegate.swizzlePushMethods()
                EMMA.setPushNotificationsDelegate(delegate: applicationDelegate)
            }
            EMMA.setPushSystemDelegate(delegate: applicationDelegate)
        }
       
        EMMA.startPushSystem()
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        guard let notification = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] else {
            return true
        }
        setPushDelegates()
        EMMA.handlePush(userInfo: notification as! Dictionary<AnyHashable, Any>)
        
        return true
    }
    
    func sendInAppImpressionOrClick(isInAppImpression: Bool, _ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, AnyObject> else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't find args",
                                     details: nil))
            return
        }
        
        guard let type = args["type"] as? String else {
            result(FlutterError.init(code: "BAD_INAPP_TYPE",
                                     message: "Unknown inapp type",
                                     details: nil))
            return
        }
        
        guard let campaignId = args["campaignId"] as? Int else {
            result(FlutterError.init(code: "BAD_CAMPAIGN_ID",
                                     message: "Unknown campaign id",
                                     details: nil))
            return
        }
        
        
        guard let campaignType = EmmaSerializer.inAppTypeFromString(inAppType: type) else {
            result(FlutterError.init(code: "BAD_INAPP_TYPE",
                                     message: "Not supported inapp type",
                                     details: nil))
            return
        }
        
        guard let communicationType = EmmaSerializer.inAppTypeToCommType(type: campaignType) else {
            result(FlutterError.init(code: "BAD_CAMPAIGN_TYPE",
                                     message: "Not supported campaign type",
                                     details: nil))
            return
        }
        
        if (isInAppImpression) {
            EMMA.sendImpression(campaignType: communicationType, withId: String(campaignId))
        } else {
            EMMA.sendClick(campaignType: communicationType, withId: String(campaignId))
        }

       result(nil)
    }
    
    func openNativeAd(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, AnyObject> else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't find args",
                                     details: nil))
            return
        }
        
        guard let id = args["id"] as? Int else {
            result(FlutterError.init(code: "BAD_CAMPAIGN_ID",
                                     message: "Unknown campaign id",
                                     details: nil))
            return
        }
        
        EMMA.openNativeAd(campaignId: String(id))
        result(nil)
    }

    func startOrder(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {         
        guard let args = call.arguments as? Dictionary<String, AnyObject> else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't find args",
                                     details: nil))
            return
        }
        
        guard let orderId = args["orderId"] as? String else {
            result(FlutterError.init(code: "BAD_ORDER_ID",
                                     message: "Unknown order id",
                                     details: nil))
            return
        }
        
        guard let totalPrice = args["totalPrice"] as? Float else {
            result(FlutterError.init(code: "BAD_PRICE",
                                     message: "Unknown total price",
                                     details: nil))
            return
        }

        guard let customerId = args["customerId"] as? String else {
            result(FlutterError.init(code: "BAD_CUSTOMER_ID",
                                     message: "Unknown customer id",
                                     details: nil))
            return
        }
        
        
        if let currencyCode = args["currencyCode"] as? String {
            EMMA.setCurrencyCode(currencyCode: currencyCode)
        }

        let coupon = args["coupon"] as? String
        let extras = args["extras"] as? Dictionary<String, String>
        
        EMMA.startOrder(orderId: orderId, andCustomer: customerId, withTotalPrice: totalPrice, withExtras: extras, assignCoupon: coupon)
        result(nil)
    }
    
    func addProduct(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, AnyObject> else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't find args",
                                     details: nil))
            return
        }
        
        guard let productId = args["productId"] as? String else {
            result(FlutterError.init(code: "BAD_PRODUCT_ID",
                                     message: "Unknown product id",
                                     details: nil))
            return
        }
        
        guard let productName = args["productName"] as? String else {
            result(FlutterError.init(code: "BAD_PRODUCT_NAME",
                                     message: "Unknown product name",
                                     details: nil))
            return
        }

        guard let quantity = args["quantity"] as? Float else {
            result(FlutterError.init(code: "BAD_QUANTITY_ID",
                                     message: "Unknown quantity id",
                                     details: nil))
            return
        }
        
        guard let price = args["price"] as? Float else {
            result(FlutterError.init(code: "BAD_PRICE",
                                     message: "Unknown price",
                                     details: nil))
            return
        }
        
        

        let extras = args["extras"] as? Dictionary<String, String>
        
        EMMA.addProduct(productId: productId, andName: productName, withQty: quantity, andPrice: price, withExtras: extras)
        result(nil)
    }
    
    func trackOrder(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        EMMA.trackOrder()
        result(nil)
    }

    func cancelOrder(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, AnyObject> else {
            result(FlutterError.init(code: "BAD_ARGS",
                                     message: "Can't find args",
                                     details: nil))
            return
        }
        
        guard let orderId = args["orderId"] as? String else {
            result(FlutterError.init(code: "BAD_ORDER_ID",
                                     message: "Unknown order id",
                                     details: nil))
            return
        }


        EMMA.cancelOrder(orderId: orderId);
        result(nil)
    }
    
    func requestTrackingWithIdfa(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        if #available(iOS 14.0, *) {
            DispatchQueue.main.async {
                EMMA.requestTrackingWithIdfa()
            }
        }
        result(nil)
    }

    func trackLocation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            EMMA.trackLocation()
        }
        result(nil)
    }
}

extension SwiftEmmaFlutterSdkPlugin: EMMAInAppMessageDelegate {
    public func onReceiveNativeAds(_ nativeAds: [EMMANativeAd]) {
        let convertedNativeAd = nativeAds.map({(nativeAd) -> [String: Any?] in
            return EmmaSerializer.nativeAdToDictionary(nativeAd)
        })
        DispatchQueue.main.async {
            self.channel.invokeMethod("Emma#onReceiveNativeAds", arguments: convertedNativeAd)
        }
    }
    
    public func onShown(_ campaign: EMMACampaign) {
        // Not implemented
    }
    
    public func onHide(_ campaign: EMMACampaign) {
        // Not implemented
    }
    
    public func onClose(_ campaign: EMMACampaign) {
        // Not implemented
    }

    public func onReceived(_ nativeAd: EMMANativeAd) {
        onReceiveNativeAds([nativeAd])
    }
    
    public func onBatchNativeAdReceived(_ nativeAds: [EMMANativeAd]) {
        onReceiveNativeAds(nativeAds)
    }
}
