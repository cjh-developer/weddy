package com.project.weddy.domain.attachment.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * 업로드 디렉토리를 초기화하고 {@link Path} 빈을 등록한다.
 *
 * <p>애플리케이션 기동 시 {@code file.upload-dir} 경로가 존재하지 않으면 자동 생성한다.
 */
@Slf4j
@Configuration
@RequiredArgsConstructor
public class FileStorageConfig {

    private final FileStorageProperties properties;

    @Bean
    public Path uploadPath() throws IOException {
        Path path = Paths.get(properties.getUploadDir()).toAbsolutePath().normalize();
        Files.createDirectories(path);
        log.info("업로드 디렉토리: {}", path);
        return path;
    }
}
