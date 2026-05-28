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
      discoveryHint: '提示：点击或拖动解释中的文字，可加入生词本并重新生成解释',
      confirmButton: '标记并重新解释',
      selectedPrefix: '已选择：',
      selectedSuffix: ' · 点击按钮加入生词本并重新解释',
      markingPrefix: '标记「',
      markingSuffix: '」并重新生成解释',
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
      footerHint: 'Click or drag to select unknown Chinese words',
      discoveryHint: 'Tip: click or drag Chinese text in the explanation to save and simplify it.',
      confirmButton: 'Save and explain again',
      selectedPrefix: 'Selected: ',
      selectedSuffix: ' · click the button to save and explain again',
      markingPrefix: 'Saving “',
      markingSuffix: '” and explaining again',
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
      footerHint: '知らない中国語をクリックまたはドラッグで選択',
      discoveryHint: 'ヒント：説明内の中国語を選択すると単語帳に保存して再説明できます。',
      confirmButton: '保存して再説明',
      selectedPrefix: '選択済み：',
      selectedSuffix: ' · ボタンを押すと保存して再説明します',
      markingPrefix: '「',
      markingSuffix: '」を保存して再説明中',
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
      footerHint: '모르는 중국어를 클릭하거나 드래그해 선택하세요',
      discoveryHint: '팁: 설명 안의 중국어를 선택하면 단어장에 저장하고 다시 설명합니다.',
      confirmButton: '저장하고 다시 설명',
      selectedPrefix: '선택됨: ',
      selectedSuffix: ' · 버튼을 눌러 저장하고 다시 설명',
      markingPrefix: '“',
      markingSuffix: '” 저장 후 다시 설명 중',
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
      footerHint: 'Haz clic o arrastra para seleccionar palabras chinas desconocidas',
      discoveryHint: 'Consejo: selecciona chino en la explicación para guardarlo y simplificarlo.',
      confirmButton: 'Guardar y explicar otra vez',
      selectedPrefix: 'Seleccionado: ',
      selectedSuffix: ' · haz clic en el botón para guardar y explicar otra vez',
      markingPrefix: 'Guardando “',
      markingSuffix: '” y explicando otra vez',
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
