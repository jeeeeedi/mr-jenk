package ax.gritlab.buy_01.user.service;

import ax.gritlab.buy_01.user.model.Role;
import ax.gritlab.buy_01.user.model.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.test.util.ReflectionTestUtils;

import java.security.Key;
import java.util.Collection;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("JwtService Unit Tests")
public class JwtServiceTest {

    @Spy
    private JwtService jwtService;

    private UserDetails testUserDetails;
    private String secretKey;

    @BeforeEach
    void setUp() {
        // Generate a proper secret key for testing
        secretKey = "dGhpc2lzYXZlcnlsb25nYmFzZTY0ZW5jb2RlZHNlY3JldGtleWZvcnRlc3Rpbmdqd3R0b2tlbnN";
        ReflectionTestUtils.setField(jwtService, "secretKey", secretKey);

        User user = new User();
        user.setId("testUser123");
        user.setEmail("test@example.com");
        user.setPassword("hashedPassword");
        user.setRole(ax.gritlab.buy_01.user.model.Role.SELLER);

        testUserDetails = user;
    }

    @Test
    @DisplayName("Should generate valid JWT token")
    void testGenerateToken() {
        // Act
        String token = jwtService.generateToken(testUserDetails);

        // Assert
        assertNotNull(token);
        assertFalse(token.isEmpty());
        assertTrue(token.contains("."));
    }

    @Test
    @DisplayName("Should extract username from token")
    void testExtractUsername() {
        // Arrange
        String token = jwtService.generateToken(testUserDetails);

        // Act
        String username = jwtService.extractUsername(token);

        // Assert
        assertNotNull(username);
        assertEquals(testUserDetails.getUsername(), username);
    }

    @Test
    @DisplayName("Should generate token with extra claims")
    void testGenerateTokenWithExtraClaims() {
        // Arrange
        Map<String, Object> extraClaims = new HashMap<>();
        extraClaims.put("customClaim", "customValue");

        // Act
        String token = jwtService.generateToken(extraClaims, testUserDetails);

        // Assert
        assertNotNull(token);
        String username = jwtService.extractUsername(token);
        assertEquals(testUserDetails.getUsername(), username);
    }

    @Test
    @DisplayName("Should validate token with correct UserDetails")
    void testIsTokenValid() {
        // Arrange
        String token = jwtService.generateToken(testUserDetails);

        // Act
        boolean isValid = jwtService.isTokenValid(token, testUserDetails);

        // Assert
        assertTrue(isValid);
    }

    @Test
    @DisplayName("Should reject token with incorrect UserDetails")
    void testIsTokenInvalidWithDifferentUser() {
        // Arrange
        String token = jwtService.generateToken(testUserDetails);
        
        User differentUser = new User();
        differentUser.setEmail("different@example.com");
        UserDetails differentUserDetails = differentUser;

        // Act
        boolean isValid = jwtService.isTokenValid(token, differentUserDetails);

        // Assert
        assertFalse(isValid);
    }

    @Test
    @DisplayName("Should reject expired token")
    void testIsExpiredToken() {
        // Arrange - Create an expired token
        Map<String, Object> claims = new HashMap<>();
        String expiredToken = Jwts
                .builder()
                .setClaims(claims)
                .setSubject(testUserDetails.getUsername())
                .setIssuedAt(new Date(System.currentTimeMillis() - 1000 * 60 * 60 * 25))
                .setExpiration(new Date(System.currentTimeMillis() - 1000 * 60)) // Expired 1 minute ago
                .signWith(getSignInKey(secretKey), SignatureAlgorithm.HS256)
                .compact();

        // Act & Assert - The token is expired, so trying to validate it should throw an exception
        // or return false, depending on the implementation
        assertThrows(Exception.class, () -> jwtService.isTokenValid(expiredToken, testUserDetails));
    }

    @Test
    @DisplayName("Should extract custom claim from token")
    void testExtractCustomClaim() {
        // Arrange
        Map<String, Object> extraClaims = new HashMap<>();
        extraClaims.put("customKey", "customValue");
        String token = jwtService.generateToken(extraClaims, testUserDetails);

        // Act
        String customValue = jwtService.extractClaim(token, claims -> claims.get("customKey", String.class));

        // Assert
        assertEquals("customValue", customValue);
    }

    private Key getSignInKey(String secretKey) {
        byte[] keyBytes = Decoders.BASE64.decode(secretKey);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
