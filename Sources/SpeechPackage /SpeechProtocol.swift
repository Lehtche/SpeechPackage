//
//  file.swift
//  speechTest
//
//  Created by Letícia Delmilio Soares on 24/03/26.
//

//Protocolo para o serviço
//Qualquer classe/actor que use esse protocolo precisa implementar:
//É um contrato para qualquer serviço que converta áudio em texto em tempo real
// Esse código define como um serviço de voz para texto deve funcionar, mas não implementa nada.

@available(iOS 13.0, *)
public protocol SpeechProtocol {
    
    func authorize() async throws
    
   
    func startTranscribe() async -> AsyncThrowingStream<String, Error>
    

    func stopTranscribe() async
}
