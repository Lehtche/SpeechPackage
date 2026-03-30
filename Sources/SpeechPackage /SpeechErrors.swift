//
//  file.swift
//  speechTest
//
//  Created by Letícia Delmilio Soares on 24/03/26.
//

import Foundation

//erros que podem acontecer no service
public enum SpeechErrors: Error {
    
    //usuario não permitiu o uso do microfone (AVAudioSession)
    case microphonePermissionDenied
    
    //usuario não permitiu o uso do SFSpeechRecognizer
    case speechRecognitionPermissionDenied
    
    // o SFSpeechRecognizer retornou nil devido a um Locale(idioma) invalido ou nao suportado
    case invalidRecognizer
    
    //buffer(área de memória temporária que armazena dados de som antes da reprodução ou processamento ) de audio recebido esta invalido ou nao pode ser processado
    case invalidAudioData
}

