/**
 * Global type definitions for AI Dictionary Server
 */

// Express request extensions
declare namespace Express {
  interface Request {
    user?: {
      id: string;
      email: string;
      licenseKey?: string;
    };
    license?: {
      key: string;
      email: string;
      isValid: boolean;
    };
  }
}

// Word definition types
interface WordDefinition {
  term: string;
  definition: string;
  pronunciation: string | null;
  partOfSpeech: string | null;
  exampleSentences: string[];
  simpleDefinition?: string | null;
  examples?: string[] | null;
  collocations?: Collocation[] | null;
  language: string;
  timestamp: Date;
}

interface Collocation {
  phrase: string;
  meaning: string;
}

interface StoredWord {
  term: string;
  definition: string;
  pronunciation: string | null;
  partOfSpeech: string | null;
  exampleSentences: string[];
  timestamp: Date;
}

// API request/response types
interface DefineWordRequest {
  word: string;
  unknownWords?: string[];
  language?: string;
  explanationSections?: ExplanationSections;
}

interface ExplanationSections {
  simple?: boolean;
  examples?: boolean;
  collocations?: boolean;
}

interface ApiError {
  error: string;
  message?: string;
}

// Environment variables
declare namespace NodeJS {
  interface ProcessEnv {
    NODE_ENV?: 'development' | 'production' | 'test';
    PORT?: string;
    MONGODB_URI?: string;
    SILICONFLOW_API_KEY?: string;
    JWT_SECRET?: string;
    RESEND_API_KEY?: string;
  }
}
