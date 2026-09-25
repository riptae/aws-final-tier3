package com.example.todo;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import com.fasterxml.jackson.databind.ObjectMapper;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties={
    "spring.datasource.url=jdbc:h2:mem:todo;MODE=MySQL;DB_CLOSE_DELAY=-1",
    "spring.datasource.username=sa", "spring.datasource.password="})
@AutoConfigureMockMvc
class TodoApiTest {
    @Autowired MockMvc api;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate db;

    @Test void crudPersistsAndValidates() throws Exception {
        api.perform(get("/api/health")).andExpect(status().isOk()).andExpect(jsonPath("$.database").value("UP"));
        api.perform(post("/api/todos").contentType("application/json").content("{\"title\":\" \"}"))
            .andExpect(status().isBadRequest());
        var result=api.perform(post("/api/todos").contentType("application/json").content("{\"title\":\"테스트\"}"))
            .andExpect(status().isCreated()).andReturn();
        long id=json.readTree(result.getResponse().getContentAsString()).get("id").asLong();
        assertThat(db.queryForObject("SELECT title FROM todos WHERE id=?",String.class,id)).isEqualTo("테스트");
        api.perform(put("/api/todos/"+id).contentType("application/json").content("{\"title\":\"수정\",\"completed\":true}"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.completed").value(true));
        api.perform(get("/api/todos")).andExpect(status().isOk()).andExpect(jsonPath("$[0].title").value("수정"));
        api.perform(delete("/api/todos/"+id)).andExpect(status().isNoContent());
        api.perform(delete("/api/todos/"+id)).andExpect(status().isNotFound());
        api.perform(put("/api/todos/"+id).contentType("application/json").content("{\"title\":\"없음\",\"completed\":false}"))
            .andExpect(status().isNotFound());
    }
}
