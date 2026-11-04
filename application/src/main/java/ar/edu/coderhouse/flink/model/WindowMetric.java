package ar.edu.coderhouse.flink.model;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.io.Serializable;
import java.time.Instant;

public class WindowMetric implements Serializable {
    private static final long serialVersionUID = 1L;

    @JsonProperty("metric_type")
    private String metricType = "user_event_count";

    @JsonProperty("user_id")
    private String userId;

    @JsonProperty("event_type")
    private String eventType;

    @JsonProperty("window_start")
    private Instant windowStart;

    @JsonProperty("window_end")
    private Instant windowEnd;

    @JsonProperty("event_count")
    private long eventCount;

    @JsonProperty("last_sequence")
    private long lastSequence;

    @JsonProperty("user_running_count")
    private long userRunningCount;

    public WindowMetric() {
    }

    public WindowMetric(
            String userId,
            String eventType,
            Instant windowStart,
            Instant windowEnd,
            long eventCount,
            long lastSequence,
            long userRunningCount) {
        this.userId = userId;
        this.eventType = eventType;
        this.windowStart = windowStart;
        this.windowEnd = windowEnd;
        this.eventCount = eventCount;
        this.lastSequence = lastSequence;
        this.userRunningCount = userRunningCount;
    }

    public String getMetricType() {
        return metricType;
    }

    public void setMetricType(String metricType) {
        this.metricType = metricType;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getEventType() {
        return eventType;
    }

    public void setEventType(String eventType) {
        this.eventType = eventType;
    }

    public Instant getWindowStart() {
        return windowStart;
    }

    public void setWindowStart(Instant windowStart) {
        this.windowStart = windowStart;
    }

    public Instant getWindowEnd() {
        return windowEnd;
    }

    public void setWindowEnd(Instant windowEnd) {
        this.windowEnd = windowEnd;
    }

    public long getEventCount() {
        return eventCount;
    }

    public void setEventCount(long eventCount) {
        this.eventCount = eventCount;
    }

    public long getLastSequence() {
        return lastSequence;
    }

    public void setLastSequence(long lastSequence) {
        this.lastSequence = lastSequence;
    }

    public long getUserRunningCount() {
        return userRunningCount;
    }

    public void setUserRunningCount(long userRunningCount) {
        this.userRunningCount = userRunningCount;
    }
}
