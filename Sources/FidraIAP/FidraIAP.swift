//
//  IAPManager.swift
//  FidraCore
//

import StoreKit
import Foundation

/// Kết quả từ các giao dịch IAP
public enum IAPResult<T> {
    case success(T)
    case failure(Error)
    case userCancelled
    case pending
    case unverified
}

/// Các lỗi có thể xảy ra trong quá trình IAP
public enum IAPError: Error, LocalizedError {
    case productNotFound
    case purchaseFailed(String)
    case restoreFailed(String)
    case verificationFailed
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .productNotFound: return "Không tìm thấy sản phẩm"
        case .purchaseFailed(let reason): return "Mua hàng thất bại: \(reason)"
        case .restoreFailed(let reason): return "Khôi phục thất bại: \(reason)"
        case .verificationFailed: return "Xác minh giao dịch thất bại"
        case .networkError(let error): return "Lỗi mạng: \(error.localizedDescription)"
        }
    }
}

/// Delegate để nhận thông báo về các sự kiện IAP
public protocol FidraIAPDelegate: AnyObject {
    func didPurchaseProduct(productId: String, expiryDate: Date?)
    func didRestoreProduct(productId: String, expiryDate: Date?)
    func didFailWithError(_ error: Error)
}

public final class FidraIAPManager: NSObject {
    
    private var productsRequest: SKProductsRequest?
    private var availableProducts: [SKProduct] = []
    private var productIdentifiers: Set<String> = []
    public var productsLoadedCallback: (([SKProduct]) -> Void)?
    
    public weak var delegate: FidraIAPDelegate?
    public var customStorageHandler: ((String, Date?) -> Void)?
    
    /// Tùy chọn lấy thời gian hiện tại từ server
    public var currentTimeProvider: (() async -> Double)?
    
    public override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    public func initialize(productIds: Set<String>) {
        self.productIdentifiers = productIds
        fetchProducts()
    }
    
    public func fetchProducts() {
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
        self.productsRequest = request
    }
    
    public func purchase(productId: String) {
        guard let product = availableProducts.first(where: { $0.productIdentifier == productId }) else { return }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    private func storeLifetimePurchase(for productId: String) {
        UserDefaults.standard.set(true, forKey: "lifetime_\(productId)")
        UserDefaults.standard.set(true, forKey: "hasLifetimePremium")
        UserDefaults.standard.set(Date(), forKey: "lifetimePurchaseDate")
    }
    
    public func hasLifetimePurchase() -> Bool {
        return UserDefaults.standard.bool(forKey: "hasLifetimePremium")
    }
    
    private func storeExpiryDate(for productId: String, date: Date?) {
        if let handler = customStorageHandler {
            handler(productId, date)
        } else {
            UserDefaults.standard.set(date, forKey: "premiumExpiryDate")
        }
    }
    
    public func getPremiumExpiryDate() -> Date? {
        return UserDefaults.standard.object(forKey: "premiumExpiryDate") as? Date
    }
    
    public func isPremium() async -> Bool {
        if hasLifetimePurchase() {
            return true
        }
        guard let expiry = getPremiumExpiryDate() else { return false }
        
        let currentTime = await getCurrentTime()
        let currentDate = Date(timeIntervalSince1970: currentTime)
        return currentDate < expiry
    }
    
    public func getCurrentTime() async -> Double {
        if let timeProvider = currentTimeProvider {
            return await timeProvider()
        }
        return Date().timeIntervalSince1970
    }
}

extension FidraIAPManager: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.availableProducts = response.products
        productsLoadedCallback?(response.products)
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        delegate?.didFailWithError(error)
    }
}

extension FidraIAPManager: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            handleTransaction(transaction)
        }
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("Restore completed")
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        delegate?.didFailWithError(error)
    }
    
    private func handleTransaction(_ transaction: SKPaymentTransaction) {
        let productId = transaction.payment.productIdentifier
        switch transaction.transactionState {
        case .purchased:
            storeLifetimePurchase(for: productId)
            delegate?.didPurchaseProduct(productId: productId, expiryDate: nil)
            SKPaymentQueue.default().finishTransaction(transaction)
        case .restored:
            storeLifetimePurchase(for: productId)
            delegate?.didRestoreProduct(productId: productId, expiryDate: nil)
            SKPaymentQueue.default().finishTransaction(transaction)
        case .failed:
            if let error = transaction.error {
                delegate?.didFailWithError(error)
            }
            SKPaymentQueue.default().finishTransaction(transaction)
        default:
            break
        }
    }
}
