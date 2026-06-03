import { describe, it, expect } from 'vitest'
import {
  LANGUAGE_OPTIONS,
  getLanguageInfo,
  detectTextLanguage,
  isSupportedSelection,
} from './languages'

describe('languages module', () => {
  describe('LANGUAGE_OPTIONS', () => {
    it('contains at least 5 language options', () => {
      expect(LANGUAGE_OPTIONS.length).toBeGreaterThanOrEqual(5)
    })

    it('each language has required top-level keys', () => {
      for (const lang of LANGUAGE_OPTIONS) {
        expect(lang).toHaveProperty('code')
        expect(lang).toHaveProperty('label')
        expect(lang).toHaveProperty('promptName')
        expect(lang).toHaveProperty('headings')
        expect(lang).toHaveProperty('ui')
        expect(lang).toHaveProperty('settings')
        expect(lang).toHaveProperty('popup')
        expect(lang).toHaveProperty('errors')
      }
    })

    it('each language has a non-empty code', () => {
      for (const lang of LANGUAGE_OPTIONS) {
        expect(lang.code.length).toBeGreaterThan(0)
      }
    })

    it('each language has unique code', () => {
      const codes = LANGUAGE_OPTIONS.map((l) => l.code)
      const uniqueCodes = new Set(codes)
      expect(uniqueCodes.size).toBe(codes.length)
    })

    it('includes Chinese language', () => {
      const zh = LANGUAGE_OPTIONS.find((l) => l.code === 'zh-CN')
      expect(zh).toBeDefined()
      expect(zh?.promptName).toBe('Simplified Chinese')
    })

    it('includes English language', () => {
      const en = LANGUAGE_OPTIONS.find((l) => l.code === 'en')
      expect(en).toBeDefined()
      expect(en?.promptName).toBe('English')
    })
  })

  describe('getLanguageInfo', () => {
    it('returns correct language info for known code', () => {
      const info = getLanguageInfo('en')
      expect(info.code).toBe('en')
      expect(info.label).toBe('English')
    })

    it('returns first language for empty string', () => {
      const info = getLanguageInfo('')
      expect(info).toEqual(LANGUAGE_OPTIONS[0])
    })

    it('returns first language for unknown code', () => {
      const info = getLanguageInfo('xx')
      expect(info).toEqual(LANGUAGE_OPTIONS[0])
    })
  })

  describe('detectTextLanguage', () => {
    it('detects Japanese text with hiragana', () => {
      expect(detectTextLanguage('こんにちは')).toBe('ja')
    })

    it('detects Japanese text with katakana', () => {
      expect(detectTextLanguage('コンニチハ')).toBe('ja')
    })

    it('detects Korean text with hangul', () => {
      expect(detectTextLanguage('안녕하세요')).toBe('ko')
    })

    it('detects Chinese text with CJK characters', () => {
      expect(detectTextLanguage('你好世界')).toBe('zh-CN')
    })

    it('defaults to English for ASCII text', () => {
      expect(detectTextLanguage('hello world')).toBe('en')
    })

    it('detects Spanish text with accented characters', () => {
      expect(detectTextLanguage('¿Cómo estás?')).toBe('es')
    })
  })

  describe('isSupportedSelection', () => {
    it('returns true for text with letters', () => {
      expect(isSupportedSelection('hello')).toBe(true)
    })

    it('returns true for text with numbers', () => {
      expect(isSupportedSelection('123')).toBe(true)
    })

    it('returns true for CJK text', () => {
      expect(isSupportedSelection('你好')).toBe(true)
    })

    it('returns false for punctuation only', () => {
      expect(isSupportedSelection('!!!')).toBe(false)
    })

    it('returns false for empty string', () => {
      expect(isSupportedSelection('')).toBe(false)
    })
  })
})
