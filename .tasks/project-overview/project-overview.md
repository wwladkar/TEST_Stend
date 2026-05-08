# 🧪 TEST Stend — Обзор проекта

## 1. Назначение проекта

**TEST Stend** — учебный тестовый стенд для отработки и совершенствования навыков автотестирования фронтенда и бэкенда.

Микросервисное веб-приложение с ролевой моделью, предназначенное для практики написания автотестов на UI и API. Содержит реальные сценарии: регистрацию, авторизацию (JWT), CRUD-операции над задачами, ролевой доступ (USER/ADMIN), валидацию — всё, что нужно для полноценного обучения автотестированию.

> ⚠️ Проект **не предназначен для продакшена** — безопасность намеренно упрощена.

---

## 2. Структура проекта

### Архитектурная схема

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Frontend   │────▶│ API Gateway  │────▶│ Auth Service │
│  React+Vite  │     │  :8080       │────▶│    :8081     │
│    :3000     │     └──────────────┘     └──────────────┘
└──────────────┘            │                     │
                            ▼                     ▼
                     ┌──────────────┐      ┌────────────┐
                     │ Core Service │      │  H2 / PG   │
                     │    :8082     │─────▶│  Database  │
                     └──────────────┘      └────────────┘
```

### Модули Maven (multi-module)

| Модуль | Назначение | Порт |
|--------|-----------|------|
| `common-security` | Общая библиотека безопасности (shared lib, не запускается самостоятельно) | — |
| `auth-service` | Сервис авторизации и управления пользователями | 8081 |
| `core-service` | Сервис задач (CRUD) | 8082 |
| `api-gateway` | API Gateway (маршрутизация запросов) | 8080 |
| `frontend/` | React-фронтенд (отдельный проект, не Maven-модуль) | 3000 |

### Дерево директорий

```
TEST_Stend/
├── pom.xml                        # Корневой Maven (multi-module)
├── docker-compose.yml             # Полный стек: PostgreSQL + сервисы + frontend
├── .env / .env.example            # Переменные окружения (JWT_SECRET и др.)
├── stend.ps1 / stend.sh           # Скрипты управления стендом
├── README.md                      # Подробная документация
│
├── common-security/               # 📦 Shared-библиотека безопасности
│   ├── pom.xml
│   └── src/main/.../common/security/
│       ├── BaseSecurityConfig.java        # CORS-конфигурация
│       ├── JwtTokenProvider.java          # Генерация и валидация JWT
│       ├── JwtAuthFilter.java            # Фильтр авторизации JWT
│       ├── TokenBlacklist.java           # In-memory блэклист токенов
│       └── GlobalExceptionHandler.java   # IllegalArgumentException → 404
│
├── auth-service/                  # 🔐 Сервис авторизации
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/main/.../authservice/
│       ├── AuthServiceApplication.java
│       ├── config/
│       │   ├── SecurityConfig.java       # Spring Security + JWT filter chain
│       │   ├── AuthExceptionHandler.java # Обработка ошибок авторизации
│       │   └── H2ServerConfig.java       # H2 TCP-сервер (для DBeaver)
│       ├── controller/
│       │   ├── AuthController.java       # Регистрация, логин
│       │   ├── UserController.java       # Профиль текущего пользователя
│       │   └── AdminController.java      # Управление пользователями (ADMIN)
│       ├── dto/
│       │   ├── LoginRequest.java
│       │   ├── RegisterRequest.java
│       │   ├── AuthResponse.java
│       │   ├── UserDto.java
│       │   ├── RoleChangeRequest.java
│       │   └── ToggleEnabledRequest.java
│       ├── entity/
│       │   └── User.java                 # Сущность пользователя
│       ├── repository/
│       │   └── UserRepository.java
│       ├── service/
│       │   ├── AuthService.java          # Бизнес-логика авторизации
│       │   ├── UserService.java          # Работа с профилем
│       │   └── AdminService.java         # Админ-операции
│       └── util/                         # Утилиты
│       └── src/main/resources/
│           ├── application.yml           # H2, порт 8081, JWT-конфиг
│           └── application-pg.yml        # PostgreSQL-профиль
│
├── core-service/                  # 📋 Сервис задач
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/main/.../coreservice/
│       ├── CoreServiceApplication.java
│       ├── config/
│       │   ├── SecurityConfig.java
│       │   └── H2ServerConfig.java
│       ├── controller/
│       │   └── TaskController.java       # CRUD задач
│       ├── dto/
│       │   ├── TaskRequest.java
│       │   └── TaskDto.java
│       ├── entity/
│       │   ├── Task.java                 # Сущность задачи
│       │   ├── TaskStatus.java           # Статус (enum)
│       │   └── TaskPriority.java         # Приоритет (enum)
│       ├── repository/
│       │   └── TaskRepository.java
│       ├── service/
│       │   └── TaskService.java          # Бизнес-логика задач
│       └── src/main/resources/
│           ├── application.yml           # H2, порт 8082, JWT-конфиг
│           └── application-pg.yml        # PostgreSQL-профиль
│
├── api-gateway/                   # 🌐 API Gateway
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/main/.../apigateway/
│       ├── ApiGatewayApplication.java
│       └── config/
│           └── CorsConfig.java           # CORS-настройки
│       └── src/main/resources/
│           └── application.yml           # Маршруты :8080 → :8081/:8082
│
├── frontend/                      # 🖥 React-фронтенд
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json / vite.config.js
│   └── src/
│       ├── App.jsx / main.jsx
│       ├── api/axios.js                  # Axios-инстанс с интерцепторами
│       ├── context/AuthContext.jsx       # Контекст авторизации (JWT)
│       ├── components/Navbar.jsx         # Навигация с ролевым доступом
│       └── pages/
│           ├── Login.jsx
│           ├── Register.jsx
│           ├── Tasks.jsx
│           └── Admin.jsx
│
├── postman/                       # 📮 Postman-коллекция
│   ├── TEST_Stend_API.postman_collection.json
│   └── TEST_Stend_Local.postman_environment.json
│
├── data/                          # 💾 Файлы H2-баз данных
│   ├── auth-db.mv.db
│   └── core-db.mv.db
│
└── logs/                          # 📝 Логи сервисов
    ├── APIGateway.log
    ├── Auth_Service.log
    ├── CoreService.log
    └── ...
