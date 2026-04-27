package com.teststend.coreservice.service;

import com.teststend.coreservice.dto.TaskDto;
import com.teststend.coreservice.dto.TaskRequest;
import com.teststend.coreservice.entity.Task;
import com.teststend.coreservice.entity.TaskPriority;
import com.teststend.coreservice.entity.TaskStatus;
import com.teststend.coreservice.repository.TaskRepository;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class TaskService {

    private static final String TASK_NOT_FOUND = "Задача не найдена";
    private static final String ACCESS_DENIED = "Нет доступа к этой задаче";

    private final TaskRepository taskRepository;

    public TaskService(TaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }

    public TaskDto create(@Valid TaskRequest request) {
        Task task = new Task(
                request.title(),
                request.description(),
                request.status() != null ? request.status() : TaskStatus.NEW,
                request.priority() != null ? request.priority() : TaskPriority.MEDIUM,
                currentUser()
        );
        return toDto(taskRepository.save(task));
    }

    public Page<TaskDto> list(Pageable pageable) {
        return taskRepository.findByCreatedBy(currentUser(), pageable)
                .map(this::toDto);
    }

    public TaskDto get(Long id) {
        Task task = findTaskAndCheckOwner(id);
        return toDto(task);
    }

    public TaskDto update(Long id, @Valid TaskRequest request) {
        Task task = findTaskAndCheckOwner(id);
        task.setTitle(request.title());
        task.setDescription(request.description());
        if (request.status() != null) task.setStatus(request.status());
        if (request.priority() != null) task.setPriority(request.priority());
        return toDto(taskRepository.save(task));
    }

    public void delete(Long id) {
        Task task = findTaskAndCheckOwner(id);
        taskRepository.delete(task);
    }

    private Task findTaskAndCheckOwner(Long id) {
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, TASK_NOT_FOUND));
        if (!task.getCreatedBy().equals(currentUser())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, ACCESS_DENIED);
        }
        return task;
    }

    private String currentUser() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }

    private TaskDto toDto(Task t) {
        return new TaskDto(t.getId(), t.getTitle(), t.getDescription(), t.getStatus(), t.getPriority(), t.getCreatedBy());
    }
}
