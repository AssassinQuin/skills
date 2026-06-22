# Go 项目惯例

## 常量组织模式

```
一个文件 = 一个领域
命名前缀 = 领域名（AwardType*, CoinType*, DaoN*）
分组注释 = // === 分隔线标注子组
包文档   = doc.go（包级注释 + 文件清单）
死代码   = go_symbol_references 确认零引用后删除
聚合列表 = var() 块放在常量块之后
```

## 架构分层

```
main.go → cmd/ (http | task) → controller/ → logic/ → dao/ → MySQL
                                                         ↘ model/
```

- `controller/` — HTTP handlers，通过 `GetUserId(ctx)` 获取用户 ID
- `logic/` — 业务逻辑，`init()` + `service.Register*()` 注册
- `dao/` — 自动生成，禁止手动编辑
- `model/entity/` + `model/do/` — 自动生成
- `model/dto/` — 手写，层间传输对象
- `consts/` — 常量定义

## GoFrame 工具链

| 命令 | 生成内容 | 何时使用 |
|------|---------|---------|
| `gf gen ctrl` | `api/{module}/{module}.go` 接口 + `internal/controller/` handler 桩 | API 定义变更后 |
| `gf gen service` | `internal/service/*.go` 接口 | logic 层新增方法后 |
| `gf gen dao` | `internal/dao/` + `internal/model/entity/` + `internal/model/do/` | 数据库 schema 变更后 |
| `make dao` / `make ctrl` / `make service` | Makefile 封装的上述命令 | 同上，优先用 make |

**关键规则**：`api/{module}/{module}.go`、`internal/service/`、`internal/dao/`、`internal/model/entity/`、`internal/model/do/` 均为自动生成文件，**禁止手动编辑**。只手动编写：
- `api/{module}/v1/*.go` — API 请求/响应定义
- `internal/logic/` — 业务逻辑实现
- `internal/controller/*.go` — handler 方法体（桩自动生成，方法体手写）
- `internal/model/dto/` — 层间传输对象

## 代码模式

- **事务**：`g.DB().Transaction(ctx, func(ctx, tx) { ... })`，禁止自动提交
- **错误处理**：`gerror.NewCode()` + `g.I18n().T(ctx, ...)`，错误码 + i18n
- **金额计算**：`shopspring/decimal`，禁止 float64
- **测试**：table-driven + `gtest` + `testify`，中文测试名
- **服务注册**：`init()` + `service.Register*()`
