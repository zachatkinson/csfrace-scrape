# SSE Refactoring Plan - DRY/SOLID Best Practices

## Executive Summary

Complete refactoring of all Server-Sent Events (SSE) endpoints following DRY, SOLID principles, and 2025 best practices. This refactoring eliminates code duplication, establishes a unified architecture, and removes all legacy/dead code.

## Current State Analysis

### Backend SSE Endpoints (7 files found)

1. **✅ `/backend/src/api/routers/jobs/streaming.py`** (372 lines)
   - **Status**: GOOD - Modern, optimized, Redis pub/sub
   - **Pattern**: Event-driven with terminal state tracking
   - **Issue**: None - This is our reference implementation

2. **⚠️ `/backend/src/api/routers/health_stream.py`** (157 lines)
   - **Status**: POOR - Static snapshot then closes
   - **Pattern**: Sends data once, no real-time updates
   - **Issue**: Not event-driven, polling-based

3. **⚠️ `/backend/src/api/routers/performance_stream.py`** (169 lines)
   - **Status**: POOR - 30-second polling loop
   - **Pattern**: Inefficient polling, sends updates regardless of changes
   - **Issue**: Not event-driven, wastes bandwidth

4. **❌ `/backend/src/api/routers/health/streaming.py`** (24 lines)
   - **Status**: LEGACY - Test endpoint only
   - **Pattern**: Simple test endpoint (not real SSE)
   - **Action**: DELETE - No longer needed

5. **🤔 `/backend/src/api/routers/events/sse.py`** (184 lines)
   - **Status**: UNUSED? - Generic event bus SSE
   - **Pattern**: Modern event bus architecture
   - **Action**: EVALUATE - May be legacy or future feature

### Frontend SSE Clients (4 files found)

1. **✅ `/frontend/src/services/JobSSEService.ts`** (349 lines)
   - **Status**: GOOD - Modern, follows SOLID
   - **Pattern**: EventSource with retry logic
   - **Issue**: None - Reference implementation

2. **⚠️ `/frontend/src/services/SSEStreamService.ts`** (257 lines)
   - **Status**: OVER-ENGINEERED - Handler pattern unnecessary
   - **Pattern**: Message handlers, abstract classes
   - **Issue**: 200+ lines for simple SSE client

3. **⚠️ `/frontend/src/services/PerformanceSSEService.ts`** (169 lines)
   - **Status**: DUPLICATE - Same as JobSSEService logic
   - **Pattern**: Copy-paste of SSE connection logic
   - **Issue**: Violates DRY principle

4. **⚠️ `/frontend/src/services/SSEPerformanceService.ts`** (263 lines)
   - **Status**: UTILITY - Performance metrics (not SSE transport)
   - **Pattern**: Adaptive polling, threshold detection
   - **Action**: KEEP but rename to avoid confusion

### Legacy/Dead Files to Remove

- ❌ `/backend/src/api/routers/health/streaming.py` - Test endpoint only
- ❌ `/backend/src/api/routers/events/sse.py` - Unused generic event bus
- ❌ `/frontend/src/services/SSEStreamService.ts` - Over-engineered, unused
- ❌ `/frontend/src/pages/api/health/stream.ts` - Duplicate endpoint
- ❌ `/frontend/src/pages/api/auth/stream.ts` - Duplicate endpoint

## Problems Identified

### Backend Issues

1. **Code Duplication**: Each endpoint implements its own SSE logic
2. **Inconsistent Patterns**: Mix of polling, static, and event-driven
3. **No Base Abstraction**: No shared SSE utilities
4. **Inefficient Streaming**: health_stream and performance_stream waste resources
5. **No Redis Integration**: Only jobs use Redis pub/sub

### Frontend Issues

1. **Massive Code Duplication**: 600+ lines of duplicated SSE connection logic
2. **No Base Client**: Each service reimplements EventSource handling
3. **Inconsistent Error Handling**: Different retry strategies across services
4. **Over-Engineering**: SSEStreamService has unnecessary abstraction layers
5. **Confusing Naming**: SSEPerformanceService is NOT an SSE client

## Unified SSE Architecture