```

---

## 3. Функциональное наполнение

### Технологический стек

| Слой | Технология |
|------|-----------|
| **Backend** | Java 17, Spring Boot 3.2.5, Spring Security, Spring Data JPA |
| **Микросервисы** | Spring Cloud Gateway (MVC), Spring Cloud 2023.0.1 |
| **Авторизация** | JWT (jjwt 0.12.5), Spring Security, Token Blacklist |
| **БД (dev)** | H2 Embedded (файловое хранение `./data/`) |
| **БД (prod/docker)** | PostgreSQL 16 Alpine |
| **Frontend** | React 18, JavaScript (JSX), Vite, Axios, React Router |
| **Инфраструктура** | Docker Compose, Maven Multi-Module, Nginx |
| **Инструменты** | Postman-коллекция, скрипты управления (PowerShell/Bash) |

### Ключевые компоненты

#### common-security (Shared Library)
- **JwtTokenProvider** — генерация и валидация JWT-токенов (секрет из env `JWT_SECRET`, TTL 24ч)
- **JwtAuthFilter** — фильтр Spring Security для проверки JWT в заголовке `Authorization: Bearer <token>`
- **TokenBlacklist** — in-memory блэклист отозванных токенов (для logout)
- **BaseSecurityConfig** — базовая CORS-конфигурация
- **GlobalExceptionHandler** — обработка `IllegalArgumentException` → 404

#### auth-service (Порт 8081)
- **Регистрация** (`POST /api/auth/register`) — публичная, с валидацией
- **Логин** (`POST /api/auth/login`) — публичная, возвращает JWT
- **Профиль** (`GET /api/users/me`) — авторизованный пользователь
- **Админка** — список пользователей, смена ролей, блокировка/разблокировка
- **Ролевая модель**: USER (базовый) / ADMIN (расширенный)
- **Сущность User**: username, email, password, role, enabled

#### core-service (Порт 8082)
- **CRUD задач** (`/api/tasks/**`) — создание, просмотр, обновление, удаление
- **Пагинация** задач
- **Владельческий доступ** — пользователь может управлять только своими задачами
- **Сущность Task**: title, description, status, priority, ownerId
- **TaskStatus** — перечисление статусов задачи
- **TaskPriority** — перечисление приоритетов задачи

#### api-gateway (Порт 8080)
- Маршрутизация запросов:
  - `/api/auth/**`, `/api/admin/**`, `/api/users/**` → Auth Service (:8081)
  - `/api/tasks/**` → Core Service (:8082)
- CORS-настройки

#### Frontend (Порт 3000)
- **Страницы**: Login, Register, Tasks (CRUD), Admin (управление пользователями)
- **AuthContext** — контекст авторизации с хранением JWT
- **Axios-интерцепторы** — автоматическая вставка JWT в заголовки
- **Navbar** — ролевая навигация (ссылка «Админка» видна только ADMIN)
- **Nginx** — раздача статики в Docker

### Конфигурация баз данных

| Профиль | БД | URL |
|---------|-----|-----|
| default (H2) | H2 file-based | `jdbc:h2:file:./data/auth-db` / `core-db` |
| `pg` (PostgreSQL) | PostgreSQL 16 | `jdbc:postgresql://postgres:5432/teststend` |

H2 TCP-порты для внешних клиентов (DBeaver):
- Auth DB: `9091`
- Core DB: `9092`

### Docker Compose (полный стек)

5 контейнеров: PostgreSQL → Auth Service → Core Service → API Gateway → Frontend (Nginx)

### Что можно тестировать (целевое использование)

**UI-тесты**: формы регистрации/логина, CRUD задач, ролевая навигация, блокировка → авто-разлогин, пагинация

**API-тесты**: регистрация (валидация, дубли), логин (ошибки, заблокированные), CRUD задач (403 на чужие), админ-эндпоинты (403 для USER), истечение JWT → 401

### TODO (нереализованное)
- Refresh-токены
- Восстановление пароля
- Фильтрация и сортировка задач
- Swagger/OpenAPI документация
- Примеры автотестов (Playwright + REST Assured)
- CI/CD пайплайн
