import PMKStoreKit
import PromiseKit
import StoreKit
import XCTest

class SKProductsRequestTests: XCTestCase {
    func test() {
        class MockProductsRequest: SKProductsRequest {
            override func start() {
                after(seconds: 0.1).done {
                    self.delegate?.productsRequest(self, didReceive: SKProductsResponse())
                }
            }
        }

        let ex = expectation(description: "")
        MockProductsRequest().start(.promise).done { _ in
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}

//////////////////////////////////////////////////////////// Cancellation

extension SKProductsRequestTests {
    func testCancel() {
        class MockProductsRequest: SKProductsRequest {            
            var isCancelled = false

            override func start() {
                after(seconds: 0.1).done {
                    if !self.isCancelled {
                        self.delegate?.productsRequest(self, didReceive: SKProductsResponse())
                    }
                }
            }
        }
        
        let ex = expectation(description: "")
        
        let request = MockProductsRequest()
        cancellable(request.start(.promise)).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        request.isCancelled = true
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
