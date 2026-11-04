package ar.edu.coderhouse.flink.model;

import java.io.Serializable;

public class EnrichedEvent implements Serializable {
    private static final long serialVersionUID = 1L;

    private PageViewEvent event;
    private long userRunningCount;

    public EnrichedEvent() {
    }

    public EnrichedEvent(PageViewEvent event, long userRunningCount) {
        this.event = event;
        this.userRunningCount = userRunningCount;
    }

    public PageViewEvent getEvent() {
        return event;
    }

    public void setEvent(PageViewEvent event) {
        this.event = event;
    }

    public long getUserRunningCount() {
        return userRunningCount;
    }

    public void setUserRunningCount(long userRunningCount) {
        this.userRunningCount = userRunningCount;
    }
}
