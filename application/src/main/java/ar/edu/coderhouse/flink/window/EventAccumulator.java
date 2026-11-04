package ar.edu.coderhouse.flink.window;

import java.io.Serializable;

public class EventAccumulator implements Serializable {
    private static final long serialVersionUID = 1L;

    private String userId;
    private String eventType;
    private long count;
    private long maxSequence;
    private long maxRunningCount;

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

    public long getCount() {
        return count;
    }

    public void setCount(long count) {
        this.count = count;
    }

    public long getMaxSequence() {
        return maxSequence;
    }

    public void setMaxSequence(long maxSequence) {
        this.maxSequence = maxSequence;
    }

    public long getMaxRunningCount() {
        return maxRunningCount;
    }

    public void setMaxRunningCount(long maxRunningCount) {
        this.maxRunningCount = maxRunningCount;
    }
}
