# Cidade Inteligente

Aplicativo desenvolvido com **Flutter** e **Dart**, com uma interface inicial de autenticação para o projeto Cidade Inteligente.

## Sobre o projeto

O Cidade Inteligente é um projeto em desenvolvimento. Nesta versão, o aplicativo apresenta uma tela de entrada com identidade visual própria e permite alternar entre os formulários de login e cadastro.

Sem a configuração do Supabase, o app abre em modo demonstrativo e mantém o perfil somente durante a sessão. Com o Supabase, o login usa contas reais e o perfil fica salvo entre sessões.

## Funcionalidades implementadas

- Tela inicial de login.
- Alternância entre login e cadastro.
- Campo de nome completo exibido durante o cadastro.
- Campos de e-mail e senha.
- Opção para mostrar ou ocultar a senha.
- Validação básica de campos obrigatórios.
- Mensagens de retorno para o usuário.
- Interface responsiva com componentes Material 3 e paleta de cores azul.

## Tecnologias utilizadas

- **Flutter** — framework para desenvolvimento de aplicações multiplataforma.
- **Dart** — linguagem de programação.
- **Material 3** — componentes e tema visual.
- **cupertino_icons** — pacote de ícones incluído nas dependências.

## Estrutura do projeto

```text
cidade_inteligente/
├── android/                 # Arquivos da plataforma Android
├── ios/                     # Arquivos da plataforma iOS
├── lib/
│   └── main.dart            # Ponto de entrada e telas atuais do aplicativo
├── linux/                   # Arquivos da plataforma Linux
├── macos/                   # Arquivos da plataforma macOS
├── test/                    # Testes automatizados
├── web/                     # Arquivos da plataforma Web
├── windows/                 # Arquivos da plataforma Windows
├── analysis_options.yaml     # Regras de análise do Dart
├── pubspec.yaml             # Configuração e dependências do projeto
└── README.md                # Documentação do projeto
```

## Pré-requisitos

Para executar o projeto, instale:

1. [Flutter SDK](https://docs.flutter.dev/get-started/install)
2. [Git](https://git-scm.com/downloads)
3. Um editor compatível, como [Visual Studio Code](https://code.visualstudio.com/), com as extensões Flutter e Dart.

Para executar em um dispositivo Android, também configure o Android Studio e o Android SDK. Consulte a documentação oficial do Flutter para configurar os destinos desejados.

## Como executar

Abra um terminal na pasta que contém o arquivo `pubspec.yaml` e execute:

```bash
flutter doctor
flutter pub get
flutter run
```

O comando `flutter doctor` verifica a configuração do ambiente. Resolva os itens necessários para a plataforma em que pretende executar o aplicativo.

## Configurar o Supabase

1. Crie um projeto no [painel do Supabase](https://supabase.com/dashboard).
2. No **SQL Editor** do projeto, abra uma nova consulta, cole o conteúdo da [migração de perfis](supabase/migrations/20261120000000_perfis.sql) e execute uma vez. A migração cria a tabela `public.perfis` e limita a consulta e a edição ao titular da conta.
3. Abra **Connect** no painel e copie a **Project URL** e a chave **Publishable**. Use somente a chave publicável no Flutter.
4. Para testar no Chrome, configure a **Site URL** em **Authentication → URL Configuration** como `http://localhost:8080`. Em um ambiente publicado, use o endereço público do app para o retorno do link de confirmação.
5. Execute na pasta do projeto, substituindo os valores de exemplo.

```powershell
flutter run -d chrome --web-port=8080 --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_SUA_CHAVE
```

Cadastre uma conta, confirme o e-mail se a confirmação estiver habilitada e faça login. No dashboard, abra **Perfil**, selecione sua cidade e clique em **Salvar perfil**. Saia e entre novamente com a mesma conta para confirmar que o perfil foi recuperado. A tabela `perfis` recebe a linha do usuário ao salvar o perfil pela primeira vez.

## Verificação e testes

Depois de instalar e configurar o Flutter, execute:

```bash
flutter analyze
flutter test
```

- `flutter analyze`: analisa o código Dart em busca de problemas.
- `flutter test`: executa os testes automatizados localizados na pasta `test/`.

Os comandos acima são instruções de verificação; os resultados dependem do ambiente configurado e dos testes presentes no projeto.

## Fluxo atual de login e cadastro

1. Ao abrir o aplicativo, a tela de login é exibida.
2. A pessoa pode alternar para o formulário de cadastro.
3. No cadastro, o campo de nome completo também é apresentado.
4. O botão de envio verifica se os campos obrigatórios estão preenchidos.
5. O aplicativo mostra uma mensagem demonstrativa na tela.

**Limitação atual:** os dados digitados não são enviados a um servidor, não são persistidos e não existe integração de autenticação nesta versão. Não use dados reais ou senhas pessoais para testar.

## Próximas melhorias sugeridas

- Implementar autenticação real e cadastro de usuários.
- Integrar uma API e um banco de dados, caso façam parte dos requisitos do projeto.
- Adicionar validação de formato de e-mail e requisitos de senha.
- Criar testes automatizados para os formulários e para a alternância entre login e cadastro.
- Definir recuperação de senha, tratamento de erros e políticas de privacidade antes de disponibilizar o aplicativo para usuários.

## Contribuição

1. Faça um fork ou clone do repositório.
2. Crie uma branch para sua alteração.
3. Implemente e teste a mudança.
4. Envie um Pull Request descrevendo o que foi alterado.

## Licença
