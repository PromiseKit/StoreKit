#if !PMKCocoaPods
import PromiseKit
#endif
import StoreKit

extension SKPaymentQueue {
    public func restoreCompletedTransactions(_: PMKNamespacer) -> Promise<[SKPaymentTransaction]> {
        return PaymentObserver(self).promise
    }

    public func restoreCompletedTransactions(_: PMKNamespacer, withApplicationUsername username: String?) -> Promise<[SKPaymentTransaction]> {
        return PaymentObserver(self, withApplicationUsername: true, userName: username).promise
    }
}

private class PaymentObserver: NSObject, SKPaymentTransactionObserver {
    let (promise, seal) = Promise<[SKPaymentTransaction]>.pending()
    var retainCycle: PaymentObserver?
    var transactions = [SKPaymentTransaction]()

    init(_ paymentQueue: SKPaymentQueue, withApplicationUsername: Bool = false, userName: String? = nil) {
        super.init()
        paymentQueue.add(self)
        withApplicationUsername ?
            paymentQueue.restoreCompletedTransactions() :
            paymentQueue.restoreCompletedTransactions(withApplicationUsername: userName)
        retainCycle = self
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        self.transactions += transactions.filter { $0.transactionState == .restored }
        transactions.forEach(queue.finishTransaction)
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        finish(queue)
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        finish(queue, with: error)
    }

    func finish(_ queue: SKPaymentQueue, with error: Error? = nil) {
        if let error = error {
            seal.reject(error)
        } else {
            seal.fulfill(transactions)
        }

        queue.remove(self)
        retainCycle = nil
    }
}
