package ar.edu.coderhouse.flink.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;

@JsonIgnoreProperties(ignoreUnknown = true)
public class PageViewEvent implements Serializable {
    private static final long serialVersionUID = 1L;

    @JsonProperty("event_id")
    private String eventId;

    @JsonProperty("event_type")
    private String eventType;

    @JsonProperty("user_id")
    private String userId;

    private long sequence;

    @JsonProperty("created_at")
    private Instant createdAt;

    public PageViewEvent() {
    }

    public PageViewEvent(String eventId, String eventType, String userId, long sequence, Instant createdAt) {
        this.eventId = eventId;
        this.eventType = eventType;
        this.userId = userId;
        this.sequence = sequence;
        this.createdAt = createdAt;
    }

    public void validate() {
        if (isBlank(eventId) || isBlank(eventType) || isBlank(userId) || createdAt == null) {
            throw new IllegalArgumentException("El evento requiere event_id, event_type, user_id y created_at");
        }
        if (sequence < 1) {
            throw new IllegalArgumentException("sequence debe ser mayor que cero");
        }
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    public long eventTimestampMillis() {
        return createdAt.toEpochMilli();
    }

    public String metricKey() {
        return userId + "|" + eventType;
    }

    public String getEventId() {
        return eventId;
    }

    public void setEventId(String eventId) {
        this.eventId = eventId;
    }

    public String getEventType() {
        return eventType;
    }

    public void setEventType(String eventType) {
        this.eventType = eventType;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public long getSequence() {
        return sequence;
    }

    public void setSequence(long sequence) {
        this.sequence = sequence;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof PageViewEvent)) {
            return false;
        }
        PageViewEvent that = (PageViewEvent) other;
        return sequence == that.sequence
                && Objects.equals(eventId, that.eventId)
                && Objects.equals(eventType, that.eventType)
                && Objects.equals(userId, that.userId)
                && Objects.equals(createdAt, that.createdAt);
    }

    @Override
    public int hashCode() {
        return Objects.hash(eventId, eventType, userId, sequence, createdAt);
    }
}
