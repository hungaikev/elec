
# Battery Management Platform API Documentation

## Table of Contents

1. [Introduction](#introduction)
2. [Authentication](#authentication)
3. [Batteries](#batteries)
4. [Battery Readings](#battery-readings)
5. [Swapping Cabinets](#swapping-cabinets)
6. [Analytics](#analytics)
7. [Alerts](#alerts)

## Introduction

Welcome to the Battery Management Platform API documentation. This API allows you to manage and monitor EV batteries and swapping cabinets, retrieve analytics, and handle alerts.

**Base URL**: `https://api.batterymanagement.com/v1`

## Authentication

All API requests must be authenticated using Bearer Token Authentication.

Include the following header in all requests:

```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

## Batteries

### List all batteries

Retrieves a list of all batteries in the system.

**Endpoint**: `GET /batteries`

**Query Parameters**:
- `status` (optional): Filter batteries by status (active, inactive, charging, discharging, maintenance)
- `limit` (optional): Number of results per page (default: 20)
- `offset` (optional): Offset for pagination (default: 0)

**Response**:

```json
{
  "data": [
    {
      "id": "uuid",
      "battery_code": "BAT001",
      "name": "Battery 1",
      "model": "Model X",
      "manufacturer": "Manufacturer A",
      "battery_type": "Lithium-ion",
      "capacity_wh": 5000,
      "nominal_voltage": 48,
      "max_charge_rate": 2,
      "max_discharge_rate": 3,
      "total_cycles": 100,
      "manufacturing_date": "2023-01-01",
      "status": "active"
    }
  ],
  "pagination": {
    "total": 100,
    "limit": 20,
    "offset": 0,
    "next": "/batteries?limit=20&offset=20",
    "previous": null
  }
}
```

### Register a new battery

Registers a new battery in the system.

**Endpoint**: `POST /batteries`

**Request Body**:

```json
{
  "battery_code": "BAT002",
  "name": "Battery 2",
  "model": "Model Y",
  "manufacturer": "Manufacturer B",
  "battery_type": "Lithium-polymer",
  "capacity_wh": 6000,
  "nominal_voltage": 52,
  "max_charge_rate": 2.5,
  "max_discharge_rate": 3.5,
  "manufacturing_date": "2023-02-15"
}
```

**Response**:

```json
{
  "id": "uuid",
  "battery_code": "BAT002",
  "name": "Battery 2",
  "model": "Model Y",
  "manufacturer": "Manufacturer B",
  "battery_type": "Lithium-polymer",
  "capacity_wh": 6000,
  "nominal_voltage": 52,
  "max_charge_rate": 2.5,
  "max_discharge_rate": 3.5,
  "total_cycles": 0,
  "manufacturing_date": "2023-02-15",
  "status": "active"
}
```

### Get battery details

Retrieves details of a specific battery.

**Endpoint**: `GET /batteries/{batteryId}`

**Response**:

```json
{
  "id": "uuid",
  "battery_code": "BAT001",
  "name": "Battery 1",
  "model": "Model X",
  "manufacturer": "Manufacturer A",
  "battery_type": "Lithium-ion",
  "capacity_wh": 5000,
  "nominal_voltage": 48,
  "max_charge_rate": 2,
  "max_discharge_rate": 3,
  "total_cycles": 100,
  "manufacturing_date": "2023-01-01",
  "status": "active"
}
```

### Update battery information

Updates information for a specific battery.

**Endpoint**: `PUT /batteries/{batteryId}`

**Request Body**:

```json
{
  "status": "charging",
  "total_cycles": 101
}
```

**Response**:

```json
{
  "id": "uuid",
  "battery_code": "BAT001",
  "name": "Battery 1",
  "model": "Model X",
  "manufacturer": "Manufacturer A",
  "battery_type": "Lithium-ion",
  "capacity_wh": 5000,
  "nominal_voltage": 48,
  "max_charge_rate": 2,
  "max_discharge_rate": 3,
  "total_cycles": 101,
  "manufacturing_date": "2023-01-01",
  "status": "charging"
}
```

### Get total distance traveled by a battery

Retrieves the total distance traveled by a specific battery.

**Endpoint**: `GET /batteries/{batteryId}/total-distance`

**Response**:

```json
{
  "battery_id": "uuid",
  "total_distance_km": 1500.5
}
```

### Get average power consumption of a battery

Retrieves the average power consumption of a battery within a specified time range.

**Endpoint**: `GET /batteries/{batteryId}/avg-power-consumption`

**Query Parameters**:
- `start_time`: Start of the time range (format: ISO 8601)
- `end_time`: End of the time range (format: ISO 8601)

**Response**:

```json
{
  "battery_id": "uuid",
  "avg_power_consumption": 250.75,
  "start_time": "2023-01-01T00:00:00Z",
  "end_time": "2023-01-31T23:59:59Z"
}
```

### Get batteries with health below threshold

Retrieves a list of batteries with health percentage below a specified threshold.

**Endpoint**: `GET /batteries/health-below-threshold`

**Query Parameters**:
- `threshold`: Health percentage threshold (0-100)

**Response**:

```json
[
  {
    "id": "uuid",
    "battery_code": "BAT001",
    "initial_capacity": 5000,
    "current_capacity": 4500,
    "total_cycles": 200,
    "health_percentage": 90
  },
  {
    "id": "uuid",
    "battery_code": "BAT002",
    "initial_capacity": 6000,
    "current_capacity": 5100,
    "total_cycles": 300,
    "health_percentage": 85
  }
]
```

## Battery Readings

### Get battery readings

Retrieves readings for a specific battery within a time range.

**Endpoint**: `GET /batteries/{batteryId}/readings`

**Query Parameters**:
- `from` (optional): Start of the time range (format: ISO 8601)
- `to` (optional): End of the time range (format: ISO 8601)

**Response**:

```json
{
  "data": [
    {
      "time": "2023-03-15T10:00:00Z",
      "state_of_charge": 85.5,
      "pack_voltage": 48.2,
      "current": 10.5,
      "internal_temperature": 35.0,
      "ambient_temperature": 25.0,
      "latitude": 40.7128,
      "longitude": -74.0060,
      "altitude": 10.0,
      "speed": 30.0,
      "power_output": 500.0,
      "charge_rate": 0,
      "discharge_rate": 2.5
    }
  ],
  "pagination": {
    "total": 100,
    "limit": 20,
    "offset": 0,
    "next": "/batteries/{batteryId}/readings?from=2023-03-15T10:00:00Z&to=2023-03-15T11:00:00Z&limit=20&offset=20",
    "previous": null
  }
}
```

### Get latest battery reading

Retrieves the most recent reading for a specific battery.

**Endpoint**: `GET /batteries/{batteryId}/latest-reading`

**Response**:

```json
{
  "time": "2023-03-15T10:00:00Z",
  "state_of_charge": 85.5,
  "pack_voltage": 48.2,
  "current": 10.5,
  "internal_temperature": 35.0,
  "ambient_temperature": 25.0,
  "latitude": 40.7128,
  "longitude": -74.0060,
  "altitude": 10.0,
  "speed": 30.0,
  "power_output": 500.0,
  "charge_rate": 0,
  "discharge_rate": 2.5
}
```

### Get cell voltages for a specific reading

Retrieves individual cell voltages for a specific battery reading.

**Endpoint**: `GET /batteries/{batteryId}/cell-voltages`

**Query Parameters**:
- `readingTime`: Timestamp of the reading (format: ISO 8601)

**Response**:

```json
[
  {
    "cell_number": 1,
    "voltage": 3.7
  },
  {
    "cell_number": 2,
    "voltage": 3.8
  }
]
```

## Swapping Cabinets

### List all swapping cabinets

Retrieves a list of all swapping cabinets in the system.

**Endpoint**: `GET /swapping-cabinets`

**Query Parameters**:
- `status` (optional): Filter cabinets by status (active, inactive, maintenance)

**Response**:

```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Cabinet A",
      "latitude": 40.7128,
      "longitude": -74.0060,
      "address": "123 Main St, City, Country",
      "total_slots": 10,
      "available_slots": 5,
      "status": "active",
      "power_source": "grid",
      "last_maintenance_date": "2023-01-15"
    }
  ],
  "pagination": {
    "total": 50,
    "limit": 20,
    "offset": 0,
    "next": "/swapping-cabinets?limit=20&offset=20",
    "previous": null
  }
}
```

### Get swapping cabinet details

Retrieves details of a specific swapping cabinet.

**Endpoint**: `GET /swapping-cabinets/{cabinetId}`

**Response**:

```json
{
  "id": "uuid",
  "name": "Cabinet A",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "address": "123 Main St, City, Country",
  "total_slots": 10,
  "available_slots": 5,
  "status": "active",
  "power_source": "grid",
  "last_maintenance_date": "2023-01-15"
}
```

### Get status of all slots in a cabinet

Retrieves the status of all slots in a specific swapping cabinet.

**Endpoint**: `GET /swapping-cabinets/{cabinetId}/slots`

**Response**:

```json
[
  {
    "id": "uuid",
    "slot_number": 1,
    "status": "occupied",
    "battery_id": "uuid",
    "last_updated": "2023-03-15T10:00:00Z"
  },
  {
    "id": "uuid",
    "slot_number": 2,
    "status": "empty",
    "battery_id": null,
    "last_updated": "2023-03-15T09:30:00Z"
  }
]
```

### Update slot status

Updates the status of a specific slot in a swapping cabinet.

**Endpoint**: `PUT /swapping-cabinets/{cabinetId}/slots/{slotId}`

**Request Body**:

```json
{
  "status": "charging",
  "battery_id": "uuid"
}
```

**Response**:

```json
{
  "id": "uuid",
  "slot_number": 1,
  "status": "charging",
  "battery_id": "uuid",
  "last_updated": "2023-03-15T10:30:00Z"
}
```

### Get metrics for a swapping cabinet

Retrieves metrics for a specific swapping cabinet.

**Endpoint**: `GET /swapping-cabinets/{cabinetId}/metrics`

**Query Parameters**:
- `from` (optional): Start of the time range (format: ISO 8601)
- `to` (optional): End of the time range (format: ISO 8601)

**Response**:

```json
{
  "total_swaps": 100,
  "energy_consumed_kwh": 500.5,
  "grid_energy_kwh": 400.0,
  "solar_energy_kwh": 100.5,
  "peak_usage_time": "18:00:00",
  "average_charging_time_minutes": 45.5
}
```

### Get total energy consumption of all swapping cabinets

Retrieves the total energy consumption of all swapping cabinets within a specified time range.

**Endpoint**: `GET /swapping-cabinets/energy-consumption`

**Query Parameters**:
- `start_time`: Start of the time range (format: ISO 8601)
- `end_time`: End of the time range (format: ISO 8601)

**Response**:

```json
{
  "total_energy_kwh": 10000.5,
  "grid_energy_kwh": 8000.0,
  "solar_energy_kwh": 2000.5,
  "start_time": "2023-01-01T00:00:00Z",
  "end_time": "2023-03-31T23:59:59Z"
}
```

## Analytics

### Get battery health analytics

Retrieves analytics data about overall battery health.

**Endpoint**: `GET /analytics/battery-health`

**Query Parameters**:
- `from` (optional): Start of the time range (format: ISO 8601)
- `to` (optional): End of the time range (format: ISO 8601)

**Response**:

```json
{
  "average_health": 92.5,
  "health_distribution": {
    "90-100": 50,
    "80-89": 30,
    "70-79": 15,
    "60-69": 5
  },
  "batteries_below_threshold": 3
}
```

### Get most active swapping cabinets

Retrieves a list of the most active swapping cabinets within a specified time range.

**Endpoint**: `GET /analytics/most-active-cabinets`

**Query Parameters**:
- `from`: Start of the time range (format: ISO 8601)
- `to`: End of the time range (format: ISO 8601)
- `limit` (optional): Number of results to return (default: 10)

**Response**:

```json
[
  {
    "cabinet_id": "uuid",
    "total_swaps": 500,
    "total_energy_consumed_kwh": 2500.5
  },
  {
    "cabinet_id": "uuid",
    "total_swaps": 450,
    "total_energy_consumed_kwh": 2250.0
  }
]
```


### Get battery usage analytics

Retrieves analytics data about battery usage within a specified time range.

**Endpoint**: `GET /analytics/battery-usage`

**Query Parameters**:
- `start_time`: Start of the time range (format: ISO 8601)
- `end_time`: End of the time range (format: ISO 8601)

**Response**:

```json
{
  "total_energy_consumed": 50000.5,
  "average_discharge_rate": 2.5,
  "peak_usage_time": "18:30:00",
  "most_used_batteries": [
    {
      "battery_id": "uuid",
      "usage_count": 100
    },
    {
      "battery_id": "uuid",
      "usage_count": 95
    }
  ]
}
```

## Alerts

### List all alerts

Retrieves a list of all alerts in the system.

**Endpoint**: `GET /alerts`

**Query Parameters**:
- `status` (optional): Filter alerts by status (active, resolved)
- `severity` (optional): Filter alerts by severity (low, medium, high, critical)

**Response**:

```json
{
  "data": [
    {
      "id": "uuid",
      "alert_type": "Low Battery",
      "severity": "high",
      "status": "active",
      "battery_id": "uuid",
      "cabinet_id": null,
      "message": "Battery charge level critically low",
      "created_at": "2023-03-15T10:00:00Z",
      "resolved_at": null
    }
  ],
  "pagination": {
    "total": 50,
    "limit": 20,
    "offset": 0,
    "next": "/alerts?limit=20&offset=20",
    "previous": null
  }
}
```

## Error Handling

The API uses conventional HTTP response codes to indicate the success or failure of an API request. In general:

- 2xx range indicate success
- 4xx range indicate an error that failed given the information provided (e.g., a required parameter was omitted, etc.)
- 5xx range indicate an error with our servers

### Error Response Format

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "A human-readable error message"
  }
}
```

## Rate Limiting

The API implements rate limiting to prevent abuse and ensure stability. The current rate limit is:

- 1000 requests per hour per API key

If you exceed the rate limit, you will receive a 429 Too Many Requests response.

## Pagination

For endpoints that return lists of items, the API uses cursor-based pagination. The `pagination` object in the response contains the following fields:

- `total`: Total number of items
- `limit`: Number of items per page
- `offset`: Current offset
- `next`: URL for the next page of results (null if there are no more results)
- `previous`: URL for the previous page of results (null if this is the first page)
