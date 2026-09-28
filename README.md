# fidra-iap-swift

FidraIAP là một thư viện mua hàng trong ứng dụng (In-App Purchase) cho ứng dụng iOS, giúp đơn giản hóa quá trình tích hợp, xác thực và quản lý các giao dịch mua hàng.

## Tính năng chính

- Tích hợp dễ dàng với StoreKit để xử lý mua hàng trong ứng dụng
- Hỗ trợ xác thực giao dịch thông qua server để ngăn chặn gian lận
- Tích hợp với FidraRemoteConfig để quản lý cấu hình sản phẩm từ xa
- Hỗ trợ các loại sản phẩm: tiêu thụ, không tiêu thụ và đăng ký
- Lưu trữ và khôi phục lịch sử giao dịch

## Cài đặt

### Swift Package Manager

```swift
    package(url: "https://gitlab.volio.vn/fidra/libs/fidra-iap-swift.git", from: "1.0.0")
```

## Sử dụng cơ bản

### Lấy thông tin sản phẩm

```swift
// Lấy danh sách sản phẩm có sẵn
let products = await FidraIAP.shared.getProducts()

// Hiển thị thông tin sản phẩm
for product in products {
    print("Product ID: \(product.productIdentifier)")
    print("Price: \(product.price) \(product.priceLocale.currencySymbol!)")
    print("Description: \(product.localizedDescription)")
}
```

### Thực hiện mua hàng

```swift
// Mua sản phẩm bằng ID
let result = await FidraIAP.shared.purchase(productID: "com.yourapp.premium")

switch result {
case .success(let transaction):
    print("Mua hàng thành công: \(transaction.productID)")
    // Cung cấp nội dung hoặc tính năng cho người dùng
    
case .userCancelled:
    print("Người dùng đã hủy giao dịch")
    
case .failed(let error):
    print("Lỗi mua hàng: \(error.localizedDescription)")
    
case .pending:
    print("Giao dịch đang chờ xử lý")
}
```

### Khôi phục giao dịch

```swift
// Khôi phục các giao dịch đã mua trước đó
let restoreResult = await FidraIAP.shared.restorePurchases()

switch restoreResult {
case .success(let transactions):
    print("Đã khôi phục \(transactions.count) giao dịch")
    for transaction in transactions {
        print("Khôi phục: \(transaction.productID)")
    }
    
case .failed(let error):
    print("Khôi phục thất bại: \(error.localizedDescription)")
    
case .nothingToRestore:
    print("Không có giao dịch nào để khôi phục")
}
```

### Kiểm tra trạng thái mua hàng

```swift
// Kiểm tra xem sản phẩm có được mua hay không
let isPurchased = FidraIAP.shared.isProductPurchased("com.yourapp.premium")

// Kiểm tra đăng ký có đang hoạt động không
let isSubscriptionActive = await FidraIAP.shared.isSubscriptionActive("com.yourapp.subscription")
```

## Xác thực giao dịch

```swift
// Xác thực giao dịch thông qua máy chủ
let isValid = await FidraIAP.shared.verifyPurchase(
    productID: "com.yourapp.premium",
    receiptData: receiptData
)

if isValid {
    print("Giao dịch hợp lệ")
} else {
    print("Giao dịch không hợp lệ")
}
```

## Yêu cầu hệ thống

- iOS 14.0+
- Swift 5.5+
- StoreKit

## Giấy phép

Copyright © 2025 Fidra. Mọi quyền được bảo lưu. 
