package com.teststend.coreservice.controller;

import com.teststend.coreservice.dto.TaskDto;
import com.teststend.coreservice.dto.TaskRequest;
import com.teststend.coreservice.entity.Task;
import com.teststend.coreservice.repository.TaskRepository;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/tasks")
public class TaskController {

    private static final String TASK_NOT_FOUND = "Задача не найдена";
    private static final String ACCESS_DENIED = "Нет доступа к этой задаче";

    private final TaskRepository taskRepository;

    public TaskController(TaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }

    private String currentUser() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TaskDto create(@Valid @RequestBody TaskRequest request) {
        Task task = new Task(
                request.title(),
                request.description(),
                request.status() != null ? request.status() : "NEW",
                request.priority() != null ? request.priority() : "MEDIUM",
                currentUser()
        );
        return toDto(taskRepository.save(task));
    }

    @GetMapping
    public Page<TaskDto> list(Pageable pageable) {
        return taskRepository.findByCreatedBy(currentUser(), pageable)
                .map(this::toDto);
    }

    @GetMapping("/{id}")
    public TaskDto get(@PathVariable Long id) {
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, TASK_NOT_FOUND));
        if (!task.getCreatedBy().equals(currentUser())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, ACCESS_DENIED);
        }
        return toDto(task);
    }

    @PutMapping("/{id}")
    public TaskDto update(@PathVariable Long id,
                          @Valid @RequestBody TaskRequest request) {
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, TASK_NOT_FOUND));
        if (!task.getCreatedBy().equals(currentUser())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, ACCESS_DENIED);
        }
        task.setTitle(request.title());
        task.setDescription(request.description());
        if (request.status() != null) task.setStatus(request.status());
        if (request.priority() != null) task.setPriority(request.priority());
        return toDto(taskRepository.save(task));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, TASK_NOT_FOUND));
        if (!task.getCreatedBy().equals(currentUser())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, ACCESS_DENIED);
        }
        taskRepository.delete(task);
    }

    private TaskDto toDto(Task t) {
        return new TaskDto(t.getId(), t.getTitle(), t.getDescription(), t.getStatus(), t.getPriority(), t.getCreatedBy());
    }
}
