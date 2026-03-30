//
//  file.swift
//  speechTest
//
//  Created by Letícia Delmilio Soares on 24/03/26.
//

@preconcurrency import Speech
import AVFoundation

//serviço de transcrição de audio em texto
//pede permissão, configura captura de audio e transforma a fala em texto de forma continua

@available(iOS 13.0.0, *)
public final actor SpeechService: SpeechProtocol {
    
    //string que acumula todos os resultados parciais e finais da transcrição
    /// Essa propriedade é atualizada progressivamente durante o processo de reconhecimento de fala.
    public private(set) var accumulatedText: String = ""
    
    // Reconhecedor de fala usado para converter áudio em texto.
    /// Pode ser `nil` se o `Locale` informado não for suportado.
    private let recognizer: SFSpeechRecognizer?
    
    /// Responsável por capturar o áudio do microfone durante a transcrição.
    private var audioEngine: AVAudioEngine?
    
    /// Requisição que envia os buffers de áudio para o reconhecedor de fala.
    private var request: SFSpeechAudioBufferRecognitionRequest?
    
    /// Referência da task de reconhecimento em andamento, usada para cancelamento.
    private var task: SFSpeechRecognitionTask?
    
    //locale(idioma), por padrão pt br
    public init(locale: Locale = Locale(identifier: "pt-BR") ) {
        self.recognizer = SFSpeechRecognizer(locale: locale)
    }
    
    // MARK: - API
//    public func authorize() async throws {
//        if await requestSpeechPermission() == false {
//            throw SpeechErrors.speechRecognitionPermissionDenied
//        }
//        
//        if await requestMicrophonePermission() == false {
//            throw SpeechErrors.microphonePermissionDenied
//        }
//    }
    /**•   AsyncThrowingStream = “fluxo de texto ao vivo”
     •    recognitionTask = “ouvir e transformar fala em texto”
     •    continuation.yield = “manda texto pra fora”*/
    
    //Ela começa a ouvir o microfone e vai enviando texto em tempo real conforme a pessoa fala
    public func startTranscribe() -> AsyncThrowingStream<String, Error> { //um fluxo contínuo de textos que pode dar erro
        AsyncThrowingStream { continuation in //envio de dados, um “cano” por onde você envia textos (yield) ou finaliza
            Task { //não trava a UI
                do {
                    guard let recognizer = self.recognizer else { // se o idioma (locale) for inválido → erro
                        throw SpeechErrors.invalidRecognizer
                    }
                    
                    let request = SFSpeechAudioBufferRecognitionRequest()//“quero resultados em tempo real” (não só no final)
                    request.shouldReportPartialResults = true
                    self.storeRequest(request)
                    
                    let engine = try self.prepareEngine(for: request)//começa a capturar áudio e envia pro reconhecimento
                    self.storeEngine(engine)
                    
                    // o sistema vai analisando o áudio e chamando esse bloco várias vezes
                    let speechTask = recognizer.recognitionTask(with: request) { result, error in
                        Task { //se der erro, encerra o stream e limpa o texto
                            if let error {
                                continuation.finish(throwing: error)
                                await self.endService()
                                return
                            }
                            guard let result else {//garante que tem resultado.Se não tiver texto válido -> erro
                                continuation.finish(throwing: SpeechErrors.invalidAudioData)
                                await self.endService()
                                return
                            }
                            // Envia texto para quem está escutando
                            self.process(result: result, sink: continuation)
                            //quando a fala acaba: encerra o stream e para o serviço
                            if result.isFinal {
                                continuation.finish()
                                await self.endService()
                            }
                        }
                    }
                    
                    self.storeSpeechTask(speechTask)
                    
                    continuation.onTermination = { @Sendable _ in
                        Task { await self.endService() }//    tudo é limpo corretamente
                    }
                    
                } catch { // Se algo falhar no começo
                    continuation.finish(throwing: error)
                    await self.endService()
                }
            }
        }
    }
    
    public func stopTranscribe() {
        audioEngine?.inputNode.removeTap(onBus: 0) //inputNode: representa a entrada de áudio (microfone). // removeTap: remove o “listener” que estava capturando o áudio.
        // onBus: 0: canal padrão de entrada.
        audioEngine?.stop()//para o audioEngine 
        
        request?.endAudio()//“acabou o áudio, pode processar o que recebeu”
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)//Desativa a sessão de áudio do app. e avisa que outros apps podem voltar a usar o audio
    }
}

