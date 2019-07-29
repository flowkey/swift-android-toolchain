import Foundation
import FoundationNetworking
import Dispatch
import Glibc

let fetchURL = URL(string: "http://www.idiomsite.com")!

print(fetchURL)
print(NSString("lolz"))

let session = URLSession(configuration: .default)
session.dataTask(with: fetchURL) { (data, response, error) in
    if let error = error {
        print("Error retrieving data:")
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
