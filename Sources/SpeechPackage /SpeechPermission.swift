//
//  SpeechPermission.swift
//  speechPackage
//
//  Created by Letícia Delmilio Soares on 27/03/26.
//

import Foundation
import Speech
import AVFoundation

@available(iOS 13.0.0, *)
extension SpeechService{
    // MARK: Permissões:
    
    //API
    public func authorize() async throws {
        if await requestSpeechPermission() == false {
            throw SpeechErrors.speechRecognitionPermissionDenied
        }
        
        if await requestMicrophonePermission() == false {
            throw SpeechErrors.microphonePermissionDenied
        }
    }
    
    //MARK: Solicita permissão para acesso ao microfone `SFSpeechRecognizer`.
    private func requestSpeechPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    //MARK: Solicita permissão para acesso ao microfone.
    
    private func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            await AVAudioApplication.requestRecordPermission()
        } else {
            await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { status in
                    continuation.resume(returning: status)
                }
            }
        }
    }
}

