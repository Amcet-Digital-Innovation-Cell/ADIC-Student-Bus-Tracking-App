# Architecture and API Requirement Document

## 1. Architecture & Tech Stack

### Project Type
This workspace is not a classic web-based admin dashboard. The current frontend implementation is a Flutter transport-tracking application for viewing college bus routes and tracking a selected bus on a map. The architecture is therefore a mobile-first UI with lightweight local state management.

### Core Framework
- Framework: Flutter
- Language: Dart
- UI system: Material Design widgets via Flutter Material
- Runtime target: mobile/web support via Flutter, with the current code focused on a mobile-style experience

### State Management
The app uses local widget state rather than a dedicated state-management library such as Provider, Riverpod, Bloc, Redux, or MobX.

Observed pattern:
- Home screen manages route filtering in a StatefulWidget
- Tracking screen manages map mode and UI state in a StatefulWidget
- Bottom sheet uses pass-through data from the parent widget

### Routing
Routing is simple and declarative:
- Root route: `/`
- Home route: `/home`

Implemented in the app entrypoint via `MaterialApp.routes`.

### UI & Mapping Libraries
- Material Design: built-in Flutter widgets
- Map rendering: `flutter_map`
- Coordinate model: `latlong2`

### Notable Architectural Characteristics
- Static seed data is embedded in the frontend rather than fetched from a backend
- Screens are composed from simple stateful widgets
- No authentication, role-based access control, or API client layer is present yet
- The app is designed around route browsing and stop visualization, not analytics dashboards

---

## 2. Component & Screen Breakdown

### A. Splash Screen
Purpose:
- Welcome/branding screen
- Transition to home screen after a short animated experience

Primary interactions:
- Tap “Get Started” to navigate to the home screen

Backend relevance:
- None at present; no API dependency

### B. Home Screen
Purpose:
- List available bus routes
- Search routes by bus name, route name, or stop name
- Open the route detail bottom sheet
- Navigate to tracking screen

Primary interactions:
- Search input filtering
- Route card selection
- “Stops” action opening a modal sheet
- “Track” action navigating to the tracking screen

Frontend assumptions:
- The list of routes is loaded from an in-memory list
- Search works client-side by matching text across route name, bus number, and stops

### C. Tracking Screen
Purpose:
- Display a map for the selected bus route
- Show the current route mode (morning vs evening)
- Allow the user to toggle route mode manually
- Open the stops sheet

Primary interactions:
- Map recentering
- Refresh action
- Manual mode toggle
- Tap bus card to view stops

Frontend assumptions:
- The map is a placeholder using a static initial coordinate and a marker
- Real-time bus position and live updates are not implemented yet

### D. Stops Bottom Sheet
Purpose:
- Display the ordered stop list for a route
- Highlight starting and destination stops
- Reflect morning or evening direction

Primary interactions:
- Scroll through the stop list
- Dismiss the sheet

---

## 3. Data Models & Entities

The frontend currently uses a compact route-centric model. A backend should expose these entities in a normalized shape.

### 3.1 BusRoute
```json
{
  "id": "string",
  "routeName": "string",
  "busNo": "string",
  "forwardStops": ["string", "string"],
  "isActive": true,
  "collegeName": "string"
}
```

Required fields:
- id: unique route identifier
- routeName: display name for the route
- busNo: bus identifier shown on cards
- forwardStops: ordered list of stops for the morning direction
- isActive: whether the route should be shown as active
- collegeName: optional college context for the app branding

### 3.2 Stop
```json
{
  "id": "string",
  "name": "string",
  "sequence": 1,
  "latitude": 12.9165,
  "longitude": 79.1325,
  "isTerminal": false
}
```

Required fields:
- id: unique stop identifier
- name: stop display name
- sequence: ordering within route
- latitude/longitude: optional geolocation for maps
- isTerminal: identifies first or last stop

### 3.3 RouteSchedule / TripMode
```json
{
  "routeId": "string",
  "mode": "morning|evening",
  "stops": ["stopId1", "stopId2"],
  "departTime": "08:00",
  "returnTime": "17:30"
}
```

Required fields:
- routeId: route reference
- mode: morning or evening travel direction
- stops: ordered stop references
- departTime/returnTime: schedule hints

### 3.4 VehicleTrackingSnapshot
```json
{
  "routeId": "string",
  "vehicleId": "string",
  "latitude": 12.9165,
  "longitude": 79.1325,
  "updatedAt": "2026-08-01T10:30:00Z",
  "speedKph": 24,
  "status": "moving|stopped|offline"
}
```

Required fields:
- routeId: relevant route
- vehicleId: bus identifier
- latitude/longitude: current position
- updatedAt: timestamp for freshness
- speedKph: optional telemetry
- status: current state of tracking

### 3.5 SearchQuery
The frontend expects search to work over the following fields:
- route name
- bus number
- stop names

A backend search endpoint should support these terms and return ranked route matches.

---

## 4. API Endpoints & Contract Requirements

The current frontend does not call any backend APIs. All data is hard-coded in the UI. To support a production-ready version of this app, the backend should implement REST endpoints with the following contracts.

### Notes on API Style
- REST is the most natural fit for this frontend.
- GraphQL is optional but not required for the current feature set.
- The backend should return stable, predictable JSON structures with consistent field names.

---

### Endpoint 1: List all active routes
Method: GET
Path: /api/routes

Query parameters:
- search (optional): free-text match against route name, bus number, stop names
- active (optional): true|false
- mode (optional): morning|evening

Example:
- GET /api/routes?search=walaja

