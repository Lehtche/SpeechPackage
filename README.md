# SpeechPackage

O **SpeechPackage** permite capturar áudio do microfone, transcrever em tempo real e gerenciar gravações de forma simples, incluindo tratamento de permissões e erros.

---

## Recursos principais

- Captura de áudio do microfone
- Transcrição em tempo real
- Controle de início e parada de gravação
- Tratamento de permissões
- Tratamento de erros

---

## Instalação

1. Vá em `File > Add Packages`
2. Cole a URL do repositório do **SpeechPackage**

---
## Como usar: 

⚠️ Permissões necessárias

Adicione as chaves no seu Info.plist:
	•	NSSpeechRecognitionUsageDescription
	•	NSMicrophoneUsageDescription


• Importar o Package

```swift
import SpeechPackage
```

• Crie a ViewModel:
```
@StateObject private var viewModel = SpeechViewModel()
```

• Iniciar gravação:
```
Task {
    await viewModel.startRecording()
}
```

• Parar gravação: 
```
Task {
    await viewModel.stopRecording()
}
```

• Acessar transcrição: 
```
Text(viewModel.transcript)
```

### Este package não salva os dados por padrão, ele só mantém a transcrição na memória (viewModel.transcript).Se você quiser salvar a transcrição no seu app, pode fazer assim:
• 1.	Criar um arquivo de modelo (ex.: Transcription.swift):
```
struct Transcription {
    var titulo: String
    var texto: String
}
```
• 2. Salvar a transcrição (SwiftData): 
```
  let texto = viewModel.transcript
  
  let nova = Transcription(
      titulo: "Sem título",
      texto: texto
  )
  context.insert(nova)
```
## Exemplo com SwiftData: 
```
import SwiftUI
import SwiftData

@main
struct speechTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Transcription.self)
    }
}
```

•	O package só faz captura + transcrição em memória.
•	Se você quiser salvar, crie seu próprio modelo no app e salve da forma que preferir.
•	Não é necessário usar SwiftData, CoreData ou qualquer outra biblioteca obrigatória.






