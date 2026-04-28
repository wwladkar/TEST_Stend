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
| **Frontend** | React 18, JavaScript (JSX), Vite, Axios, React Router |
| **API Gateway** | Spring Cloud Gateway (MVC) |
| **Auth Service** | Spring Boot 3.2, Spring Security, JWT (jjwt 0.12), JPA |
| **Core Service** | Spring Boot 3.2, Spring Security, JWT, JPA |
| **Common Security** | Общий модуль: JWT, фильтры, CORS, blacklist (shared lib) |
| **БД** | H2 (embedded, текущая) / PostgreSQL (Docker Compose) |
| **Инфраструктура** | Docker Compose, Maven (multi-module) |

## 📂 Структура проекта

```
TEST_Stend/
├── pom.xml                    # Корневой Maven (multi-module)
├── docker-compose.yml         # Полный стек: PostgreSQL + сервисы + frontend
├── .env.example               # Шаблон переменных окружения (JWT_SECRET и др.)
├── stend.ps1                  # Скрипт управления (Windows)
├── stend.sh                   # Скрипт управления (Linux/Mac)
├── common-security/           # Общий модуль безопасности
│   └── src/main/.../common/security/
│       ├── BaseSecurityConfig.java     # CORS-конфигурация
│       ├── JwtTokenProvider.java       # Генерация JWT
│       ├── JwtAuthFilter.java          # Фильтр валидации JWT
│       ├── TokenBlacklist.java         # In-memory блэклист токенов
│       └── GlobalExceptionHandler.java # IllegalArgumentException → 404
├── auth-service/              # Сервис авторизации (:8081)
│   └── src/main/.../authservice/
│       ├── config/            # SecurityConfig, AuthExceptionHandler, H2ServerConfig
│       ├── controller/        # AuthController, UserController, AdminController
│       ├── dto/               # LoginRequest, RegisterRequest, AuthResponse, UserDto,
│       │                      # RoleChangeRequest, ToggleEnabledRequest
│       ├── entity/            # User
│       └── repository/        # UserRepository
├── core-service/              # Сервис задач (:8082)
│   └── src/main/.../coreservice/
│       ├── config/            # SecurityConfig, H2ServerConfig
│       ├── controller/        # TaskController
│       ├── dto/               # TaskRequest, TaskDto
│       ├── entity/            # Task, TaskStatus, TaskPriority
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
- **Maven 3.9+** (или используй Maven Wrapper — см. ниже)
- **Node.js 20+** (с npm)
- **Docker** (опционально — для полного стека)

### 0. Переменные окружения (обязательно!)

Перед запуском бэкенда задай JWT-секрет:

```bash
# Скопируй шаблон и задай свой секрет
# Linux/Mac:
cp .env.example .env
# Windows PowerShell:
copy .env.example .env
# Отредактируй .env — укажи уникальный JWT_SECRET (минимум 32 байта)
```

> Эта переменная нужна **до** любого запуска бэкенда — как локального, так и через Docker Compose.

Или установи переменную напрямую:
```bash
# Windows PowerShell
$env:JWT_SECRET="your-own-random-secret-at-least-32-bytes-long!!"

# Linux/Mac
export JWT_SECRET="your-own-random-secret-at-least-32-bytes-long!!"
```

> ⚠️ Без `JWT_SECRET` бэкенд **не запустится** — Spring упадёт при создании `JwtTokenProvider`.

### 1. Быстрый старт (одной командой)

Проект содержит скрипты для управления стендом — сборка, запуск, остановка и мониторинг:

**Windows:**
```powershell
.\stend.ps1              # сборка + запуск всех сервисов
.\stend.ps1 start        # запустить без сборки
.\stend.ps1 stop         # остановить все сервисы
.\stend.ps1 restart      # перезапуск
.\stend.ps1 status       # проверить статус портов
.\stend.ps1 clean        # удалить БД + логи + пересобрать
```

**Linux/Mac:**
```bash
chmod +x stend.sh        # первый раз — сделать исполняемым
./stend.sh               # сборка + запуск всех сервисов
./stend.sh start         # запустить без сборки
./stend.sh stop          # остановить все сервисы
./stend.sh restart       # перезапуск
./stend.sh status        # проверить статус портов
./stend.sh clean         # удалить БД + логи + пересобрать
```

Скрипты автоматически:
- Определяют пути к Java и Maven (проверяют `JAVA_HOME`, `PATH`, Maven Wrapper)
- Загружают и валидируют `.env` (включая проверку `JWT_SECRET`)
- Запускают сервисы с перенаправлением логов в `logs/`
- Ждут готовности каждого сервиса (по TCP-порту)

### 2. Полный стек через Docker Compose

Если Docker установлен — это самый простой вариант, не требующий Java/Maven/Node:

```bash
docker compose up -d
```

Поднимает PostgreSQL, все бэкенд-сервисы и frontend одной командой.
Сервисы автоматически используют PostgreSQL (профиль `pg` активируется через `SPRING_PROFILES_ACTIVE` в docker-compose.yml).

> `docker compose` автоматически подхватит переменную `JWT_SECRET` из файла `.env` (шаг 0).

### 3. Ручной запуск (H2, без Docker)

**Режим H2 (по умолчанию):**
H2 работает как embedded-БД, ничего дополнительно настраивать не нужно.

Порядок запуска:
```bash
# 1. Собрать (Maven Wrapper или системный Maven)
# Через Maven Wrapper (рекомендуется, если Maven не установлен):
./mvnw clean package -DskipTests        # Linux/Mac
.\mvnw.cmd clean package -DskipTests    # Windows
# Или через системный Maven:
mvn clean package -DskipTests

# 2. Запустить сервисы (в отдельных терминалах)
java -jar auth-service/target/auth-service-1.0.0-SNAPSHOT.jar
java -jar core-service/target/core-service-1.0.0-SNAPSHOT.jar
java -jar api-gateway/target/api-gateway-1.0.0-SNAPSHOT.jar
```

**Режим PostgreSQL (локально с внешней БД):**
Если PostgreSQL уже запущен (например, через `docker compose up -d postgres`),
добавь флаг `--spring.profiles.active=pg` — он подключит `application-pg.yml` с настройками PostgreSQL:
```bash
java -jar auth-service/target/auth-service-1.0.0-SNAPSHOT.jar --spring.profiles.active=pg
java -jar core-service/target/core-service-1.0.0-SNAPSHOT.jar --spring.profiles.active=pg
java -jar api-gateway/target/api-gateway-1.0.0-SNAPSHOT.jar
```

### 4. Фронтенд (только при ручном запуске)

```bash
cd frontend
npm install
npm run dev
```

### 5. Открыть в браузере

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
| `jwt.secret` | *(обязательный env)* | Секрет для подписи JWT. Задаётся через `JWT_SECRET`, без значения по умолчанию |
| `jwt.expiration-ms` | `86400000` (24ч) | Время жизни JWT-токена |
| `server.port` (auth) | `8081` | Порт Auth Service |
| `server.port` (core) | `8082` | Порт Core Service |
| `server.port` (gateway) | `8080` | Порт API Gateway |
| H2 TCP (auth) | `9091` | TCP-порт H2 для DBeaver |
| H2 TCP (core) | `9092` | TCP-порт H2 для DBeaver |

## 📌 TODO

- [x] Переключение на PostgreSQL через Spring Profiles
- [ ] Refresh-токены
- [ ] Восстановление пароля
- [ ] Фильтрация и сортировка задач
- [x] Docker Compose для полного стека (сервисы + БД)
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
