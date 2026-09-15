import ./skk/memfile_dict

type SearchEngine* = object
  ## 複合ルートによる見出し語の変換候補検索エンジン
  dict: SkkMemfileDict

proc initSearchEngine*(path: string): SearchEngine =
  result.dict = openDict(path)

proc close*(engine: var SearchEngine) =
  engine.dict.close()

proc lookup*(engine: SearchEngine, key: string): seq[string] =
  result = engine.dict.lookup(key)
