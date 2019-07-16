import Foundation
import FoundationNetworking
import Dispatch
import Glibc

let flowkeyUrl = URL(string: "http://flowkey.com")!
URLSession.shared.dataTask(with: flowkeyUrl) { (data, response, error) in
    if let error = error {
        print(error)
        return
    }

    guard let data = data, let response = response else {
        assertionFailure("Unknown error!")
        return
    }

    print(data, response)
}.resume()


print(UUID())


RunLoop.current.run(until: Date().addingTimeInterval(5))
