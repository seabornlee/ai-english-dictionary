import { type ExplanationLanguage } from '../lib/languages'
import { getConfig, saveConfig, type LLMConfig } from '../lib/storage'
import {
  getAuthState,
  setAuthState,
  clearAuthState,
  isAuthenticated,
  isLicensed,
  ensureDeviceId,
} from '../lib/auth'
import { login, register, activateLicense } from '../lib/api-client'

// ── DOM Elements ──

const form = document.getElementById('config-form') as HTMLFormElement
const languageSelect = document.getElementById('language') as HTMLSelectElement
const providerSelect = document.getElementById('provider') as HTMLSelectElement
const apiKeyInput = document.getElementById('apiKey') as HTMLInputElement
const modelInput = document.getElementById('model') as HTMLInputElement
const baseUrlInput = document.getElementById('baseUrl') as HTMLInputElement
const simpleSectionInput = document.getElementById('section-simple') as HTMLInputElement
const examplesSectionInput = document.getElementById('section-examples') as HTMLInputElement
const collocationsSectionInput = document.getElementById('section-collocations') as HTMLInputElement
const successMsg = document.getElementById('success-msg') as HTMLElement

const apiKeyGroup = document.getElementById('api-key-group') as HTMLElement
const modelGroup = document.getElementById('model-group') as HTMLElement
const baseUrlGroup = document.getElementById('base-url-group') as HTMLElement

// Auth elements
const accountLoggedOut = document.getElementById('account-logged-out') as HTMLElement
const accountLoggedIn = document.getElementById('account-logged-in') as HTMLElement
const authEmailInput = document.getElementById('auth-email') as HTMLInputElement
const authPasswordInput = document.getElementById('auth-password') as HTMLInputElement
const authEmailDisplay = document.getElementById('auth-email-display') as HTMLElement
const licenseStatusEl = document.getElementById('license-status') as HTMLElement
const authError = document.getElementById('auth-error') as HTMLElement
const authSuccess = document.getElementById('auth-success') as HTMLElement
const licenseError = document.getElementById('license-error') as HTMLElement
const licenseSuccess = document.getElementById('license-success') as HTMLElement

const btnLogin = document.getElementById('btn-login') as HTMLButtonElement
const btnRegister = document.getElementById('btn-register') as HTMLButtonElement
const btnActivateLicense = document.getElementById('btn-activate-license') as HTMLButtonElement
const btnLogout = document.getElementById('btn-logout') as HTMLButtonElement

// ── Provider Defaults ──

const defaultModels: Record<string, string> = {
  openai: 'gpt-4o-mini',
  claude: 'claude-3-haiku-20240307',
  custom: 'gpt-4o-mini',
  server: '',
}

const defaultUrls: Record<string, string> = {
  openai: 'https://api.openai.com/v1',
  claude: 'https://api.anthropic.com/v1',
  custom: '',
  server: '',
}

// ── Toggle API fields visibility ──

function toggleApiFields(provider: string) {
  const isServer = provider === 'server'
  apiKeyGroup.style.display = isServer ? 'none' : ''
  modelGroup.style.display = isServer ? 'none' : ''
  baseUrlGroup.style.display = isServer ? 'none' : ''
}

// ── Auth UI ──

async function refreshAuthUI() {
  const authState = await getAuthState()
  const loggedIn = isAuthenticated(authState)
  const licensed = isLicensed(authState)

  accountLoggedOut.style.display = loggedIn ? 'none' : ''
  accountLoggedIn.style.display = loggedIn ? '' : 'none'

  if (loggedIn) {
    authEmailDisplay.textContent = `📧 ${authState.email}`
  }

  if (licensed) {
    licenseStatusEl.textContent = '✅ 许可证：已激活'
    licenseStatusEl.className = 'license-status active'
    btnActivateLicense.style.display = 'none'
  } else if (loggedIn) {
    licenseStatusEl.textContent = '❌ 许可证：未激活'
    licenseStatusEl.className = 'license-status inactive'
    btnActivateLicense.style.display = ''
  }

  clearMessages()
}

function showAuthError(msg: string) {
  authError.textContent = msg
  authError.className = 'error show'
  setTimeout(() => { authError.className = 'error' }, 5000)
}

function showAuthSuccess(msg: string) {
  authSuccess.textContent = msg
  authSuccess.className = 'success show'
  setTimeout(() => { authSuccess.className = 'success' }, 5000)
}

