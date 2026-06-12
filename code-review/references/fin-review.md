# Financial Code Review Dimensions

Fin 模式的专项检查表。P1(数据完整性) > P2(流程正确性) > P3(安全合规)。

## P1: 数据完整性（权重最高）

| 检查项 | Go | Python |
|--------|-----|--------|
| **金额精度** | `float64` 用于金额 → ❌；用 `decimal.Decimal` 或整数分/厘 | `float` 用于金额 → ❌；用 `Decimal` 或整数 |
| **舍入规则** | 无显式舍入模式 → 告警 | `round()` 默认银行家舍入，是否与业务规则一致？ |
| **溢出风险** | `int32` 存金额 → 告警；大额用 `int64` 或 `big.Int` | Python int 无溢出，但 `json` 序列化可能丢精度 |
| **并发竞态** | goroutine 操作共享金额无 mutex/atomic → Critical | 多线程操作共享余额无锁 → Critical |
| **空值处理** | `nil` 指针解引用金额字段 → Critical | `None` 参与算术运算 → Critical |
| **序列化** | JSON `float` 金额字段 → 告警 | `dataclass` 金额字段类型检查 |
| **币种/单位** | 无币种标注或混用元/分/厘 → 告警 | 同左 |

**Go 专项**：`database/sql` Scan 到 `float64` / `strconv.FormatFloat` 金额 / protobuf 金额用 `double` → 全部告警

**Python 专项**：`pandas` float64 列存金额 / Django `FloatField` / SQLAlchemy `Float` → 全部告警

## P2: 流程正确性

| 检查项 | 说明 |
|--------|------|
| **幂等性** | 重试、超时重发、消息重复消费是否安全？ |
| **事务完整性** | 多表/多服务操作在事务内？失败回滚？分布式补偿？ |
| **状态机** | 订单/交易状态流转合法？无非法跳转？ |
| **对账** | 对账机制存在？差异处理完整？ |
| **审计日志** | 操作人、时间、金额、前后值是否记录？ |
| **T+0/T+1** | 交易日和结算日分离？时区正确？ |
| **并发控制** | 同账户/订单并发有锁？乐观锁版本号检查？ |
| **超时重试** | 外部调用超时合理？重试有退避？重试幂等？ |

**Go 专项**：`context.WithTimeout` 链完整 / `errgroup` 失败取消 / 事务 `defer Rollback`

**Python 专项**：Celery `autoretry_for` / Django `transaction.atomic` 嵌套 / `@retry` 覆盖外部调用

## P3: 安全合规

| 检查项 | 说明 |
|--------|------|
| SQL 注入 | 动态拼接 → Critical |
| 加密传输 | 敏感数据 TLS？内部加密？ |
| 加密存储 | PII 加密存储？密钥管理安全？ |
| 日志脱敏 | 泄露金额/卡号/身份证号？ |
| 鉴权授权 | API 鉴权？角色区分？越权风险？ |
| PII 处理 | 合规依据？最小化采集？ |
| 合规标注 | 关键逻辑标注适用法规（反洗钱、KYC）？ |
| 密钥硬编码 | API key/secret/token 硬编码 → Critical |
| 输入校验 | 白名单？金额上下限？ |

## 严重性

| 级别 | 举例 |
|------|------|
| **Critical** | float64 存金额、事务不完整、SQL 注入、密钥硬编码 |
| **Warning** | 无幂等、无审计日志、日志脱敏不完整 |
| **Info** | 命名不规范、缺少注释、可简化逻辑 |
