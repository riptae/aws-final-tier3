package com.example.todo;

import java.util.Map;
import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiErrors {
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String,String>> validation(MethodArgumentNotValidException e) {
        return ResponseEntity.badRequest().body(Map.of("message", "title은 1~200자이며, 수정 시 completed가 필요합니다."));
    }
    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<Map<String,String>> database(DataAccessException e) {
        return ResponseEntity.status(503).body(Map.of("message", "Database unavailable"));
    }
}
