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

## 代码模式

- **事务**：`g.DB().Transaction(ctx, func(ctx, tx) { ... })`，禁止自动提交
- **错误处理**：`gerror.NewCode()` + `g.I18n().T(ctx, ...)`，错误码 + i18n
- **金额计算**：`shopspring/decimal`，禁止 float64
- **测试**：table-driven + `gtest` + `testify`，中文测试名
- **服务注册**：`init()` + `service.Register*()`
