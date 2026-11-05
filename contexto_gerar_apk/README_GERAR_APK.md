# Como Gerar o APK do ASA Connect em Outra Máquina 📱

Este guia contém tudo o que você precisa saber para compilar o APK do ASA Connect no novo computador.

---

## 1. Pré-Requisitos na Nova Máquina

Certifique-se de que a máquina possui:
1. **Flutter SDK** (versão 3.29 ou superior recomendada):
   * Verifique com: `flutter doctor -v`
2. **Android SDK e Command-line Tools** (instalados pelo Android Studio):
   * O `compileSdk` configurado no projeto é a versão **36**.
   * Licenças do Android aceitas: `flutter doctor --android-licenses`
3. **Java JDK 17 ou 21**:
   * Verifique com: `java -version`

---

## 2. Configurar o Endereço do Backend (Antes de Gerar o APK) ⚠️ IMPORTANTE

Como o APK rodará em um dispositivo físico ou emulador, ele precisa saber onde a API FastAPI está rodando.

Abra o arquivo:
👉 `src/mobile/lib/services/api_client.dart` (ou `app/lib/services/api_client.dart`)

Altere a linha da `baseUrl`:

* **Cenário A — Celular conectado via USB com ADB Reverse (Mais Recomendado):**
  ```dart
  static const String baseUrl = 'http://localhost:8000';
  ```
  *(Depois de conectar o celular no USB, rode no terminal: `adb reverse tcp:8000 tcp:8000`)*

* **Cenário B — Celular e Computador na mesma rede Wi-Fi residencial/sem bloqueio:**
  ```dart
  static const String baseUrl = 'http://192.168.X.X:8000'; // Troque pelo IPv4 do seu PC (veja com 'ipconfig')
  ```

* **Cenário C — Emulador Oficial do Android Studio:**
  ```dart
  static const String baseUrl = 'http://10.0.2.2:8000';
  ```

---

## 3. Comandos para Gerar o APK

Abra o terminal na pasta do app Flutter (`src/mobile` ou `app`):

### Passo 1: Baixar as dependências
```bash
flutter pub get
```

### Passo 2: Gerar o APK

* **Opção 1: APK Release (Mais leve e otimizado):**
  ```bash
  flutter build apk --release
  ```
  Local do arquivo gerado:
  `build/app/outputs/flutter-apk/app-release.apk`

* **Opção 2: APK Debug (Ideal para testar rápido sem preocupação de assinatura):**
  ```bash
  flutter build apk --debug
  ```
  Local do arquivo gerado:
  `build/app/outputs/flutter-apk/app-debug.apk`

---

## 4. Scripts Automáticos Prontos

Nesta pasta você encontra dois utilitários:
* `gerar_apk.bat` — Basta dar **dois cliques** no Windows Explorer para iniciar o processo automaticamente.
* `gerar_apk.ps1` — Script PowerShell que compila e já copia o APK gerado diretamente para esta pasta!

---

## 5. Dicas para Evitar Erros Comuns

* **Erro de memória ou cache incremental do Kotlin:**
  O arquivo `android/gradle.properties` já contém:
  ```properties
  kotlin.incremental=false
  ```
  Isso evita travamentos do compilador Kotlin no Windows.

* **Tráfego HTTP liberado:**
  O arquivo `android/app/src/main/AndroidManifest.xml` já está configurado com `android:usesCleartextTraffic="true"` e `<uses-permission android:name="android.permission.INTERNET"/>` para não bloquear as requisições para a API local.
