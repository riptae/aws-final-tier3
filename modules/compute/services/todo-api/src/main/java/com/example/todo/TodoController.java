package com.example.todo;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.net.URI;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api")
public class TodoController {
    private final JdbcTemplate db;
    public TodoController(JdbcTemplate db) { this.db = db; }

    public record Todo(long id, String title, boolean completed, LocalDateTime createdAt) {}
    public record CreateTodo(@NotBlank @Size(max=200) String title) {}
    public record UpdateTodo(@NotBlank @Size(max=200) String title, @NotNull Boolean completed) {}

    // DB까지 정상이어야 배포 health check가 성공한다.
    @GetMapping("/health")
    public Map<String, String> health() {
        db.queryForObject("SELECT 1", Integer.class);
        return Map.of("status", "UP", "database", "UP");
    }

    @GetMapping("/todos")
    public List<Todo> list() {
        return db.query("SELECT id,title,completed,created_at FROM todos ORDER BY id DESC",
            (rs, row) -> new Todo(rs.getLong("id"), rs.getString("title"),
                rs.getBoolean("completed"), rs.getTimestamp("created_at").toLocalDateTime()));
    }

    @PostMapping("/todos")
    public ResponseEntity<Todo> create(@Valid @RequestBody CreateTodo input) {
        var key = new GeneratedKeyHolder();
        db.update(connection -> {
            var statement = connection.prepareStatement(
                "INSERT INTO todos(title,completed) VALUES (?,false)", new String[]{"id"});
            statement.setString(1, input.title().strip());
            return statement;
        }, key);
        long id = java.util.Objects.requireNonNull(key.getKey()).longValue();
        return ResponseEntity.created(URI.create("/api/todos/" + id)).body(find(id));
    }

    @PutMapping("/todos/{id}")
    public Todo update(@PathVariable long id, @Valid @RequestBody UpdateTodo input) {
        find(id);
        db.update("UPDATE todos SET title=?,completed=? WHERE id=?", input.title().strip(), input.completed(), id);
        return find(id);
    }

    @DeleteMapping("/todos/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable long id) {
        if (db.update("DELETE FROM todos WHERE id=?", id) == 0) throw missing();
    }

    private Todo find(long id) {
        var rows = db.query("SELECT id,title,completed,created_at FROM todos WHERE id=?",
            (rs, row) -> new Todo(rs.getLong("id"), rs.getString("title"),
                rs.getBoolean("completed"), rs.getTimestamp("created_at").toLocalDateTime()), id);
        if (rows.isEmpty()) throw missing();
        return rows.get(0);
    }
    private ResponseStatusException missing() {
        return new ResponseStatusException(HttpStatus.NOT_FOUND, "Todo not found");
    }
}
