package com.project.weddy.domain.user.dto.response;

import com.project.weddy.domain.user.entity.User;
import lombok.Builder;
import lombok.Getter;

/**
 * 사용자 정보 응답 DTO.
 * 비밀번호 등 민감 정보를 제외한 사용자 데이터를 클라이언트에 전달한다.
 */
@Getter
@Builder
public class UserResponse {

    private String userOid;
    private String userId;
    private String name;
    private String handPhone;
    private String email;
    private String role;
    private String inviteCode;

    /**
     * {@link User} 엔티티로부터 응답 DTO를 생성하는 정적 팩토리 메서드.
     *
     * @param user 사용자 엔티티
     * @return UserResponse 인스턴스
     */
    public static UserResponse from(User user) {
        return UserResponse.builder()
                .userOid(user.getOid())
                .userId(user.getUserId())
                .name(user.getName())
                .handPhone(user.getHandPhone())
                .email(user.getEmail())
                .role(user.getRole() != null ? user.getRole().name() : null)
                .inviteCode(user.getInviteCode())
                .build();
    }
}
