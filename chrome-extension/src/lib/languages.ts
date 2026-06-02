export type ExplanationLanguage = '' | 'zh-CN' | 'en' | 'ja' | 'ko' | 'es'

export interface LanguageInfo {
  code: Exclude<ExplanationLanguage, ''>
  label: string
  promptName: string
  headings: {
    basic: string
    simple: string
    examples: string
    collocations: string
  }
  ui: {
    loading: string
    footerHint: string
    discoveryHint: string
    confirmButton: string
    selectedPrefix: string
    selectedSuffix: string
    markingPrefix: string
    markingSuffix: string
  }
  settings: {
    title: string
    interfaceLanguage: string
    interfaceLanguageHint: string
    selectOnFirstUse: string
    provider: string
    apiKey: string
    apiKeyHint: string
    modelName: string
    modelHint: string
    baseUrl: string
    baseUrlHint: string
    explanationContent: string
    explanationContentHint: string
    simplerWording: string
    examples: string
    collocations: string
    saveSettings: string
    settingsSaved: string
    customOpenAI: string
  }
  popup: {
    title: string
    settingsTooltip: string
    emptyState: string
    emptyHint: string
    export: string
    clear: string
    clearConfirm: string
    justNow: string
    minutesAgo: string
    hoursAgo: string
    today: string
  }
  errors: {
    apiKeyRequired: string
    licenseRequired: string
    apiRequestFailed: string
  }
}

