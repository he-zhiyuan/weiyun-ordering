package com.sky.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import java.nio.charset.StandardCharsets;

@Configuration
@Slf4j
public class RedisConfiguration {

    @Bean
    public RedisTemplate<String, String> redisTemplate(RedisConnectionFactory redisConnectionFactory) {
        log.info("开始创建redis模板对象...");
        RedisTemplate<String, String> redisTemplate = new RedisTemplate<>();
        StringRedisSerializer utf8Serializer = new StringRedisSerializer(StandardCharsets.UTF_8);
        redisTemplate.setConnectionFactory(redisConnectionFactory);
        redisTemplate.setKeySerializer(utf8Serializer);
        redisTemplate.setValueSerializer(utf8Serializer);
        redisTemplate.setHashKeySerializer(utf8Serializer);
        redisTemplate.setHashValueSerializer(utf8Serializer);
        redisTemplate.afterPropertiesSet();
        return redisTemplate;
    }
}