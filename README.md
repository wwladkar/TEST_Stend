# 🧪 TEST Stend

Тестовый стенд для отработки и совершенствования навыков автотестирования фронтенда и бэкенда.

## 📋 О проекте

Микросервисное веб-приложение с ролевой моделью, предназначенное для практики написания автотестов на UI и API. Содержит реальные сценарии: регистрацию, авторизацию, CRUD-операции, ролевой доступ, валидацию — всё, что нужно для полноценного обучения.

## 🏗 Архитектура

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

## 🔧 Стек технологий

| Слой | Технология |
|------|-----------|
| **Frontend** | React 18, TypeScript, Vite, Axios, React Router |
| **API Gateway** | Spring Cloud Gateway (MVC) |
| **Auth Service** | Spring Boot 3.2, Spring Security, JWT (jjwt 0.12), JPA |
| **Core Service** | Spring Boot 3.2, Spring Security, JWT, JPA |
| **БД** | H2 (embedded, текущая) / PostgreSQL (Docker Compose) |
| **Инфраструктура** | Docker Compose, Maven (multi-module) |

## 📂 Структура проекта

```
TEST_Stend/
├── pom.xml                    # Корневой Maven (multi-module)
├── docker-compose.yml         # PostgreSQL для продакшн-режима
├── auth-service/              # Сервис авторизации (:8081)
│   └── src/main/.../authservice/
│       ├── config/            # SecurityConfig, JwtAuthFilter, H2ServerConfig
│       ├── controller/        # AuthController, UserController, AdminController
│       ├── dto/               # LoginRequest, RegisterRequest, AuthResponse, UserDto
│       ├── entity/            # User
│       ├── repository/        # UserRepository
│       └── util/              # JwtTokenProvider
├── core-service/              # Сервис задач (:8082)
│   └── src/main/.../coreservice/
│       ├── config/            # SecurityConfig, JwtAuthFilter, H2ServerConfig
│       ├── controller/        # TaskController
│       ├── dto/               # TaskRequest, TaskDto
│       ├── entity/            # Task
│       └── repository/        # TaskRepository
├── api-gateway/               # API Gateway (:8080)
│   └── src/main/.../apigateway/
│       └── config/            # CorsConfig
└── frontend/                  # React-приложение (:3000)
    └── src/
        ├── api/               # Axios-инстанс с интерцепторами
        ├── context/           # AuthContext (JWT-авторизация)
        ├── components/        # Navbar (ролевая навигация)
        └── pages/             # Login, Register, Tasks, Admin
```

## 🚀 Запуск

### Предварительные требования

- **Java 17+**
- **Node.js 20+** (с npm)
- **Docker** (опционально — для PostgreSQL)

### 1. База данных

**Режим H2 (по умолчанию, без установки):**
Ничего дополнительно настраивать не нужно — H2 работает как embedded-БД.

**Режим PostgreSQL (через Docker):**
```bash
docker compose up -d
```
Затем переключить `spring.datasource.url` в `application.yml` обоих сервисов на PostgreSQL.

### 2. Бэкенд

```bash
mvn clean package -DskipTests
java -jar auth-service/target/auth-service-1.0.0-SNAPSHOT.jar
java -jar core-service/target/core-service-1.0.0-SNAPSHOT.jar
java -jar api-gateway/target/api-gateway-1.0.0-SNAPSHOT.jar
```

### 3. Фронтенд

```bash
cd frontend
npm install
npm run dev
```

### 4. Открыть в браузере

👉 **http://localhost:3000**

## 📡 API-эндпоинты

### Авторизация (`Auth Service :8081`)

| Метод | Эндпоинт | Доступ | Описание |
|-------|----------|--------|----------|
| `POST` | `/api/auth/register` | Публичный | Регистрация пользователя |
| `POST` | `/api/auth/login` | Публичный | Авторизация (возвращает JWT) |
| `GET` | `/api/users/me` | Авторизованный | Профиль текущего пользователя |
| `GET` | `/api/admin/users` | ADMIN | Список всех пользователей |
| `PUT` | `/api/admin/users/{id}/role` | ADMIN | Смена роли пользователя |
| `PUT` | `/api/admin/users/{id}/enabled` | ADMIN | Блокировка/разблокировка |

### Задачи (`Core Service :8082`)

| Метод | Эндпоинт | Доступ | Описание |
|-------|----------|--------|----------|
| `GET` | `/api/tasks` | Авторизованный | Список задач (пагинация) |
| `POST` | `/api/tasks` | Авторизованный | Создание задачи |
| `GET` | `/api/tasks/{id}` | Владелец | Получение задачи |
| `PUT` | `/api/tasks/{id}` | Владелец | Обновление задачи |
| `DELETE` | `/api/tasks/{id}` | Владелец | Удаление задачи |

> Все запросы кроме `/api/auth/**` требуют заголовок `Authorization: Bearer <JWT>`

### Gateway (`:8080`)

