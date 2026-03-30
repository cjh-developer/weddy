package com.project.weddy.domain.attachment.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 파일 업로드 설정 프로퍼티.
 * application.yml 의 {@code file.upload-dir} 을 바인딩한다.
 */
@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "file")
public class FileStorageProperties {
    private String uploadDir = "./uploads";
}
