package com.project.weddy.common.util;

import java.security.SecureRandom;

/**
 * 엔티티 PK(oid) 생성 유틸리티.
 * auto-increment 대신 서버에서 14자리 숫자 문자열을 직접 생성한다.
 * SecureRandom을 사용하여 예측 불가능한 값을 보장한다.
 */
public final class OidGenerator {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final int OID_LENGTH = 14;

    // 유틸리티 클래스 — 인스턴스화 방지
    private OidGenerator() {
        throw new UnsupportedOperationException("Utility class");
    }

    /**
     * 14자리 숫자 문자열 OID를 생성한다.
     * 첫 자리가 0이 되지 않도록 1~9 범위에서 첫 자리를 별도 생성한다.
     *
     * @return 예: "37291048523611"
     */
    public static String generate() {
        StringBuilder sb = new StringBuilder(OID_LENGTH);

        // 첫 자리: 1~9 (선행 0 방지)
        // nextInt(9) → 0~8, '1'+0~8 → '1'~'9'
        sb.append((char) ('0' + 1 + SECURE_RANDOM.nextInt(9)));

        // 나머지 13자리: 0~9
        // nextInt(10) → 0~9, '0'+0~9 → '0'~'9'
        for (int i = 1; i < OID_LENGTH; i++) {
            sb.append((char) ('0' + SECURE_RANDOM.nextInt(10)));
        }

        return sb.toString();
    }
}
