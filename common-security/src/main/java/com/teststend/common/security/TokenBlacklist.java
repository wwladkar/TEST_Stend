package com.teststend.common.security;

import org.springframework.stereotype.Component;

import java.util.concurrent.ConcurrentHashMap;

/**
 * In-memory JWT blacklist for token invalidation.
 * Tokens are added when a user is blocked or their role is changed.
 * Entries expire automatically when the token's own expiration passes.
 */
@Component
public class TokenBlacklist {

    private final ConcurrentHashMap<String, Long> blacklisted = new ConcurrentHashMap<>();

    /**
     * Add a token to the blacklist.
     *
     * @param token       the raw JWT string
     * @param expirationMs the token's expiration timestamp in millis
     */
    public void add(String token, long expirationMs) {
        blacklisted.put(token, expirationMs);
    }

    /**
     * Check if a token is blacklisted.
     * Automatically cleans up expired entries.
     */
    public boolean isBlacklisted(String token) {
        Long expiration = blacklisted.get(token);
        if (expiration == null) {
            return false;
        }
        if (System.currentTimeMillis() > expiration) {
            blacklisted.remove(token, expiration);
            return false;
        }
        return true;
    }

    /**
     * Remove all expired entries. Call periodically or on demand.
     */
    public void cleanup() {
        long now = System.currentTimeMillis();
        blacklisted.entrySet().removeIf(e -> now > e.getValue());
    }
}
