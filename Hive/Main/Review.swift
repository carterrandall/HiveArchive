import StoreKit

struct StoreReviewHelper {
    
    static func incrementAppOpenedCount() { // called from appdelegate didfinishLaunchingWithOptions:
        guard var appOpenCount = UserDefaults.standard.value(forKey: "APP_OPENED_COUNT") as? Int else {
            UserDefaults.standard.set(1, forKey: "APP_OPENED_COUNT")
            return
        }
        appOpenCount += 1
        UserDefaults.standard.set(appOpenCount, forKey: "APP_OPENED_COUNT")
    }
    
    static func checkAndAskForReview() { // call this whenever appropriate
        // this will not be shown everytime. Apple has some internal logic on how to show this.
        guard let appOpenCount = UserDefaults.standard.value(forKey: "APP_OPENED_COUNT") as? Int else {
            UserDefaults.standard.set(1, forKey: "APP_OPENED_COUNT")
            return
        }
        
        if let daysSinceLast = UserDefaults.standard.value(forKey: "DAYS_SINCE_LAST_REQUEST") as? Int, daysSinceLast > 50 {
            SKStoreReviewController.requestReview()
            UserDefaults.standard.set(0, forKey: "DAYS_SINCE_LAST_REQUEST")
        } else {
            if var daysSinceLast = UserDefaults.standard.value(forKey: "DAYS_SINCE_LAST_REQUEST") as? Int {
                daysSinceLast += 1
                if appOpenCount >= 10 && appOpenCount <= 50 && daysSinceLast > 10 {
                    SKStoreReviewController.requestReview()
                    UserDefaults.standard.set(0, forKey: "DAYS_SINCE_LAST_REQUEST")
                } else {
                    UserDefaults.standard.set(daysSinceLast, forKey: "DAYS_SINCE_LAST_REQUEST")
                }
            } else {
                UserDefaults.standard.set(0, forKey: "DAYS_SINCE_LAST_REQUEST")
            }
        }
        print("App run count is: \(appOpenCount)")
    }
}
