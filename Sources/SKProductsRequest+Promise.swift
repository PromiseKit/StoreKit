import StoreKit
#if !PMKCocoaPods
import PMKCancel
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
    */
    public func start(_: PMKNamespacer) -> Promise<SKProductsResponse> {
        let proxy = SKDelegate()
        delegate = proxy
        proxy.retainCycle = proxy
        start()
        return proxy.promise
    }
}


fileprivate class SKDelegate: NSObject, SKProductsRequestDelegate {
    let (promise, seal) = Promise<SKProductsResponse>.pending()
    var retainCycle: SKDelegate?

    @objc fileprivate func request(_ request: SKRequest, didFailWithError error: Error) {
        seal.reject(error)
        retainCycle = nil
    }

    @objc fileprivate func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        seal.fulfill(response)
        retainCycle = nil
    }
}

// perhaps one day Apple will actually make their errors into Errors…
//extension SKError: CancellableError {
//    public var isCancelled: Bool {
//        return true
//    }
//}

//////////////////////////////////////////////////////////// Cancellation

extension SKProductsRequest {
    /**
     Sends the request to the Apple App Store.
     
     - Returns: A cancellable promise that fulfills if the request succeeds.
     */
    public func startCC(_: PMKNamespacer) -> CancellablePromise<SKProductsResponse> {
        let proxy = SKDelegate()
        delegate = proxy
        proxy.retainCycle = proxy
        let cp = CancellablePromise(task: SKRequestTask(self, proxy), promise: proxy.promise, resolver: proxy.seal)

        start()
        return cp
    }
}

fileprivate class SKRequestTask: CancellableTask {
    let request: SKRequest
    let proxy: SKDelegate

    init(_ request: SKRequest, _ proxy: SKDelegate) {
        self.request = request
        self.proxy = proxy
    }
    
    var isCancelled = false
    
    func cancel() {
        request.cancel()
        proxy.retainCycle = nil
        isCancelled = true
    }
}
