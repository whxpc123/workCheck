# WorkCheck API 文档

## 概述
WorkCheck API 提供代码变更检查记录的管理功能，包括任务管理、检查项模板配置等功能。

**基础URL**: `http://localhost:8080/workcheck/api`

## API 端点

### 1. 加载任务列表
```http
GET /load?user={userName}&month={month}
```

**参数**:
- `userName` (string): 用户名
- `month` (string): 月份，格式为 YYYY-MM

**响应示例**:
```json
{
  "success": true,
  "tasks": [
    {
      "id": 1,
      "taskId": "S00001",
      "change": "修复登录bug",
      "risk": "高",
      "userName": "张三",
      "month": "2024-01",
      "files": [
        {
          "id": 1,
          "file": "/src/login.js",
          "test": "已完成"
        }
      ],
      "checks": [
        {
          "id": 1,
          "checkItem": "代码合并是否完成",
          "status": "完成",
          "sortOrder": 0
        }
      ]
    }
  ]
}
```

### 2. 保存任务列表
```http
POST /save?user={userName}&month={month}
```

**请求头**:
- `Content-Type: application/json`

**请求体**:
```json
[
  {
    "taskId": "S00001",
    "change": "修复登录bug",
    "risk": "高",
    "files": [
      {
        "file": "/src/login.js",
        "test": "已完成"
      }
    ],
    "checks": [
      {
        "checkItem": "代码合并是否完成",
        "status": "完成",
        "sortOrder": 0
      }
    ]
  }
]
```

**响应示例**:
```json
{
  "success": true,
  "tasks": [...],
  "message": "保存成功"
}
```

### 3. 获取检查项模板
```http
GET /check-template
```

**响应示例**:
```json
{
  "success": true,
  "checks": [
    "代码合并是否完成",
    "冲突是否确认",
    "核心逻辑单测覆盖",
    "高风险点复盘",
    "日志级别合理",
    "异常兜底处理",
    "paas参数核对",
    "cmc参数核对",
    "性能测试完成"
  ]
}
```

### 4. 获取所有用户列表
```http
GET /users
```

**响应示例**:
```json
{
  "success": true,
  "users": ["张三", "李四", "王五"]
}
```

### 5. 获取所有月份列表
```http
GET /months
```

**响应示例**:
```json
{
  "success": true,
  "months": ["2024-01", "2024-02", "2023-12"]
}
```

### 6. 初始化默认模板
```http
POST /init-template
```

**响应示例**:
```json
{
  "success": true,
  "message": "默认模板初始化成功"
}
```

### 7. 健康检查
```http
GET /health
```

**响应示例**:
```json
{
  "status": "OK",
  "message": "WorkCheck API is running",
  "timestamp": 1640995200000
}
```

## 错误响应格式
所有API在出错时都会返回以下格式：
```json
{
  "success": false,
  "error": "错误描述信息"
}
```

## 数据库表结构

### tasks 表
| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT | 主键，自增 |
| task_id | VARCHAR(50) | 任务编号 |
| change_content | TEXT | 变更内容 |
| risk | VARCHAR(20) | 风险等级 |
| user_name | VARCHAR(100) | 用户名 |
| month | VARCHAR(10) | 月份 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |

### task_files 表
| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT | 主键，自增 |
| task_id | BIGINT | 关联任务ID |
| file_path | TEXT | 文件路径 |
| test_status | VARCHAR(100) | 测试状态 |

### task_checks 表
| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT | 主键，自增 |
| task_id | BIGINT | 关联任务ID |
| check_item | VARCHAR(200) | 检查项内容 |
| status | VARCHAR(20) | 状态（完成/未完成） |
| sort_order | INT | 排序顺序 |

### check_templates 表
| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT | 主键，自增 |
| name | VARCHAR(100) | 模板名称 |
| description | VARCHAR(500) | 描述 |
| is_default | BOOLEAN | 是否默认模板 |
| created_at | TIMESTAMP | 创建时间 |

### check_template_items 表
| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT | 主键，自增 |
| template_id | BIGINT | 关联模板ID |
| item_text | VARCHAR(200) | 检查项文本 |
| sort_order | INT | 排序顺序 |

## 使用说明

1. 启动应用前请确保MySQL数据库已创建
2. 修改 `application.yml` 中的数据库连接配置
3. 应用启动后会自动创建表结构
4. 首次使用建议调用 `/init-template` 初始化默认检查项模板

## 注意事项

1. 所有接口都支持CORS跨域请求
2. 保存任务时会先删除同用户同月份的旧任务
3. 检查项支持动态配置，可通过数据库修改模板