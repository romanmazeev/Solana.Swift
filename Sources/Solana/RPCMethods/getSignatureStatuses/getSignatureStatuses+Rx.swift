import Foundation
import RxSwift

public extension Solana {
    func getSignatureStatuses(pubkeys: [String], configs: RequestConfiguration? = nil) -> Single<[SignatureStatus?]> {
        Single.create { emitter in
            self.getSignatureStatuses(pubkeys:pubkeys, configs: configs) {
                switch $0 {
                case .success(let status):
                    emitter(.success(status))
                case .failure(let error):
                    emitter(.failure(error))
                }
            }
            return Disposables.create()
        }
    }
}
