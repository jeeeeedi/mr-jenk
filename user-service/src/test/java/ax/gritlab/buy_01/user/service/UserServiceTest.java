package ax.gritlab.buy_01.user.service;

import ax.gritlab.buy_01.user.dto.UpdateProfileRequest;
import ax.gritlab.buy_01.user.dto.UserProfileResponse;
import ax.gritlab.buy_01.user.model.Role;
import ax.gritlab.buy_01.user.model.User;
import ax.gritlab.buy_01.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("UserService Unit Tests")
public class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private KafkaTemplate<String, String> kafkaTemplate;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId("user123");
        testUser.setName("John Doe");
        testUser.setEmail("john@example.com");
        testUser.setRole(ax.gritlab.buy_01.user.model.Role.SELLER);
        testUser.setAvatar("avatar.jpg");
        testUser.setPassword("hashedPassword");
    }

    @Test
    @DisplayName("Should retrieve user profile successfully")
    void testGetProfile() {
        // Arrange
        // Act
        UserProfileResponse response = userService.getProfile(testUser);

        // Assert
        assertNotNull(response);
        assertEquals("user123", response.getId());
        assertEquals("John Doe", response.getName());
        assertEquals("john@example.com", response.getEmail());
        assertEquals(Role.SELLER, response.getRole());
        assertEquals("avatar.jpg", response.getAvatar());
    }

    @Test
    @DisplayName("Should retrieve user by ID successfully")
    void testGetUserById() {
        // Arrange
        when(userRepository.findById("user123")).thenReturn(Optional.of(testUser));

        // Act
        UserProfileResponse response = userService.getUserById("user123");

        // Assert
        assertNotNull(response);
        assertEquals("user123", response.getId());
        assertEquals("John Doe", response.getName());
        verify(userRepository, times(1)).findById("user123");
    }

    @Test
    @DisplayName("Should throw exception when user not found")
    void testGetUserByIdNotFound() {
        // Arrange
        when(userRepository.findById("nonexistent")).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(RuntimeException.class, () -> userService.getUserById("nonexistent"));
        verify(userRepository, times(1)).findById("nonexistent");
    }

    @Test
    @DisplayName("Should update user profile successfully")
    void testUpdateProfile() {
        // Arrange
        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setName("Jane Doe");
        request.setAvatar("new_avatar.jpg");

        when(userRepository.save(any(User.class))).thenReturn(testUser);

        // Act
        UserProfileResponse response = userService.updateProfile(testUser, request);

        // Assert
        assertNotNull(response);
        verify(userRepository, times(1)).save(any(User.class));
    }

    @Test
    @DisplayName("Should throw exception when current password is missing for password change")
    void testUpdateProfileMissingCurrentPassword() {
        // Arrange
        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setNewPassword("newPassword123");
        request.setPassword(null);

        // Act & Assert
        assertThrows(IllegalArgumentException.class, () -> userService.updateProfile(testUser, request));
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    @DisplayName("Should throw exception when current password is incorrect")
    void testUpdateProfileIncorrectPassword() {
        // Arrange
        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setPassword("wrongPassword");
        request.setNewPassword("newPassword123");

        when(passwordEncoder.matches("wrongPassword", "hashedPassword")).thenReturn(false);

        // Act & Assert
        assertThrows(RuntimeException.class, () -> userService.updateProfile(testUser, request));
        verify(userRepository, never()).save(any(User.class));
    }
}
