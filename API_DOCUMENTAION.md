# SPTM Backend API Dokümantasyonu

**Base URL:** `http://localhost:8080` (Development)

## Auth (`/api/auth`)

| Method | Endpoint             | Description       | Request Body/Params                                       |
| ------ | -------------------- | ----------------- | --------------------------------------------------------- |
| `POST` | `/api/auth/login`    | Authenticate user | Body: `LoginRequest` (`email`, `password`)                |
| `POST` | `/api/auth/register` | Register new user | Body: `RegisterRequest` (`username`, `email`, `password`) |

## Tasks (`/api/tasks`)

| Method   | Endpoint                   | Description              | Request Body/Params             |
| -------- | -------------------------- | ------------------------ | ------------------------------- |
| `POST`   | `/api/tasks`               | Create a new task        | Body: `TaskDTO`                 |
| `GET`    | `/api/tasks/user/{userId}` | Get all tasks for a user | Path: `userId`                  |
| `PUT`    | `/api/tasks/{taskId}`      | Update a task            | Path: `taskId`, Body: `TaskDTO` |
| `DELETE` | `/api/tasks/{taskId}`      | Delete a task            | Path: `taskId`                  |

## Missions (`/api/missions`)

| Method   | Endpoint                                   | Description                | Request Body/Params                          |
| -------- | ------------------------------------------ | -------------------------- | -------------------------------------------- |
| `POST`   | `/api/missions`                            | Create a mission statement | Query: `userId`, Body: String (content)      |
| `GET`    | `/api/missions/user/{userId}`              | Get missions for a user    | Path: `userId`                               |
| `POST`   | `/api/missions/{missionId}/submissions`    | Add a sub-mission          | Path: `missionId`, Body: `SubMissionDTO`     |
| `PUT`    | `/api/missions/{missionId}`                | Update a mission           | Path: `missionId`, Body: String (content)    |
| `PUT`    | `/api/missions/submissions/{subMissionId}` | Update a sub-mission       | Path: `subMissionId`, Body: String (content) |
| `DELETE` | `/api/missions/{missionId}`                | Delete a mission           | Path: `missionId`                            |
| `DELETE` | `/api/missions/submissions/{subMissionId}` | Delete a sub-mission       | Path: `subMissionId`                         |

## Visions (`/api/visions`)

| Method   | Endpoint                     | Description            | Request Body/Params                      |
| -------- | ---------------------------- | ---------------------- | ---------------------------------------- |
| `GET`    | `/api/visions/user/{userId}` | Get visions for a user | Path: `userId`                           |
| `POST`   | `/api/visions`               | Create a vision        | Query: `userId`, Body: `{"text": "..."}` |
| `PUT`    | `/api/visions/{id}`          | Update a vision        | Path: `id`, Body: `{"text": "..."}`      |
| `DELETE` | `/api/visions/{id}`          | Delete a vision        | Path: `id`                               |

## Core Values (`/api/core-values`)

| Method   | Endpoint                         | Description                | Request Body/Params                      |
| -------- | -------------------------------- | -------------------------- | ---------------------------------------- |
| `GET`    | `/api/core-values/user/{userId}` | Get core values for a user | Path: `userId`                           |
| `POST`   | `/api/core-values`               | Create a core value        | Query: `userId`, Body: `{"text": "..."}` |
| `PUT`    | `/api/core-values/{id}`          | Update a core value        | Path: `id`, Body: `{"text": "..."}`      |
| `DELETE` | `/api/core-values/{id}`          | Delete a core value        | Path: `id`                               |

## Context Tags (`/api/contexts`)

| Method   | Endpoint                      | Description                 | Request Body/Params                                     |
| -------- | ----------------------------- | --------------------------- | ------------------------------------------------------- |
| `GET`    | `/api/contexts/user/{userId}` | Get context tags for a user | Path: `userId`                                          |
| `POST`   | `/api/contexts`               | Create a context tag        | Query: `userId`, Body: `{"name": "...", "icon": "..."}` |
| `DELETE` | `/api/contexts/{id}`          | Delete a context tag        | Path: `id`                                              |

## Analytics (`/api/analytics`)

| Method | Endpoint                         | Description            | Request Body/Params                   |
| ------ | -------------------------------- | ---------------------- | ------------------------------------- |
| `GET`  | `/api/analytics/weekly/{userId}` | Get weekly statistics  | Path: `userId`                        |
| `POST` | `/api/analytics/review`          | Create a weekly review | Query: `userId`, Body: String (notes) |

## Calendar (`/api/calendar`)

**Configuration Required**: Add `sptm.google.client-id` and `sptm.google.client-secret` to `application.properties`.

| Method | Endpoint                 | Description                                | Request Body/Params     |
| ------ | ------------------------ | ------------------------------------------ | ----------------------- |
| `GET`  | `/api/calendar/auth-url` | Get Google Calendar Auth URL (Server-side) | None                    |
| `POST` | `/api/calendar/sync`     | Sync Calendar (Exchange Auth Code)         | Body: `{"code": "..."}` |
| `GET`  | `/api/calendar/events`   | Get synced events from database            | None                    |

## System

| Method | Endpoint | Description  | Request Body/Params |
| ------ | -------- | ------------ | ------------------- |
| `GET`  | `/`      | Health check | None                |