Все запросы через Gateway проксируются к соответствующим сервисам:
- `/api/auth/**`, `/api/admin/**`, `/api/users/**` → Auth Service
- `/api/tasks/**` → Core Service

## 🗄 Подключение к БД через DBeaver

| БД | URL | User | Password |
|----|-----|------|----------|
| Auth (пользователи) | `jdbc:h2:tcp://localhost:9091/C:/Users/User/IdeaProjects/TEST_Stend/data/auth-db` | `sa` | *(пустое)* |
| Core (задачи) | `jdbc:h2:tcp://localhost:9092/C:/Users/User/IdeaProjects/TEST_Stend/data/core-db` | `sa` | *(пустое)* |

> Драйвер в DBeaver: **H2 Embedded**

## 🔐 Ролевая модель

| Роль | Возможности |
|------|-------------|
| **USER** | Регистрация, авторизация, CRUD своих задач, просмотр профиля |
| **ADMIN** | Всё выше + просмотр всех пользователей, смена ролей, блокировка |

### Создание первого админа

Зарегистрируйся через UI, затем в DBeaver выполни:
```sql
UPDATE users SET role = 'ADMIN' WHERE username = 'your_username';
```

## 🧪 Что можно тестировать

### UI-тесты (Playwright / Cypress)

- Формы регистрации и логина (валидация полей)
- Отображение ошибок (дубли email, неверный пароль, заблокированный аккаунт)
- CRUD задач (создание, изменение статуса, удаление)
- Навигация по ролям (ссылка «Админка» видна только ADMIN)
- Блокировка пользователя → автоматический разлогин
- Пагинация задач

### API-тесты (REST Assured / Pytest / Supertest)

- `POST /api/auth/register` — успешная регистрация, дубли username/email, короткий пароль
- `POST /api/auth/login` — успешный логин, неверные данные, заблокированный юзер
- `GET /api/tasks` — пустой список, пагинация, фильтрация по владельцу
- `POST /api/tasks` — валидация полей, приоритет/статус по умолчанию
- `PUT /api/tasks/{id}` — чужая задача → 403
- `DELETE /api/tasks/{id}` — чужая задача → 403
- `GET /api/admin/users` — USER → 403, ADMIN → 200
- `PUT /api/admin/users/{id}/role` — смена роли, невалидная роль
- Истечение JWT-токена → 401

### Рекомендуемые инструменты

| Тип | Инструмент |
|-----|-----------|
| UI E2E | [Playwright](https://playwright.dev/), [Cypress](https://www.cypress.io/) |
| API | [REST Assured](https://rest-assured.io/) (Java), [Requests+Pytest](https://docs.pytest.org/) (Python) |
| Контрактные | [Pact](https://pact.io/) |
| Нагрузочные | [k6](https://k6.io/), [JMeter](https://jmeter.apache.org/) |
| Отчётность | [Allure](https://docs.qameta.io/allure/) |

## ⚙️ Конфигурация

| Параметр | Значение по умолчанию | Описание |
|----------|----------------------|----------|
| `jwt.secret` | `SuperSecretKey...` | Секрет для подписи JWT (заменить в продакшене!) |
| `jwt.expiration-ms` | `86400000` (24ч) | Время жизни JWT-токена |
| `server.port` (auth) | `8081` | Порт Auth Service |
| `server.port` (core) | `8082` | Порт Core Service |
| `server.port` (gateway) | `8080` | Порт API Gateway |
| H2 TCP (auth) | `9091` | TCP-порт H2 для DBeaver |
| H2 TCP (core) | `9092` | TCP-порт H2 для DBeaver |

## 📌 TODO

- [ ] Переключение на PostgreSQL через Spring Profiles
- [ ] Refresh-токены
- [ ] Восстановление пароля
- [ ] Фильтрация и сортировка задач
- [ ] Docker Compose для полного стека (сервисы + БД)
- [ ] Swagger/OpenAPI документация
- [ ] Примеры автотестов (Playwright + REST Assured)
- [ ] CI/CD пайплайн с запуском тестов

## ⚠️ Безопасность

**Не используй данный стенд как есть в продакшене!** Это учебный проект с намеренно упрощённой безопасностью.

- JWT-секрет **обязательно** задаётся через переменную окружения (не хранится в репо):
  ```bash
  # Windows PowerShell
  $env:JWT_SECRET="your-own-random-secret-at-least-32-bytes-long!!"

  # Linux/Mac
  export JWT_SECRET="your-own-random-secret-at-least-32-bytes-long!!"
  ```
  Или скопируй `.env.example` в `.env` и задай своё значение:
  ```bash
  cp .env.example .env
  # отредактируй .env
  ```
- H2 запущена с пользователем `sa` без пароля и открытым TCP-доступом
- Пароли в Docker Compose (`teststend/teststend`) — только для локальной разработки

## 📄 Лицензия

Учебный проект. Свободно используй для практики автотестирования.
