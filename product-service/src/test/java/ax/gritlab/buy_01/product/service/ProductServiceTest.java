package ax.gritlab.buy_01.product.service;

import ax.gritlab.buy_01.product.dto.ProductRequest;
import ax.gritlab.buy_01.product.dto.ProductResponse;
import ax.gritlab.buy_01.product.exception.ResourceNotFoundException;
import ax.gritlab.buy_01.product.exception.UnauthorizedException;
import ax.gritlab.buy_01.product.model.Product;
import ax.gritlab.buy_01.product.repository.ProductRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("ProductService Unit Tests")
public class ProductServiceTest {

    @Mock
    private ProductRepository productRepository;

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private KafkaTemplate<String, String> kafkaTemplate;

    @Mock
    private ObjectMapper objectMapper;

    @InjectMocks
    private ProductService productService;

    private Product testProduct;
    private ProductRequest testProductRequest;

    @BeforeEach
    void setUp() {
        testProduct = new Product();
        testProduct.setId("prod123");
        testProduct.setName("Test Product");
        testProduct.setDescription("A test product");
        testProduct.setPrice(99.99);
        testProduct.setQuantity(10);
        testProduct.setUserId("user123");
        testProduct.setCreatedAt(LocalDateTime.now());
        testProduct.setUpdatedAt(LocalDateTime.now());

        testProductRequest = new ProductRequest();
        testProductRequest.setName("Updated Product");
        testProductRequest.setDescription("Updated description");
        testProductRequest.setPrice(149.99);
        testProductRequest.setQuantity(20);
    }

    @Test
    @DisplayName("Should retrieve all products")
    void testGetAllProducts() {
        // Arrange
        List<Product> products = new ArrayList<>();
        products.add(testProduct);
        when(productRepository.findAll()).thenReturn(products);

        // Act
        List<ProductResponse> responses = productService.getAllProducts();

        // Assert
        assertNotNull(responses);
        assertEquals(1, responses.size());
        verify(productRepository, times(1)).findAll();
    }

    @Test
    @DisplayName("Should retrieve product by ID successfully")
    void testGetProductById() {
        // Arrange
        when(productRepository.findById("prod123")).thenReturn(Optional.of(testProduct));

        // Act
        ProductResponse response = productService.getProductById("prod123");

        // Assert
        assertNotNull(response);
        assertEquals("prod123", response.getId());
        assertEquals("Test Product", response.getName());
        verify(productRepository, times(1)).findById("prod123");
    }

    @Test
    @DisplayName("Should throw exception when product not found")
    void testGetProductByIdNotFound() {
        // Arrange
        when(productRepository.findById("nonexistent")).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(ResourceNotFoundException.class, () -> productService.getProductById("nonexistent"));
        verify(productRepository, times(1)).findById("nonexistent");
    }

    @Test
    @DisplayName("Should create product successfully")
    void testCreateProduct() {
        // Arrange
        when(productRepository.save(any(Product.class))).thenReturn(testProduct);

        // Act
        ProductResponse response = productService.createProduct(testProductRequest, "user123");

        // Assert
        assertNotNull(response);
        assertEquals("Test Product", response.getName());
        verify(productRepository, times(1)).save(any(Product.class));
    }

    @Test
    @DisplayName("Should update product successfully")
    void testUpdateProduct() {
        // Arrange
        when(productRepository.findById("prod123")).thenReturn(Optional.of(testProduct));
        when(productRepository.save(any(Product.class))).thenReturn(testProduct);

        // Act
        ProductResponse response = productService.updateProduct("prod123", testProductRequest, "user123");

        // Assert
        assertNotNull(response);
        verify(productRepository, times(1)).findById("prod123");
        verify(productRepository, times(1)).save(any(Product.class));
    }

    @Test
    @DisplayName("Should throw exception when updating product with unauthorized user")
    void testUpdateProductUnauthorized() {
        // Arrange
        when(productRepository.findById("prod123")).thenReturn(Optional.of(testProduct));

        // Act & Assert
        assertThrows(UnauthorizedException.class, () -> productService.updateProduct("prod123", testProductRequest, "differentUser"));
        verify(productRepository, times(1)).findById("prod123");
        verify(productRepository, never()).save(any(Product.class));
    }

    @Test
    @DisplayName("Should delete product successfully")
    void testDeleteProduct() {
        // Arrange
        testProduct.setMediaIds(new ArrayList<>());
        when(productRepository.findById("prod123")).thenReturn(Optional.of(testProduct));

        // Act
        productService.deleteProduct("prod123", "user123");

        // Assert
        verify(productRepository, times(1)).findById("prod123");
        verify(productRepository, times(1)).delete(testProduct);
    }

    @Test
    @DisplayName("Should throw exception when deleting product with unauthorized user")
    void testDeleteProductUnauthorized() {
        // Arrange
        when(productRepository.findById("prod123")).thenReturn(Optional.of(testProduct));

        // Act & Assert
        assertThrows(UnauthorizedException.class, () -> productService.deleteProduct("prod123", "differentUser"));
        verify(productRepository, times(1)).findById("prod123");
        verify(productRepository, never()).delete(any(Product.class));
    }

    @Test
    @DisplayName("Should delete all products for a user")
    void testDeleteProductsByUserId() {
        // Arrange
        List<Product> userProducts = new ArrayList<>();
        userProducts.add(testProduct);
        when(productRepository.findByUserId("user123")).thenReturn(userProducts);

        // Act
        productService.deleteProductsByUserId("user123");

        // Assert
        verify(productRepository, times(1)).findByUserId("user123");
        verify(productRepository, times(1)).delete(testProduct);
    }
}