Success response:
```json
{
  "data": [
    {
      "id": "route_001",
      "routeName": "Walaja",
      "busNo": "Bus 14",
      "forwardStops": ["Walaja Toll", "Ranipet", "Arcot", "Collectorate", "Annai Mira College"],
      "isActive": true,
      "collegeName": "Annai Mira College of Engineering"
    }
  ],
  "meta": {
    "count": 1
  }
}
```

Required behavior:
- Return a list of routes visible to the user
- Filtering should support search text without requiring the client to sort locally

---

### Endpoint 2: Get a single route by ID
Method: GET
Path: /api/routes/{routeId}

Path parameter:
- routeId: string

Success response:
```json
{
  "data": {
    "id": "route_001",
    "routeName": "Sankaranpalayam",
    "busNo": "Bus 10",
    "forwardStops": ["Main Bus St", "Sankaranpalayam", "Old Bus Stand", "Collectorate", "Annai Mira College"],
    "isActive": true,
    "collegeName": "Annai Mira College of Engineering"
  }
}
```

Error response:
```json
{
  "error": {
    "code": "ROUTE_NOT_FOUND",
    "message": "Route not found"
  }
}
```

---

### Endpoint 3: Get ordered stops for a route in a specific mode
Method: GET
Path: /api/routes/{routeId}/stops

Query parameters:
- mode (required): morning|evening

Example:
- GET /api/routes/route_001/stops?mode=evening

Success response:
```json
{
  "data": {
    "routeId": "route_001",
    "mode": "evening",
    "stops": [
      {
        "id": "stop_005",
        "name": "Annai Mira College",
        "sequence": 1,
        "latitude": 12.9165,
        "longitude": 79.1325,
        "isTerminal": true
      },
      {
        "id": "stop_004",
        "name": "Collectorate",
        "sequence": 2,
        "latitude": 12.9181,
        "longitude": 79.1338,
        "isTerminal": false
      }
    ]
  }
}
```

Required behavior:
- Return the ordered list of stops for the selected direction
- Morning mode should follow the forward route order
- Evening mode should return the reverse route order

---

### Endpoint 4: Get current vehicle position for tracking
Method: GET
Path: /api/routes/{routeId}/tracking

Query parameters:
- mode (optional): morning|evening
- includeHistory (optional): true|false

Example:
- GET /api/routes/route_001/tracking?mode=morning

Success response:
```json
{
  "data": {
    "routeId": "route_001",
    "vehicleId": "bus_014",
    "latitude": 12.9192,
    "longitude": 79.1314,
    "updatedAt": "2026-08-01T10:30:00Z",
    "speedKph": 24,
    "status": "moving"
  }
}
```

Required behavior:
- Return the latest bus location for the selected route
- The frontend can use this to render a map marker and update the vehicle card

---

### Endpoint 5: List tracking history for a route
Method: GET
Path: /api/routes/{routeId}/tracking/history

Query parameters:
- from (optional): ISO timestamp
- to (optional): ISO timestamp
- limit (optional): integer

Success response:
```json
{
  "data": [
    {
      "routeId": "route_001",
      "vehicleId": "bus_014",
      "latitude": 12.9192,
      "longitude": 79.1314,
      "updatedAt": "2026-08-01T10:30:00Z",
      "speedKph": 24,
      "status": "moving"
    }
  ],
  "meta": {
    "count": 1
  }
}
```

Required behavior:
- Useful if the app later supports a live path or breadcrumb trail

---

### Endpoint 6: Search routes
Method: GET
Path: /api/routes/search

Query parameters:
- q (required): search string

Example:
- GET /api/routes/search?q=collectorate

Success response:
```json
{
  "data": [
    {
      "id": "route_001",
      "routeName": "Sankaranpalayam",
      "busNo": "Bus 10",
      "matchReason": "stop_match"
    }
  ]
}
```

Required behavior:
- Return lightweight route results ranked by relevance
- Match across route names, bus number, and stop names

---

### Endpoint 7: Create or update a route (admin operation)
Method: POST or PUT
Path: /api/routes
or /api/routes/{routeId}

Request body:
```json
{
  "routeName": "New Route",
  "busNo": "Bus 15",
  "forwardStops": ["Start", "Stop 1", "Stop 2", "Destination"],
  "isActive": true,
  "collegeName": "Annai Mira College of Engineering"
}
```

Success response:
```json
{
  "data": {
    "id": "route_002",
    "routeName": "New Route",
    "busNo": "Bus 15",
    "forwardStops": ["Start", "Stop 1", "Stop 2", "Destination"],
    "isActive": true,
    "collegeName": "Annai Mira College of Engineering"
  }
}
```

Required behavior:
- Enables future admin dashboard operations for route management

---

### Endpoint 8: Create or update a stop (admin operation)
Method: POST or PUT
Path: /api/stops
or /api/stops/{stopId}

Request body:
```json
{
  "name": "Collectorate",
  "latitude": 12.9181,
  "longitude": 79.1338,
  "isTerminal": false
}
```

Success response:
```json
{
  "data": {
    "id": "stop_004",
    "name": "Collectorate",
    "latitude": 12.9181,
    "longitude": 79.1338,
    "isTerminal": false
  }
}
```

---

## Suggested Backend Capabilities for Production

To evolve this frontend into a true admin dashboard, the backend should also support:
- Authentication and authorization
- Role-based access for admin vs student users
- Pagination and sorting for large route tables
- Websocket or polling for live bus location updates
- Audit logs for admin edits
- Analytics endpoints for route utilization and attendance-like metrics

---

## Summary

The current frontend is a route-search and bus-tracking experience built with Flutter, Material Design, and Flutter Map. It uses local state and hard-coded route data. The backend contract implied by the UI is centered around route discovery, stop ordering, and live tracking rather than classic dashboard CRUD and analytics.
