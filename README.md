# Orchestration - Microservices Management

## 📋 Descrição

Este repositório é responsável pela **orquestração e gerenciamento** de uma arquitetura de microserviços. Ele fornece scripts e configurações para facilitar o deploy, gerenciamento e testes de carga de múltiplos serviços de forma integrada.

## 🏗️ Arquitetura

O projeto orquestra os seguintes microserviços:

- **usersapi** - API de gerenciamento de usuários e autenticação
- **catalogapi** - API de catálogo de produtos
- **paymentsapi** - API de processamento de pagamentos
- **notificationsapi** - API de notificações

### Message Broker

- **RabbitMQ** - Message broker para comunicação assíncrona entre microserviços

### API Gateway

- **Kong Gateway** - API Gateway para roteamento, autenticação e gerenciamento de APIs
- **Konga** - Interface gráfica (UI) para gerenciar o Kong (versão community)

### Monitoramento

- **New Relic Infrastructure** - Agente de monitoramento de infraestrutura e containers

Todos os serviços são conectados através de uma rede compartilhada (`app-network`), permitindo comunicação entre os microserviços.

## 📁 Estrutura do Projeto

```
orchestration/
├── docker-compose.yaml          # Configuração principal do Docker Compose (inclui todos os serviços)
├── startall.sh                  # Script para iniciar todos os microserviços
├── downall.sh                   # Script para parar todos os microserviços
├── rabbitmq/                    # Configuração do RabbitMQ
│   └── docker-compose.yaml      # Docker Compose do RabbitMQ (incluído no principal)
├── kong/                        # Kong API Gateway (Enterprise) – standalone
│   └── docker-compose.yml       # Kong + Postgres sem Konga
├── kong-konga/                  # Kong API Gateway + Konga UI (versão community)
│   ├── docker-compose.yaml      # Kong + Konga + Postgres (incluído no principal)
│   └── docker-postgredb.sh      # Script auxiliar para subir Postgres standalone
├── newrelic-infra/              # Monitoramento de infraestrutura com New Relic
│   ├── docker-compose.yaml      # Agente New Relic Infrastructure (incluído no principal)
│   ├── newrelic-infra.dockerfile # Dockerfile do agente
│   └── newrelic-infra.yml       # Configuração da license key
├── k6/                          # Testes de carga
│   └── index.js                 # Configuração de teste K6
└── k8s/                         # Kubernetes deployment
    ├── start-all.sh             # Script para deploy no Kubernetes
    └── delete-all.sh            # Script para remover resources do Kubernetes
```

### Estrutura de Pastas dos Projetos

```
capucheta/
├── catalogapi/
├── notificationsapi/
├── orchestration/
├── paymentsapi/
└── usersapi/
```

> **Nota:** Todos os repositórios devem estar na mesma pasta raiz (`capucheta/`) para que os scripts funcionem corretamente.

## 🚀 Pré-requisitos

Antes de começar, certifique-se de ter instalado:

