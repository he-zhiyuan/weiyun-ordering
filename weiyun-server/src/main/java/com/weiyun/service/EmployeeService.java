package com.weiyun.service;

import com.weiyun.dto.EmployeeDTO;
import com.weiyun.dto.EmployeeLoginDTO;
import com.weiyun.dto.EmployeePageQueryDTO;
import com.weiyun.entity.Employee;
import com.weiyun.result.PageResult;

public interface EmployeeService {

    /**
     * 员工登录
     *
     * @param employeeLoginDTO
     * @return
     */
    Employee login(EmployeeLoginDTO employeeLoginDTO);

    /**
     * 新增员工
     *
     * @param employeeDTO
     */
    void save(EmployeeDTO employeeDTO);

    /**
     * 分页查询
     *
     * @param employeePageQueryDTO
     * @return
     */
    PageResult pageQuery(EmployeePageQueryDTO employeePageQueryDTO);

    /**
     * 启用或禁用员工
     *
     * @param status
     * @param id
     */
    void startOrStop(Integer status, Long id);

    /**
     * 根据id查询员工信息
     *
     * @param id
     * @return
     */
    Employee getById(Long id);

    /**
     * 更新员工信息
     *
     * @param employeeDTO
     */
    void update(EmployeeDTO employeeDTO);
}