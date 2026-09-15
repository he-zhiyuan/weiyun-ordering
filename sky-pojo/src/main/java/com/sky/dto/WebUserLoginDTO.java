package com.sky.dto;

import lombok.Data;

import java.io.Serializable;

/**
 * Web端用户登录（演示用，免验证码，手机号直接登录/注册）
 */
@Data
public class WebUserLoginDTO implements Serializable {

    private String phone;

    private String name;

}