- [Docker](https://www.docker.com/get-started) (versão 20.x ou superior)
- [Docker Compose](https://docs.docker.com/compose/install/) (versão 2.x ou superior)
- [Kubernetes](https://kubernetes.io/) e [kubectl](https://kubernetes.io/docs/tasks/tools/) (opcional, para deploy K8s)
- [K6](https://k6.io/docs/getting-started/installation/) (opcional, para testes de carga)

## 📦 Instalação e Configuração

### 1. Clonar os Repositórios

Clone todos os repositórios necessários na mesma pasta raiz:

```bash
mkdir capucheta && cd capucheta
git clone git@github.com:capuchetagames/usersapi.git
git clone git@github.com:capuchetagames/catalogapi.git
git clone git@github.com:capuchetagames/paymentsapi.git
git clone git@github.com:capuchetagames/notificationsapi.git
git clone git@github.com:capuchetagames/orchestration.git
```

### 2. Navegar para o Diretório de Orquestração

```bash
cd orchestration
```

## 🐳 Uso com Docker Compose

### Opção 1: Usando Docker Compose Diretamente

#### Build e Inicializar (Primeira vez)

```bash
docker-compose up --build
```

#### Inicializar (Após o primeiro build)

```bash
docker-compose up
```

#### Parar e Remover Containers

```bash
docker-compose down -v
```

> **Nota:** A flag `-v` remove também os volumes, garantindo um ambiente limpo. O RabbitMQ é automaticamente inicializado junto com os outros serviços.

### Opção 2: Usando Scripts Bash

#### Iniciar Todos os Serviços

```bash
./startall.sh
```

Este script irá:
1. Iniciar o serviço de usuários
2. Iniciar o serviço de catálogo
3. Iniciar o serviço de pagamentos
4. Iniciar o serviço de notificações

#### Parar Todos os Serviços

```bash
./downall.sh
```

Este script irá parar e remover todos os containers e volumes de todos os serviços.

## ☸️ Deploy no Kubernetes

### Iniciar Todos os Serviços no Kubernetes

```bash
cd k8s
./start-all.sh
```

### Remover Todos os Resources do Kubernetes

```bash
cd k8s
./delete-all.sh
```

> **Nota:** Certifique-se de que seu cluster Kubernetes está configurado e o `kubectl` está apontando para o cluster correto.

## 📨 RabbitMQ - Message Broker

O RabbitMQ é usado como message broker para comunicação assíncrona entre os microserviços.

### Configuração Padrão

- **Porta AMQP:** 5672
- **Porta Management Console:** 15672
- **Usuário padrão:** admin
- **Senha padrão:** admin

> **⚠️ Segurança:** As credenciais padrão devem ser alteradas em ambientes de produção. Edite o arquivo `rabbitmq/docker-compose.yaml` e altere as variáveis `RABBITMQ_DEFAULT_USER` e `RABBITMQ_DEFAULT_PASS` para configurar credenciais mais seguras.

### Acessar o Management Console

Após iniciar os serviços, acesse o console de gerenciamento do RabbitMQ:

```
http://localhost:15672
```

Use as credenciais padrão (admin/admin) para fazer login.

## 🦍 Kong API Gateway + Konga

O Kong é usado como API Gateway para centralizar o roteamento, autenticação e controle de acesso das APIs dos microserviços. O Konga fornece uma interface gráfica para gerenciar o Kong.

### Versão Community (Kong + Konga)

O diretório `kong-konga/` contém a configuração completa com Kong Gateway, Konga UI e PostgreSQL, integrada ao `docker-compose.yaml` principal.

#### Inicializar Kong + Konga via docker compose principal

```bash
docker compose up
```

O stack do Kong/Konga será inicializado automaticamente junto com os demais serviços.

#### Inicializar Kong + Konga de forma isolada

```bash
cd kong-konga
docker compose up -d
```

#### Portas expostas

| Serviço           | Porta  | Descrição                    |
|-------------------|--------|------------------------------|
| Kong Proxy HTTP   | 8000   | Entrada de requisições HTTP  |
| Kong Proxy HTTPS  | 8443   | Entrada de requisições HTTPS |
| Kong Admin API    | 8001   | API de administração HTTP    |
| Kong Admin HTTPS  | 8444   | API de administração HTTPS   |
| Kong Manager      | 8002   | Interface de gestão HTTP     |
| Kong Manager TLS  | 8445   | Interface de gestão HTTPS    |
| Konga UI          | 1337   | Interface gráfica do Konga   |
| PostgreSQL        | 5432   | Banco de dados do Kong       |

#### Acessar o Konga

Após iniciar os serviços, acesse a interface do Konga:

```
http://localhost:1337
```

Na primeira vez, crie um usuário administrador e configure a conexão com o Kong Admin API:
- **Kong Admin URL:** `http://kong-cp:8001`

### Versão Enterprise (Kong standalone)

O diretório `kong/` contém uma configuração alternativa para Kong Gateway Enterprise (sem Konga). Requer uma licença válida do Kong Enterprise.

```bash
# Prefira usar um arquivo .env para evitar expor a licença no histórico do shell
echo "KONG_LICENSE_DATA='<seu-json-de-licença>'" > kong/.env

cd kong
docker compose up -d
```

> **⚠️ Nota:** A versão Enterprise exige a variável de ambiente `KONG_LICENSE_DATA` com a licença Kong válida. Sem ela, o serviço não iniciará corretamente. Evite exportar a licença diretamente no shell (`export KONG_LICENSE_DATA=...`), pois o valor ficará registrado no histórico do terminal.

---

## 📊 Monitoramento com New Relic Infrastructure

O diretório `newrelic-infra/` contém a configuração do agente New Relic Infrastructure, que monitora o host e os containers Docker em tempo real.

### Configuração

Antes de inicializar, edite o arquivo `newrelic-infra/newrelic-infra.yml` e substitua a `license_key` pela sua chave de licença do New Relic:

```yaml
license_key: <sua-license-key-new-relic>
```

Como alternativa mais segura, utilize uma variável de ambiente no arquivo de configuração:

```yaml
license_key: ${NEW_RELIC_LICENSE_KEY}
```

E defina a variável em um arquivo `.env` ou via seu sistema de gerenciamento de segredos.

> **⚠️ Segurança:** Nunca commite sua license key real no repositório. Utilize variáveis de ambiente ou um gerenciador de segredos em ambientes compartilhados.

### Inicialização

O agente é iniciado automaticamente pelo `docker-compose.yaml` principal:

```bash
docker compose up
```

Ou de forma isolada:

```bash
cd newrelic-infra
docker compose up -d
```

---

## 🧪 Testes de Carga com K6

O projeto inclui scripts de teste de carga usando [K6](https://k6.io/) para validar a performance dos serviços.

### Executar Teste de Carga 

```bash
cd k6
k6 run index.js
```

### Configuração Atual

O teste padrão está configurado para:
- **10 usuários virtuais (VUs)** simultâneos
- **Duração de 30 segundos**
- **Endpoint testado:** `http://localhost:5200/Auth`

Para personalizar, edite o arquivo `k6/index.js`:

```javascript
export const options = {
    vus: 10,        // Número de usuários virtuais
    duration: '30s', // Duração do teste
};
```

## 🔗 Recursos Adicionais

### Workflow e Diagramas

Miro com um workflow básico para interface gráfica:
- [Acesse o board no Miro](https://miro.com/app/board/uXjVJ-g_ni8=/?share_link_id=452428393845)