export const LANGUAGE_OPTIONS: LanguageInfo[] = [
  {
    code: 'zh-CN',
    label: '简体中文',
    promptName: 'Simplified Chinese',
    headings: {
      basic: '简明释义',
      simple: '更简单的说法',
      examples: '例句',
      collocations: '常见搭配',
    },
    ui: {
      loading: '正在查询',
      footerHint: '点击或拖动选择生词；从已选文字拖动可反选',
      discoveryHint: '提示：点击不认识的生词，AI 将避开它们重新解释',
      confirmButton: '生成',
      selectedPrefix: '点击生成不包含',
      selectedSuffix: '的解释',
      markingPrefix: '正在生成不包含「',
      markingSuffix: '」的解释',
    },
    settings: {
      title: '🔧 词析 设置',
      interfaceLanguage: '界面语言',
      interfaceLanguageHint: '控制设置页和弹窗提示语言；AI 解释语言会自动跟随划词语言。',
      selectOnFirstUse: '首次使用时选择',
      provider: 'API 提供商',
      apiKey: 'API Key',
      apiKeyHint: '你的 API 密钥，将安全存储在本地',
      modelName: '模型名称',
      modelHint: '推荐：gpt-4o-mini（OpenAI）/ claude-3-haiku-20240307（Claude）',
      baseUrl: 'API Base URL',
      baseUrlHint: '如使用代理或自定义服务，请修改此地址',
      explanationContent: '解释内容',
      explanationContentHint: '默认只显示"简明释义"，下列板块需要手动启用。',
      simplerWording: '更简单的说法',
      examples: '例句',
      collocations: '常见搭配',
      saveSettings: '保存设置',
      settingsSaved: '✓ 设置已保存',
      customOpenAI: '自定义 (OpenAI 兼容)',
    },
    popup: {
      title: '📚 生词本',
      settingsTooltip: '设置',
      emptyState: '还没有生词',
      emptyHint: '选中网页中的词语即可查询',
      export: '导出生词',
      clear: '清空',
      clearConfirm: '确定要清空所有生词吗？',
      justNow: '刚刚',
      minutesAgo: ' 分钟前',
      hoursAgo: ' 小时前',
      today: '今天',
    },
    errors: {
      apiKeyRequired: '请先在设置中配置 API Key',
      licenseRequired: '请先在设置中登录并激活许可证',
      apiRequestFailed: 'API 请求失败',
    },
  },
  {
    code: 'en',
    label: 'English',
    promptName: 'English',
    headings: {
      basic: 'Basic definition',
      simple: 'Simpler wording',
      examples: 'Examples',
      collocations: 'Common collocations',
    },
    ui: {
      loading: 'Looking up',
      footerHint: 'Click or drag to select unknown words',
      discoveryHint: 'Tip: click or drag text in the explanation to save and simplify it.',
      confirmButton: 'Save and explain again',
      selectedPrefix: 'Selected: ',
      selectedSuffix: ' · click the button to save and explain again',
      markingPrefix: 'Saving "',
      markingSuffix: '" and explaining again',
    },
    settings: {
      title: '🔧 Lexis Settings',
      interfaceLanguage: 'Interface Language',
      interfaceLanguageHint: 'Controls settings and popup language; AI explanation language follows the selected text.',
      selectOnFirstUse: 'Select on first use',
      provider: 'API Provider',
      apiKey: 'API Key',
      apiKeyHint: 'Your API key, stored securely on your device',
      modelName: 'Model Name',
      modelHint: 'Recommended: gpt-4o-mini (OpenAI) / claude-3-haiku-20240307 (Claude)',
      baseUrl: 'API Base URL',
      baseUrlHint: 'Modify this if using a proxy or custom service',
      explanationContent: 'Explanation Content',
      explanationContentHint: 'Only "Basic definition" is shown by default. Enable additional sections below.',
      simplerWording: 'Simpler wording',
      examples: 'Examples',
      collocations: 'Common collocations',
      saveSettings: 'Save Settings',
      settingsSaved: '✓ Settings saved',
      customOpenAI: 'Custom (OpenAI compatible)',
    },
    popup: {
      title: '📚 Vocabulary',
      settingsTooltip: 'Settings',
      emptyState: 'No words yet',
      emptyHint: 'Select text on any webpage to look it up',
      export: 'Export',
      clear: 'Clear',
      clearConfirm: 'Are you sure you want to clear all words?',
      justNow: 'just now',
      minutesAgo: ' min ago',
      hoursAgo: ' hr ago',
      today: 'today',
    },
    errors: {
      apiKeyRequired: 'Please configure your API Key in Settings',
      licenseRequired: 'Please log in and activate your license in Settings',
      apiRequestFailed: 'API request failed',
    },
  },
  {
    code: 'ja',
    label: '日本語',
    promptName: 'Japanese',
    headings: {
      basic: '簡潔な意味',
      simple: 'より簡単な言い方',
      examples: '例文',
      collocations: 'よくある組み合わせ',
    },
    ui: {
      loading: '検索中',
      footerHint: '知らない単語をクリックまたはドラッグで選択',
      discoveryHint: 'ヒント：説明内の単語を選択すると単語帳に保存して再説明できます。',
      confirmButton: '保存して再説明',
      selectedPrefix: '選択済み：',
      selectedSuffix: ' · ボタンを押すと保存して再説明します',
      markingPrefix: '「',
      markingSuffix: '」を保存して再説明中',
    },
    settings: {
      title: '🔧 Lexis 設定',
      interfaceLanguage: 'インターフェース言語',
      interfaceLanguageHint: '設定とポップアップの言語を制御します。AI説明言語は選択テキストに従います。',
      selectOnFirstUse: '初回使用時に選択',
      provider: 'APIプロバイダー',
      apiKey: 'APIキー',
      apiKeyHint: 'APIキーはデバイスに安全に保存されます',
      modelName: 'モデル名',
      modelHint: '推奨：gpt-4o-mini（OpenAI）/ claude-3-haiku-20240307（Claude）',
      baseUrl: 'API Base URL',
      baseUrlHint: 'プロキシやカスタムサービスを使用する場合は変更してください',
      explanationContent: '説明内容',
      explanationContentHint: 'デフォルトでは「簡潔な意味」のみ表示。以下のセクションを有効にできます。',
      simplerWording: 'より簡単な言い方',
      examples: '例文',
      collocations: 'よくある組み合わせ',
      saveSettings: '設定を保存',
      settingsSaved: '✓ 設定を保存しました',
      customOpenAI: 'カスタム（OpenAI互換）',
    },
    popup: {
      title: '📚 単語帳',
      settingsTooltip: '設定',
      emptyState: 'まだ単語がありません',
      emptyHint: 'ウェブページでテキストを選択して検索',
      export: 'エクスポート',
      clear: 'クリア',
      clearConfirm: 'すべての単語を削除しますか？',
      justNow: 'たった今',
      minutesAgo: '分前',
      hoursAgo: '時間前',
      today: '今日',
    },
    errors: {
      apiKeyRequired: '設定でAPIキーを設定してください',
      licenseRequired: '設定でログインしてライセンスを有効化してください',
      apiRequestFailed: 'APIリクエストに失敗しました',
    },
  },
  {
    code: 'ko',
    label: '한국어',
    promptName: 'Korean',
    headings: {
      basic: '간단한 뜻',
      simple: '더 쉬운 설명',
      examples: '예문',
      collocations: '자주 쓰는 조합',
    },
    ui: {
      loading: '검색 중',
      footerHint: '모르는 단어를 클릭하거나 드래그해 선택하세요',
      discoveryHint: '팁: 설명 안의 단어를 선택하면 단어장에 저장하고 다시 설명합니다.',
      confirmButton: '저장하고 다시 설명',
      selectedPrefix: '선택됨: ',
      selectedSuffix: ' · 버튼을 눌러 저장하고 다시 설명',
      markingPrefix: '"',
      markingSuffix: '" 저장 후 다시 설명 중',
    },
    settings: {
      title: '🔧 Lexis 설정',
      interfaceLanguage: '인터페이스 언어',
      interfaceLanguageHint: '설정 및 팝업 언어를 제어합니다. AI 설명 언어는 선택한 텍스트를 따릅니다.',
      selectOnFirstUse: '첫 사용 시 선택',
      provider: 'API 제공자',
      apiKey: 'API 키',
      apiKeyHint: 'API 키는 기기에 안전하게 저장됩니다',
      modelName: '모델 이름',
      modelHint: '권장: gpt-4o-mini (OpenAI) / claude-3-haiku-20240307 (Claude)',
      baseUrl: 'API Base URL',
      baseUrlHint: '프록시나 커스텀 서비스를 사용하는 경우 수정하세요',
      explanationContent: '설명 내용',
      explanationContentHint: '기본적으로 "간단한 뜻"만 표시됩니다. 아래 섹션을 활성화할 수 있습니다.',
      simplerWording: '더 쉬운 설명',
      examples: '예문',
      collocations: '자주 쓰는 조합',
      saveSettings: '설정 저장',
      settingsSaved: '✓ 설정이 저장되었습니다',
      customOpenAI: '커스텀 (OpenAI 호환)',
    },
    popup: {
      title: '📚 단어장',
      settingsTooltip: '설정',
      emptyState: '아직 단어가 없습니다',
      emptyHint: '웹페이지에서 텍스트를 선택하여 검색하세요',
      export: '내보내기',
      clear: '지우기',
      clearConfirm: '모든 단어를 삭제하시겠습니까?',
      justNow: '방금',
      minutesAgo: '분 전',
      hoursAgo: '시간 전',
      today: '오늘',
    },
    errors: {
      apiKeyRequired: '설정에서 API 키를 구성해주세요',
      licenseRequired: '설정에서 로그인하고 라이선스를 활성화해주세요',
      apiRequestFailed: 'API 요청 실패',
    },
  },
  {
    code: 'es',
    label: 'Español',
    promptName: 'Spanish',
    headings: {
      basic: 'Definición básica',
      simple: 'Explicación más simple',
      examples: 'Ejemplos',
      collocations: 'Combinaciones comunes',
    },
    ui: {
      loading: 'Buscando',
      footerHint: 'Haz clic o arrastra para seleccionar palabras desconocidas',
      discoveryHint: 'Consejo: selecciona texto en la explicación para guardarlo y simplificarlo.',
      confirmButton: 'Guardar y explicar otra vez',
      selectedPrefix: 'Seleccionado: ',
      selectedSuffix: ' · haz clic en el botón para guardar y explicar otra vez',
      markingPrefix: 'Guardando "',
      markingSuffix: '" y explicando otra vez',
    },
    settings: {
      title: '🔧 Configuración de Lexis',
      interfaceLanguage: 'Idioma de interfaz',
      interfaceLanguageHint: 'Controla el idioma de configuración y popup; el idioma de explicación AI sigue el texto seleccionado.',
      selectOnFirstUse: 'Seleccionar en el primer uso',
      provider: 'Proveedor de API',
      apiKey: 'Clave API',
      apiKeyHint: 'Tu clave API, almacenada de forma segura en tu dispositivo',
      modelName: 'Nombre del modelo',
      modelHint: 'Recomendado: gpt-4o-mini (OpenAI) / claude-3-haiku-20240307 (Claude)',
      baseUrl: 'URL base de API',
      baseUrlHint: 'Modifica esto si usas un proxy o servicio personalizado',
      explanationContent: 'Contenido de explicación',
      explanationContentHint: 'Solo se muestra "Definición básica" por defecto. Habilita secciones adicionales abajo.',
      simplerWording: 'Explicación más simple',
      examples: 'Ejemplos',
      collocations: 'Combinaciones comunes',
      saveSettings: 'Guardar configuración',
      settingsSaved: '✓ Configuración guardada',
      customOpenAI: 'Personalizado (compatible con OpenAI)',
    },
    popup: {
      title: '📚 Vocabulario',
      settingsTooltip: 'Configuración',
      emptyState: 'Aún no hay palabras',
      emptyHint: 'Selecciona texto en cualquier página web para buscarlo',
      export: 'Exportar',
      clear: 'Borrar',
      clearConfirm: '¿Estás seguro de que quieres borrar todas las palabras?',
      justNow: 'ahora mismo',
      minutesAgo: ' min atrás',
      hoursAgo: ' hr atrás',
      today: 'hoy',
    },
    errors: {
      apiKeyRequired: 'Configura tu API Key en Configuración',
      licenseRequired: 'Inicia sesión y activa tu licencia en Configuración',
      apiRequestFailed: 'Solicitud API fallida',
    },
  },
]

export function getLanguageInfo(language: ExplanationLanguage): LanguageInfo {
  return LANGUAGE_OPTIONS.find((item) => item.code === language) ?? LANGUAGE_OPTIONS[0]
}

export function detectTextLanguage(text: string): Exclude<ExplanationLanguage, ''> {
  if (/[\u3040-\u30ff]/.test(text)) {
    return 'ja'
  }
  if (/[\uac00-\ud7af]/.test(text)) {
    return 'ko'
  }
  if (/[\u4e00-\u9fff]/.test(text)) {
    return 'zh-CN'
  }
  if (/[ñáéíóúü¿¡]/i.test(text)) {
    return 'es'
  }
  return 'en'
}

export function isSupportedSelection(text: string): boolean {
  return /[\p{L}\p{N}]/u.test(text)
}