### Backend Architecture

```
src/core/sse/
├── __init__.py
├── base.py              # BaseSSEService abstract class
├── events.py            # SSE event formatting utilities
└── redis_publisher.py   # Redis pub/sub integration

src/api/routers/
├── jobs/streaming.py    # Uses BaseSSEService + Redis
├── health_stream.py     # Refactored to use BaseSSEService + Redis
└── performance_stream.py # Refactored to use BaseSSEService + Redis
```

### Frontend Architecture

```
src/services/sse/
├── BaseSSEClient.ts     # Abstract base class for all SSE clients
├── JobSSEClient.ts      # Extends BaseSSEClient
├── HealthSSEClient.ts   # Extends BaseSSEClient
└── PerformanceSSEClient.ts  # Extends BaseSSEClient

src/utils/
└── performanceMetrics.ts  # Renamed from SSEPerformanceService
```

## Implementation Plan

### Phase 1: Backend Base Abstraction (30 min)

**Task**: Create `src/core/sse/` module with reusable SSE utilities

**Files to Create**:

1. `/backend/src/core/sse/__init__.py`
2. `/backend/src/core/sse/base.py` - BaseSSEService abstract class
3. `/backend/src/core/sse/events.py` - SSE formatting utilities
4. `/backend/src/core/sse/redis_publisher.py` - Redis pub/sub helpers

**Key Features**:
- Abstract `BaseSSEService` class with common SSE logic
- `safe_json_dumps()` utility (DRY from jobs/streaming.py)
- Redis subscription helpers
- Terminal state tracking pattern
- Connection/keepalive event generation

### Phase 2: Refactor Health SSE (20 min)

**Task**: Replace static snapshot with event-driven Redis pub/sub

**Changes to `/backend/src/api/routers/health_stream.py`**:
- Extend `BaseSSEService`
- Subscribe to `health_events` Redis channel
- Only send updates when service health changes
- Implement terminal state tracking (no updates for healthy services)
- Reduce from 157 lines to ~80 lines

**New Redis Publisher** `/backend/src/monitoring/health_events.py`:
- `publish_health_status_update()` function
- Called when health check detects changes
- Publishes to `health_events` Redis channel

### Phase 3: Refactor Performance SSE (20 min)

**Task**: Replace 30-second polling with threshold-based updates

**Changes to `/backend/src/api/routers/performance_stream.py`**:
- Extend `BaseSSEService`
- Subscribe to `performance_events` Redis channel
- Only send updates when metrics change >10%
- Implement smart thresholding
- Reduce from 169 lines to ~80 lines

**New Redis Publisher** `/backend/src/monitoring/performance_events.py`:
- `publish_performance_update()` function
- Called by performance monitoring
- Only publishes significant changes (>10% CPU, >10% memory, etc.)

### Phase 4: Frontend Base Client (30 min)

**Task**: Create `BaseSSEClient` abstract class

**File to Create**: `/frontend/src/services/sse/BaseSSEClient.ts`

**Key Features**:
- Abstract base class with EventSource management
- Exponential backoff retry logic (from JobSSEService.ts)
- Connection state management
- Automatic reconnection
- Event callback registration
- Error handling patterns
- ~150 lines (replaces 600+ lines of duplicated code)

### Phase 5: Refactor Frontend Clients (30 min)

**Task**: Migrate all SSE clients to extend `BaseSSEClient`

**Files to Refactor**:
1. `/frontend/src/services/sse/JobSSEClient.ts` - Extract from JobSSEService.ts
2. `/frontend/src/services/sse/HealthSSEClient.ts` - New, extends BaseSSEClient
3. `/frontend/src/services/sse/PerformanceSSEClient.ts` - Refactor PerformanceSSEService.ts

**Result**: Each client reduced to ~50-80 lines (just event-specific logic)

### Phase 6: Cleanup Legacy Code (15 min)

**Task**: Remove all dead/legacy/duplicate files

**Files to DELETE**:

Backend:
- ❌ `/backend/src/api/routers/health/streaming.py`
- ❌ `/backend/src/api/routers/events/sse.py`