// MARK: - Internal
@available(iOS 13.0.0, *)
extension SpeechService {
    
    // Armazena a requisição de reconhecimento de fala.
    private func storeRequest(_ request: SFSpeechAudioBufferRecognitionRequest) {
        self.request = request
    }
    
    // Armazena a engine de captura de áudio.
    private func storeEngine(_ engine: AVAudioEngine) {
        self.audioEngine = engine
    }
    
    // Armazena a referência da task de reconhecimento.
    private func storeSpeechTask(_ task: SFSpeechRecognitionTask) {
        self.task = task
    }
    
    // Atualiza o `accumulatedText` com o novo resultado e envia para a stream.
    private func process(result: SFSpeechRecognitionResult, sink: AsyncThrowingStream<String, Error>.Continuation) {
           let newText = result.bestTranscription.formattedString
           if newText != self.accumulatedText {
               self.accumulatedText = newText
               sink.yield(newText)
           }
       }
    //encerra o serviço de reconhecimento
        //cancela a task em andaemnto e libera o request, task e o audioEngine
    private func endService() async {
        task?.cancel() //Cancela qualquer processamento em andamento.
        task = nil //Remove a referência da task da memória.
        request = nil //encerra

        if let engine = audioEngine { //verifica se existe, se existir, cria uma variável local engine.
            if engine.isRunning { //se estiver rodando interrompe a captura do microfone.
                engine.stop()
            }
        }
        
        audioEngine = nil //Remove completamente o motor de áudio.
        accumulatedText = "" //zera o texto acumulado
 
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)//Desativa a sessão de áudio do app. e avisa que outros apps podem voltar a usar o audio
    }
    
   // MARK: - Sessão de áudio
  //Configura a sessão de áudio para gravação e reconhecimento de fala.
    private func activeAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setPreferredSampleRate(16_000)
        try session.setPreferredIOBufferDuration(0.02)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    //Prepara e inicia o AVAudioEngine para enviar o audio ao requestSpeech
    private func prepareEngine(for request: SFSpeechAudioBufferRecognitionRequest) throws -> AVAudioEngine {
        try activeAudioSession() //prepara para usar o microfone
        
        let audioEngine = AVAudioEngine()// esse é o “motor” que controla o áudio (entrada do microfone)
        let inputNode = audioEngine.inputNode // inputNode = entrada de áudio (microfone)
        let format = inputNode.outputFormat(forBus: 0) //formato do audio

        inputNode.removeTap(onBus: 0) //evita conflito se já estava gravando antes
        
        //Captura o áudio em tempo real
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)//divide em “pedaços” (buffer) e envia esses pedaços para o request
        }
        
        audioEngine.prepare() // deixa tudo pronto pra começar
        try audioEngine.start() //microfone começa a funcionar de verdade
        
        return audioEngine //você guarda isso pra poder parar depois
    }
    
//// MARK: Permissões:
//
//    //MARK: Solicita permissão para acesso ao microfone `SFSpeechRecognizer`.
//    private func requestSpeechPermission() async -> Bool {
//        return await withCheckedContinuation { continuation in
//            SFSpeechRecognizer.requestAuthorization { status in
//                continuation.resume(returning: status == .authorized)
//            }
//        }
//    }
//    
////MARK: Solicita permissão para acesso ao microfone.
//  
//    private func requestMicrophonePermission() async -> Bool {
//        if #available(iOS 17.0, *) {
//            await AVAudioApplication.requestRecordPermission()
//        } else {
//            await withCheckedContinuation { continuation in
//                AVAudioSession.sharedInstance().requestRecordPermission { status in
//                    continuation.resume(returning: status)
//                }
//            }
//        }
//    }
}
