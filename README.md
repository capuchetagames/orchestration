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

Todos os serviços são conectados através de uma rede compartilhada (`app-network`), permitindo comunicação entre os microserviços.

## 📁 Estrutura do Projeto

```
orchestration/
├── docker-compose.yaml     # Configuração principal do Docker Compose
├── startall.sh             # Script para iniciar todos os serviços
├── downall.sh              # Script para parar todos os serviços
├── rabbitmq/               # Configuração do RabbitMQ
│   └── docker-compose-rabbitmq.yaml  # Docker Compose do RabbitMQ (incluído no principal)
├── k6/                     # Testes de carga
│   └── index.js            # Configuração de teste K6
└── k8s/                    # Kubernetes deployment
    ├── start-all.sh        # Script para deploy no Kubernetes
    └── delete-all.sh       # Script para remover resources do Kubernetes
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

> **Nota:** O RabbitMQ é gerenciado através do `docker-compose.yaml` e será iniciado automaticamente ao executar `docker-compose up`.

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

> **⚠️ Segurança:** As credenciais padrão devem ser alteradas em ambientes de produção. Edite o arquivo `rabbitmq/docker-compose-rabbitmq.yaml` para configurar credenciais mais seguras.

### Acessar o Management Console

Após iniciar os serviços, acesse o console de gerenciamento do RabbitMQ:

```
http://localhost:15672
```

Use as credenciais padrão (admin/admin) para fazer login.

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

