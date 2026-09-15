import ./skk/dictionary

type SearchEngine* = object
  dict: SkkDict

proc initSearchEngine*(dictionaryPath: string): SearchEngine =
  result.dict = openDict(dictionaryPath)

proc close*(engine: var SearchEngine) =
  engine.dict.close()

proc lookup*(engine: SearchEngine, key: string): seq[string] =
  result = engine.dict.lookup(key)
