#if !PMKCocoaPods
import PMKCancel
import PromiseKit
#endif
import StoreKit

extension SKReceiptRefreshRequest {
    public func promise() -> Promise<SKReceiptRefreshRequest> {
        return ReceiptRefreshObserver(request: self).promise
    }
}

private class ReceiptRefreshObserver: NSObject, SKRequestDelegate, CancellableTask {
    let (promise, seal) = Promise<SKReceiptRefreshRequest>.pending()
    let request: SKReceiptRefreshRequest
    var retainCycle: ReceiptRefreshObserver?
    
    init(request: SKReceiptRefreshRequest) {
        self.request = request
        super.init()
        request.delegate = self
        request.start()
        retainCycle = self
    }
    
    
    func requestDidFinish(_: SKRequest) {
        seal.fulfill(request)
        retainCycle = nil
    }
    
    func request(_: SKRequest, didFailWithError error: Error) {
        seal.reject(error)
        retainCycle = nil
    }

    var isCancelled = false
    
    func cancel() {
        request.cancel()
        retainCycle = nil
        isCancelled = true
    }
}

//////////////////////////////////////////////////////////// Cancellation

extension SKReceiptRefreshRequest {
    public func promiseCC() -> CancellablePromise<SKReceiptRefreshRequest> {
        let rro = ReceiptRefreshObserver(request: self)
        return CancellablePromise(task: rro, promise: rro.promise, resolver: rro.seal)
    }
}
