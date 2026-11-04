package ar.edu.coderhouse.flink.serde;

import ar.edu.coderhouse.flink.model.WindowMetric;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.flink.api.common.functions.MapFunction;

public class MetricToJson implements MapFunction<WindowMetric, String> {
    private static final long serialVersionUID = 1L;
    private static final ObjectMapper MAPPER = new ObjectMapper().registerModule(new JavaTimeModule());

    @Override
    public String map(WindowMetric metric) throws Exception {
        return MAPPER.writeValueAsString(metric);
    }
}