function showLicenseError(msg: string) {
  licenseError.textContent = msg
  licenseError.className = 'error show'
  setTimeout(() => { licenseError.className = 'error' }, 5000)
}

function showLicenseSuccess(msg: string) {
  licenseSuccess.textContent = msg
  licenseSuccess.className = 'success show'
  setTimeout(() => { licenseSuccess.className = 'success' }, 5000)
}

function clearMessages() {
  authError.className = 'error'
  authSuccess.className = 'success'
  licenseError.className = 'error'
  licenseSuccess.className = 'success'
}

// ── Auth Actions ──

btnLogin.addEventListener('click', async () => {
  const email = authEmailInput.value.trim()
  const password = authPasswordInput.value

  if (!email || !password) {
    showAuthError('请输入邮箱和密码')
    return
  }

  try {
    const authState = await getAuthState()
    const response = await login(authState.serverUrl, email, password)
    await setAuthState({ userToken: response.token, email: response.user.email })
    showAuthSuccess('登录成功')
    authPasswordInput.value = ''
    await refreshAuthUI()
  } catch (err) {
    showAuthError((err as Error).message || '登录失败')
  }
})

btnRegister.addEventListener('click', async () => {
  const email = authEmailInput.value.trim()
  const password = authPasswordInput.value

  if (!email || !password) {
    showAuthError('请输入邮箱和密码')
    return
  }

  if (password.length < 6) {
    showAuthError('密码至少 6 位')
    return
  }

  try {
    const authState = await getAuthState()
    const response = await register(authState.serverUrl, email, password)
    await setAuthState({ userToken: response.token, email: response.user.email })
    showAuthSuccess('注册成功！请检查邮箱完成验证后登录。')
    // If email verification is required, log them out until verified
    await setAuthState({ userToken: null })
    await refreshAuthUI()
  } catch (err) {
    showAuthError((err as Error).message || '注册失败')
  }
})

btnLogout.addEventListener('click', async () => {
  await clearAuthState()
  await refreshAuthUI()
})

btnActivateLicense.addEventListener('click', async () => {
  try {
    const authState = await getAuthState()
    if (!authState.userToken) {
      showLicenseError('请先登录')
      return
    }

    btnActivateLicense.disabled = true
    btnActivateLicense.textContent = '激活中...'

    const deviceId = await ensureDeviceId()
    const response = await activateLicense(authState.serverUrl, authState.userToken, deviceId)
    await setAuthState({ licenseToken: response.token })
    showLicenseSuccess('许可证激活成功')
    await refreshAuthUI()
  } catch (err) {
    showLicenseError((err as Error).message || '激活失败')
  } finally {
    btnActivateLicense.disabled = false
    btnActivateLicense.textContent = '激活许可证'
  }
})

// ── Config Form ──

providerSelect.addEventListener('change', () => {
  const provider = providerSelect.value
  modelInput.placeholder = defaultModels[provider] || ''
  baseUrlInput.placeholder = defaultUrls[provider] || ''
  toggleApiFields(provider)
})

form.addEventListener('submit', (e) => {
  e.preventDefault()
  void saveFormConfig()
})

async function saveFormConfig() {
  const config: LLMConfig = {
    provider: providerSelect.value as LLMConfig['provider'],
    apiKey: apiKeyInput.value,
    model: modelInput.value || defaultModels[providerSelect.value],
    baseUrl: baseUrlInput.value || defaultUrls[providerSelect.value],
    language: languageSelect.value as ExplanationLanguage,
    explanationSections: {
      simple: simpleSectionInput.checked,
      examples: examplesSectionInput.checked,
      collocations: collocationsSectionInput.checked,
    },
  }

  await saveConfig(config)
  successMsg.classList.add('show')
  setTimeout(() => {
    successMsg.classList.remove('show')
  }, 2000)
}

async function loadConfig() {
  const config = await getConfig()
  languageSelect.value = config.language
  providerSelect.value = config.provider
  apiKeyInput.value = config.apiKey
  modelInput.value = config.model
  baseUrlInput.value = config.baseUrl
  simpleSectionInput.checked = config.explanationSections.simple
  examplesSectionInput.checked = config.explanationSections.examples
  collocationsSectionInput.checked = config.explanationSections.collocations
  toggleApiFields(config.provider)
}

// ── Init ──

void loadConfig()
void refreshAuthUI()