package com.sky.service;

import com.sky.dto.UserLoginDTO;
import com.sky.dto.WebUserLoginDTO;
import com.sky.entity.User;

public interface UserService {

    /**
     * 微信登录
     *
     * @param userLoginDTO
     * @return
     */
    User wxLogin(UserLoginDTO userLoginDTO);

    /**
     * Web端登录（演示用，免验证码，手机号直接登录/注册）
     *
     * @param webUserLoginDTO
     * @return
     */
    User webLogin(WebUserLoginDTO webUserLoginDTO);
}