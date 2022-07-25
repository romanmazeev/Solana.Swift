//
//  mintFromAccount.swift
//  
//
//  Created by Roman Mazeev on 25/07/22.
//

import Foundation

extension Action {
    public func mintMetaryNFT(
        nftPublicKey: PublicKey,
        appAccount: Account,
        userAccount: Account,
        onComplete: @escaping (Result<TransactionID, Error>) -> Void
    ) {

        ContResult.init { cb in
            self.findSPLTokenDestinationAddress(
                mintAddress: nftPublicKey.base58EncodedString,
                destinationAddress: userAccount.publicKey.base58EncodedString,
                allowUnfundedRecipient: true
            ) { cb($0) }
        }.flatMap { (destination, isUnregisteredAsocciatedToken) in

            let toPublicKey = destination

            // catch error
            guard appAccount.publicKey.base58EncodedString != toPublicKey.base58EncodedString else {
                return .failure(SolanaError.invalidPublicKey)
            }

            guard let fromPublicKey = PublicKey(string: appAccount.publicKey.base58EncodedString) else {
                return .failure( SolanaError.invalidPublicKey)
            }
            var instructions = [TransactionInstruction]()

            // create associated token address
            if isUnregisteredAsocciatedToken {
                guard let mint = PublicKey(string: nftPublicKey.base58EncodedString) else {
                    return .failure(SolanaError.invalidPublicKey)
                }
                guard let owner = PublicKey(string: appAccount.publicKey.base58EncodedString) else {
                    return .failure(SolanaError.invalidPublicKey)
                }

                let createATokenInstruction = AssociatedTokenProgram.createAssociatedTokenAccountInstruction(
                    mint: mint,
                    associatedAccount: toPublicKey,
                    owner: owner,
                    payer: userAccount.publicKey
                )
                instructions.append(createATokenInstruction)
            }

            // send instruction
            let sendInstruction = TokenProgram.transferInstruction(
                tokenProgramId: .tokenProgramId,
                source: fromPublicKey,
                destination: toPublicKey,
                owner: appAccount.publicKey,
                amount: 1
            )

            instructions.append(sendInstruction)
            return .success((instructions: instructions, account: appAccount))

        }.flatMap { (instructions, account) in
            ContResult.init { cb in
                self.serializeAndSendWithFee(instructions: instructions, signers: [account]) {
                    cb($0)
                }
            }
        }.run(onComplete)
    }
}

extension ActionTemplates {
    public struct MintMetaryNFT: ActionTemplate {
        public let nftPublicKey: PublicKey
        public let appAccount: Account
        public let userAccount: Account

        public typealias Success = TransactionID

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<TransactionID, Error>) -> Void) {
            actionClass.mintMetaryNFT(nftPublicKey: nftPublicKey, appAccount: appAccount, userAccount: userAccount, onComplete: completion)
        }
    }
}
