# Habit Tracker Backend

Node.js backend with Express and MongoDB for the Habit Tracker Flutter app.

## Setup

1. **Install dependencies:**
   ```bash
   cd backend
   npm install
   ```

2. **Configure environment variables:**
   
   Edit the `.env` file with your actual MongoDB password:
   ```
   MONGODB_URI=mongodb+srv://admin:YOUR_PASSWORD@vibecoding.otpwy2r.mongodb.net/habit_tracker?retryWrites=true&w=majority&appName=vibecoding
   JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
   PORT=3000
   ```

3. **Start the server:**
   ```bash
   npm start
   # or for development with auto-reload:
   npm run dev
   ```

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/signup` | Register a new user |
| POST | `/api/auth/signin` | Login user |
| GET | `/api/auth/me` | Get current user (requires auth) |

### Habits (All require authentication)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/habits` | Get all habits for user |
| POST | `/api/habits` | Create a new habit |
| PUT | `/api/habits/:id` | Update a habit |
| DELETE | `/api/habits/:id` | Delete a habit |
| POST | `/api/habits/:id/toggle` | Toggle a day's completion |
| POST | `/api/habits/sync` | Bulk sync all habits |
| GET | `/api/habits/layout` | Get layout settings |
| PUT | `/api/habits/layout` | Update layout settings |

## Request/Response Examples

### Sign Up
```json
POST /api/auth/signup
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}

Response:
{
  "message": "User created successfully",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "...",
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

### Create Habit
```json
POST /api/habits
Authorization: Bearer <token>
{
  "name": "Morning Exercise",
  "goalDays": 30
}
```

### Toggle Day
```json
POST /api/habits/:id/toggle
Authorization: Bearer <token>
{
  "date": "2026-01-28"
}
```

## Flutter App Configuration

In the Flutter app, update the API base URL in `lib/config/api_config.dart`:

```dart
// For Android emulator
static const String baseUrl = 'http://10.0.2.2:3000/api';

// For iOS simulator
static const String baseUrl = 'http://localhost:3000/api';

// For physical device (use your computer's IP)
static const String baseUrl = 'http://192.168.x.x:3000/api';

// For web
static const String baseUrl = 'http://localhost:3000/api';
```
