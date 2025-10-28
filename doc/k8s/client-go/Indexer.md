数据经过 `Reflector` 的 `List+Watch`，通过 `DeltaFIFO` 队列的存储，最终将这些资源对象存储到 `Indexer`
`Clinet-go` 通过从 `Indexer` 中读取数据而不是远程 `etcd`

### 存储

- `IndexFunc+Indexers`
  - 用什么函数来提取索引值
  - `Indexers`
    - `map`
    - `key`
      - `namespace`
      - `node`
    - `IndexFunc`
- `Index`
  - 某些索引值该对应那些对象
- `Indices`
  - 系统中该存在哪些索引
  - `map`
  - `key`
    - `namespace`
    - `node`
  - `Index: map`
    - `key`
      - 从 `IndexFunc` 中获取的索引值
    - 对象键集合