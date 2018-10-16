import StoreKit
#if !PMKCocoaPods
import PromiseKit
#endif

/**
 To import the `SKRequest` category:

    use_frameworks!
    pod "PromiseKit/StoreKit"

 And then in your sources:

    import PromiseKit
*/
extension SKProductsRequest {
    /**
     Sends the request to the Apple App Store.

     - Returns: A promise that fulfills if the request succeeds.
     - Note: cancelling this promise will cancel the underlying task
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
    */
    public func start(_: PMKNamespacer) -> Promise<SKProductsResponse> {
        let proxy = SKDelegate(request: self)
        delegate = proxy
        proxy.retainCycle = proxy
        start()
        return proxy.promise
    }
}


fileprivate class SKDelegate: NSObject, SKProductsRequestDelegate, CancellableTask {
    let (promise, seal) = Promise<SKProductsResponse>.pending()
    let request: SKRequest
    var retainCycle: SKDelegate?

    init(request: SKRequest) {
        self.request = request
        super.init()
        promise.setCancellableTask(self, reject: seal.reject)
    }

    @objc fileprivate func request(_ request: SKRequest, didFailWithError error: Error) {
        seal.reject(error)
        retainCycle = nil
    }

    @objc fileprivate func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        seal.fulfill(response)
        retainCycle = nil
    }

    var isCancelled = false
    
    func cancel() {
        request.cancel()
        retainCycle = nil
        isCancelled = true
    }
}

// perhaps one day Apple will actually make their errors into Errors…
//extension SKError: CancellableError {
//    public var isCancelled: Bool {
//        return true
//    }
//}
