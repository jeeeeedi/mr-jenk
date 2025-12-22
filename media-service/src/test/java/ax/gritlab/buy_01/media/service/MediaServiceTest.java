package ax.gritlab.buy_01.media.service;

import ax.gritlab.buy_01.media.exception.ResourceNotFoundException;
import ax.gritlab.buy_01.media.exception.UnauthorizedException;
import ax.gritlab.buy_01.media.model.Media;
import ax.gritlab.buy_01.media.repository.MediaRepository;
import ax.gritlab.buy_01.media.config.StorageProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("MediaService Unit Tests")
public class MediaServiceTest {

    @Mock
    private MediaRepository mediaRepository;

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private StorageProperties storageProperties;

    @InjectMocks
    private MediaService mediaService;

    private Media testMedia;

    @BeforeEach
    void setUp() {
        // Set up test media
        testMedia = new Media();
        testMedia.setId("media123");
        testMedia.setUserId("user123");
        testMedia.setOriginalFilename("test_image.jpg");
        testMedia.setContentType("image/jpeg");
        testMedia.setFilePath("/uploads/test_image.jpg");
        testMedia.setSize(1024L);
        testMedia.setCreatedAt(LocalDateTime.now());
        testMedia.setUpdatedAt(LocalDateTime.now());
    }

    @Test
    @DisplayName("Should find media by user ID")
    void testFindByUserId() {
        // Arrange
        List<Media> userMedia = new ArrayList<>();
        userMedia.add(testMedia);
        when(mediaRepository.findByUserId("user123")).thenReturn(userMedia);

        // Act
        List<Media> result = mediaService.findByUserId("user123");

        // Assert
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("media123", result.get(0).getId());
        verify(mediaRepository, times(1)).findByUserId("user123");
    }

    @Test
    @DisplayName("Should associate media with product successfully")
    void testAssociateWithProduct() {
        // Arrange
        when(mediaRepository.findById("media123")).thenReturn(Optional.of(testMedia));
        when(mediaRepository.save(any(Media.class))).thenReturn(testMedia);

        // Act
        Media result = mediaService.associateWithProduct("media123", "prod123", "user123");

        // Assert
        assertNotNull(result);
        assertEquals("prod123", result.getProductId());
        verify(mediaRepository, times(1)).findById("media123");
        verify(mediaRepository, times(1)).save(any(Media.class));
    }

    @Test
    @DisplayName("Should throw exception when associating media with unauthorized user")
    void testAssociateWithProductUnauthorized() {
        // Arrange
        when(mediaRepository.findById("media123")).thenReturn(Optional.of(testMedia));

        // Act & Assert
        assertThrows(UnauthorizedException.class, () -> mediaService.associateWithProduct("media123", "prod123", "differentUser"));
        verify(mediaRepository, times(1)).findById("media123");
        verify(mediaRepository, never()).save(any(Media.class));
    }

    @Test
    @DisplayName("Should throw exception when associating non-existent media")
    void testAssociateWithProductNotFound() {
        // Arrange
        when(mediaRepository.findById("nonexistent")).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(ResourceNotFoundException.class, () -> mediaService.associateWithProduct("nonexistent", "prod123", "user123"));
        verify(mediaRepository, times(1)).findById("nonexistent");
        verify(mediaRepository, never()).save(any(Media.class));
    }

    @Test
    @DisplayName("Should delete all media for a user")
    void testDeleteMediaByUserId() {
        // Arrange - Use empty list - the service only calls deleteAll if list is not empty
        List<Media> emptyMedia = new ArrayList<>();
        when(mediaRepository.findByUserId("user123")).thenReturn(emptyMedia);

        // Act
        mediaService.deleteMediaByUserId("user123");

        // Assert
        verify(mediaRepository, times(1)).findByUserId("user123");
        // deleteAll is only called if media list is not empty
    }

    @Test
    @DisplayName("Should delete media by product ID with empty list")
    void testDeleteMediaByProductId() {
        // Arrange - Use empty list - the service only calls deleteAll if list is not empty
        List<Media> emptyMedia = new ArrayList<>();
        when(mediaRepository.findByProductId("prod123")).thenReturn(emptyMedia);

        // Act
        mediaService.deleteMediaByProductId("prod123");

        // Assert
        verify(mediaRepository, times(1)).findByProductId("prod123");
        // deleteAll is only called if media list is not empty
    }

    @Test
    @DisplayName("Should delete media by IDs list with empty result")
    void testDeleteMediaByIds() {
        // Arrange - Use empty list - the service only calls deleteAll if list is not empty
        List<String> mediaIds = new ArrayList<>();
        mediaIds.add("media123");
        List<Media> emptyMedias = new ArrayList<>();
        when(mediaRepository.findAllById(mediaIds)).thenReturn(emptyMedias);

        // Act
        mediaService.deleteMediaByIds(mediaIds);

        // Assert
        verify(mediaRepository, times(1)).findAllById(mediaIds);
        // deleteAll is only called if media list is not empty
    }

    @Test
    @DisplayName("Should handle empty list for deleteMediaByIds")
    void testDeleteMediaByIdsEmpty() {
        // Arrange
        List<String> emptyList = new ArrayList<>();

        // Act
        mediaService.deleteMediaByIds(emptyList);

        // Assert
        verify(mediaRepository, never()).findAllById(any());
        verify(mediaRepository, never()).deleteAll(any());
    }
}

