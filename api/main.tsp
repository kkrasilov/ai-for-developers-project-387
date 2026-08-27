import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi3";

using TypeSpec.Http;
using TypeSpec.Rest;

@service(#{ title: "Call Booking API" })
@server("http://localhost:3000")
namespace CallBooking;

// ============================================================
// Models
// ============================================================

model EventType {
  // id генерируется автоматически на сервере (БД), клиент его не передает
  id: int64;
  name: string;
  description: string;

  @minValue(1)
  duration_minutes: int32;
}

model CreateEventTypeRequest {
  name: string;
  description: string;

  @minValue(1)
  duration_minutes: int32;
}

model Booking {
  id: int64;
  event_type_id: int64;
  event_type_name: string;

  guest_name: string;
  guest_email: string;

  start_at: utcDateTime;
  end_at: utcDateTime;
}

model CreateBookingRequest {
  event_type_id: int64;
  start_at: utcDateTime;

  guest_name: string;
  guest_email: string;
}

model TimeSlot {
  start_at: utcDateTime;
  end_at: utcDateTime;
}

// ============================================================
// Errors
// ============================================================

@error
model ErrorResponse {
  code: string;
  message: string;
}

@error
model NotFoundErrorResponse {
  @statusCode statusCode: 404;
  code: string;
  message: string;
}

// Конфликт: слот уже занят другим бронированием
@error
model BookingConflictErrorResponse {
  @statusCode statusCode: 409;
  code: string;
  message: string;
}

// Слот не входит в доступное окно (ближайшие 14 дней) или уже в прошлом
@error
model InvalidSlotErrorResponse {
  @statusCode statusCode: 422;
  code: string;
  message: string;
}

// ============================================================
// Owner API
// ============================================================

@route("/owner")
interface OwnerApi {

  // Получить все типы событий
  @get
  @route("/event_types")
  listEventTypes(): EventType[];

  // Создать тип события
  @post
  @route("/event_types")
  createEventType(
    @body body: CreateEventTypeRequest
  ): EventType;

  // Получить все предстоящие бронирования
  // независимо от типа события
  @get
  @route("/bookings")
  listUpcomingBookings(): Booking[];
}

// ============================================================
// Guest API
// ============================================================

@route("/event_types")
interface GuestEventTypeApi {

  // Получить доступные типы бронирования
  @get
  listEventTypes(): EventType[];

  // Получить один тип события по id
  // (используется на странице выбора слота)
  @get
  @route("/{event_type_id}")
  getEventType(
    @path event_type_id: int64
  ): EventType | NotFoundErrorResponse;

  // Получить свободные слоты выбранного типа события
  // только в пределах ближайших 14 дней
  @get
  @route("/{event_type_id}/slots")
  listAvailableSlots(
    @path event_type_id: int64
  ): TimeSlot[] | NotFoundErrorResponse;
}

// ============================================================
// Guest Booking API
// ============================================================

@route("/bookings")
interface GuestBookingApi {

  // Создать бронирование
  // 409 — слот уже занят другой записью
  // 422 — слот вне окна доступности (ближайшие 14 дней) или в прошлом
  // 404 — указан несуществующий тип события
  @post
  createBooking(
    @body body: CreateBookingRequest
  ): Booking | BookingConflictErrorResponse | InvalidSlotErrorResponse | NotFoundErrorResponse;
}