Frontend:
- ❌ `/frontend/src/services/SSEStreamService.ts`
- ❌ `/frontend/src/pages/api/health/stream.ts`
- ❌ `/frontend/src/pages/api/auth/stream.ts`

**File to RENAME**:
- `/frontend/src/services/SSEPerformanceService.ts` → `/frontend/src/utils/performanceMetrics.ts`

### Phase 7: Update Documentation (15 min)

**Task**: Add SSE best practices to CLAUDE.md

**Files to Update**:
1. `/backend/CLAUDE.md` - Add "SSE Best Practices" section
2. `/frontend/CLAUDE.md` - Add "SSE Client Standards" section

**Key Documentation**:
- When to use event-driven vs polling
- Redis pub/sub integration patterns
- Terminal state tracking
- Frontend BaseSSEClient usage
- Error handling and retry strategies

### Phase 8: End-to-End Testing (30 min)

**Task**: Test all SSE endpoints with real auth

**Test Scenarios**:
1. Job SSE: Create job → monitor pending → processing → completed
2. Health SSE: Restart service → monitor status change
3. Performance SSE: Generate load → monitor metric updates
4. All SSE: Test reconnection after network failure
5. All SSE: Test multiple concurrent connections

## Code Reduction Metrics

### Backend
- **Before**: 520 lines across 4 active files + 184 lines in legacy
- **After**: ~300 lines (base abstraction + 3 refactored endpoints)
- **Reduction**: ~42% less code, 100% DRY compliance

### Frontend
- **Before**: 1,038 lines across 4 files
- **After**: ~350 lines (base client + 3 specific clients + utils)
- **Reduction**: ~66% less code, SOLID architecture

### Total Impact
- **Lines Removed**: ~908 lines
- **DRY Violations Fixed**: 5 major duplications eliminated
- **Files Deleted**: 5 legacy files removed
- **Architecture**: Unified, maintainable, scalable

## Success Criteria

### Technical Requirements
- ✅ All SSE endpoints use Redis pub/sub
- ✅ No code duplication across SSE implementations
- ✅ Base abstractions follow SOLID principles
- ✅ Terminal state tracking on all endpoints
- ✅ Threshold-based updates (not polling)
- ✅ All legacy files removed

### Performance Improvements
- ✅ 90%+ reduction in unnecessary SSE traffic
- ✅ <100ms latency for status updates
- ✅ Graceful handling of 100+ concurrent connections
- ✅ Proper memory cleanup on disconnect

### Code Quality
- ✅ 100% DRY compliance
- ✅ SOLID principles throughout
- ✅ Comprehensive error handling
- ✅ Type-safe implementations
- ✅ Clear documentation

## Timeline

- **Phase 1**: Backend Base Abstraction - 30 min
- **Phase 2**: Refactor Health SSE - 20 min
- **Phase 3**: Refactor Performance SSE - 20 min
- **Phase 4**: Frontend Base Client - 30 min
- **Phase 5**: Refactor Frontend Clients - 30 min
- **Phase 6**: Cleanup Legacy Code - 15 min
- **Phase 7**: Update Documentation - 15 min
- **Phase 8**: End-to-End Testing - 30 min

**Total Estimated Time**: 3 hours (190 minutes)

## Risk Mitigation

### Backward Compatibility
- **Not a concern** - User confirmed no backward compatibility needed
- Deploy all changes at once to avoid partial migrations

### Testing Strategy
- Test each phase independently before moving to next
- Keep Docker logs open to monitor Redis pub/sub
- Use browser DevTools to verify SSE connection behavior

### Rollback Plan
- Git commit after each phase
- Keep old files until all tests pass
- Use feature flags if deploying to production

## Next Steps

1. **Get User Approval** on this plan
2. **Start Phase 1**: Create backend base abstraction
3. **Iterate through phases** 2-8 systematically
4. **Mark todos complete** as each phase finishes
5. **Update CLAUDE.md** with new SSE standards

---

**Created**: 2025-10-09
**Status**: Awaiting approval
**Estimated Completion**: 3 hours
**Expected Impact**: -908 lines, +unified architecture, +90% efficiency
