//
//  file.swift
//  speechTest
//
//  Created by Letícia Delmilio Soares on 24/03/26.
//

import SwiftUI
//view model que controla o serviço de transcrição

@available(iOS 13.0, *)
public final class SpeechViewModel: ObservableObject {
    
    //transcreve em tempo real na UI
    @Published public var transcript: String = ""
    
    //transcrição ativa
    @Published public var isRunning: Bool = false
    
    // Erro atual da transcrição
    @Published public var errorMessage: Error?
    
    // Serviço de transcrição usado pelo ViewModel.
    private let service: any SpeechProtocol
    
    // Referência da task de transcrição em andamento.
    private var transcriptionTask: Task<Void, Never>?
    
    // Inicializa a ViewModel com o serviço de transcrição.
    public init(service: any SpeechProtocol = SpeechService() ) {
        self.service = service
    }
    
    //Inicia a transcrição em tempo real
    @MainActor// garante que mudanças na UI (como transcript) acontecem na thread principal
    public func startRecording() async {
        guard isRunning == false else { return } //se já estiver gravando faz nada
        isRunning = true //Esta gravando
        
        transcriptionTask = Task { //roda em background, sem travar a UI
                do {
                    try await service.authorize() //pede acesso ao microfone e ao reconhecimento

                    let stream = await service.startTranscribe()//escuta o audio e retorna fluxo de texto
                    
                    for try await partialResult in stream {//recebe pedaços de texto eatualiza transcript continuamente
                        self.transcript = partialResult
                    }
                } catch { //tratamento de erro
                    self.errorMessage = error //salva o erro pra mostrar
                }
            }
    }
    
    // Encerra a transcrição em tempo real.
    @MainActor
    public func stopRecording() async {
        guard isRunning else { return } //se estiver gravando
        
        isRunning = false
        transcriptionTask?.cancel()
        transcriptionTask = nil
        transcript = ""
        
        Task {
            await service.stopTranscribe()
        }
    }
}
