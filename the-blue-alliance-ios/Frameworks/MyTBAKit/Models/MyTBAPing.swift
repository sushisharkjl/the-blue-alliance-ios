import Foundation
import Firebase

struct MyTBAPingRequest: Codable {
    var mobileId: String
}

extension MyTBA {

    @discardableResult
    func ping(_ token: String, completion: @escaping MyTBABaseCompletionBlock) -> URLSessionDataTask? {
        let ping = MyTBAPingRequest(mobileId: token)

        guard let encodedPing = try? MyTBA.jsonEncoder.encode(ping) else {
            completion(nil, MyTBAError.error("Unable to ping device - invalid data"))
            return nil
        }
        return callApi(method: "ping", bodyData: encodedPing, completion: completion)
    }

}
