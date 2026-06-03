import { type CSSProperties, type ReactNode } from 'react'
import {
  AbsoluteFill,
  Composition,
  Easing,
  Sequence,
  interpolate,
  registerRoot,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion'

const FPS = 30
const WIDTH = 1920
const HEIGHT = 1080
const DURATION = 1350
const FONT = '-apple-system, BlinkMacSystemFont, "Segoe UI", "Microsoft YaHei", sans-serif'

function RemotionRoot() {
  return (
    <Composition
      id="LexisPromo"
      component={LexisPromo}
      durationInFrames={DURATION}
      fps={FPS}
      width={WIDTH}
      height={HEIGHT}
    />
  )
}

function LexisPromo() {
  return (
    <AbsoluteFill style={backgroundStyle}>
      <GradientOrbs />
      <Sequence from={0} durationInFrames={120}>
        <IntroScene />
      </Sequence>
      <Sequence from={120} durationInFrames={180}>
        <SelectScene />
      </Sequence>
      <Sequence from={300} durationInFrames={210}>
        <DefinitionScene />
      </Sequence>
      <Sequence from={510} durationInFrames={240}>
        <MarkScene />
      </Sequence>
      <Sequence from={750} durationInFrames={210}>
        <SimplifyScene />
      </Sequence>
      <Sequence from={960} durationInFrames={180}>
        <VocabularyScene />
      </Sequence>
      <Sequence from={1140} durationInFrames={150}>
        <LanguageScene />
      </Sequence>
      <Sequence from={1290} durationInFrames={60}>
        <OutroScene />
      </Sequence>
    </AbsoluteFill>
  )
}

function IntroScene() {
  const frame = useCurrentFrame()
  const { fps } = useVideoConfig()
  const scale = spring({ frame, fps, config: { damping: 18, stiffness: 110 } })
  const opacity = fade(frame, 0, 20, 96, 119)

  return (
    <AbsoluteFill style={{ ...centerStyle, opacity }}>
      <div style={{ ...logoMarkStyle, transform: `scale(${scale})` }}>L</div>
      <h1 style={heroTitleStyle}>Lexis</h1>
      <p style={heroSubtitleStyle}>Learn Chinese while reading</p>
      <Caption text="Meet Lexis — an AI Chinese dictionary for language learners who read on the web." />
    </AbsoluteFill>
  )
}

function SelectScene() {
  const frame = useCurrentFrame()
  const cursorX = interpolate(frame, [35, 88], [1030, 704], clamp)
  const highlight = interpolate(frame, [55, 92], [0, 1], clamp)

  return (
    <SceneShell caption="Select any Chinese word on any webpage. Lexis explains it instantly.">
      <CopyBlock
        eyebrow="Instant lookup"
        title="Select Chinese text anywhere"
        body="Works directly on the webpage you are reading."
      />
      <BrowserMock highlightOpacity={highlight} />
      <MousePointer x={cursorX} y={560} />
    </SceneShell>
  )
}

function DefinitionScene() {
  const frame = useCurrentFrame()
  const y = interpolate(frame, [15, 45], [70, 0], easeOut)
  const opacity = interpolate(frame, [10, 35], [0, 1], clamp)

  return (
    <SceneShell caption="Get clear Chinese definitions powered by AI. No interruption to your reading.">
      <CopyBlock
        eyebrow="AI explanations"
        title="Understand meaning in context"
        body="Definitions are concise and in Chinese."
      />
      <BrowserMock highlightOpacity={1}>
        <div style={{ ...floatingTooltipWrap, opacity, transform: `translateY(${y}px)` }}>
          <DefinitionTooltip selectedWord="沪指" />
        </div>
      </BrowserMock>
    </SceneShell>
  )
}

function MarkScene() {
  const frame = useCurrentFrame()
  const selectedOpacity = interpolate(frame, [50, 80], [0, 1], clamp)
  const actionOpacity = interpolate(frame, [90, 125], [0, 1], clamp)

  return (
    <SceneShell caption="If the explanation contains words you don't know, click to mark them.">
      <CopyBlock
        eyebrow="Mark unknown words"
        title="Build your learning loop"
        body="Marked words become part of your vocabulary."
      />
      <BrowserMock highlightOpacity={1}>
        <div style={floatingTooltipWrap}>
          <DefinitionTooltip
            selectedWord="沪指"
            selectedOpacity={selectedOpacity}
            actionOpacity={actionOpacity}
          />
        </div>
      </BrowserMock>
      <MousePointer x={1370} y={506} />
    </SceneShell>
  )
}

function SimplifyScene() {
  const frame = useCurrentFrame()
  const beforeOpacity = interpolate(frame, [0, 50, 75], [1, 1, 0], clamp)
  const afterOpacity = interpolate(frame, [75, 110], [0, 1], clamp)

  return (
    <SceneShell caption="Lexis saves those words and explains again WITHOUT using them.">
      <CopyBlock
        eyebrow="Simpler re-explanations"
        title="Adapts to your vocabulary"
        body="Every explanation avoids words you already know."
      />
      <div style={comparePanelStyle}>
        <div style={{ ...miniTooltipStyle, opacity: beforeOpacity }}>
          <div style={miniLabelStyle}>Basic definition</div>
          <p>
            上海证券交易所的<span style={selectedWordStyle}>股票</span>
            <span style={selectedWordStyle}>价格</span>
            <span style={wordChipStyle}>指数</span>，反映上海证券市场
            <span style={wordChipStyle}>整体</span>走势。
          </p>
          <div style={{ fontSize: 14, color: '#999', marginTop: 12 }}>Selected: 股票、价格</div>
        </div>
        <div style={arrowStyle}>→</div>
        <div style={{ ...miniTooltipStyle, opacity: afterOpacity }}>
          <div style={{ ...miniLabelStyle, color: '#4caf50' }}>Simpler wording</div>
          <p>沪指是反映上海股市好坏的一个数字。数字上涨说明股市好，下跌说明股市不好。</p>
        </div>
      </div>
    </SceneShell>
  )
}

function VocabularyScene() {
  return (
    <SceneShell caption="Every marked word is saved. Future explanations automatically avoid them.">
      <CopyBlock
        eyebrow="Vocabulary notebook"
        title="Words accumulate over time"
        body="Review your vocabulary, export anytime. All stored locally."
      />
      <VocabularyNotebook />
    </SceneShell>
  )
}

function LanguageScene() {
  return (
    <SceneShell caption="Choose your interface language. Explanations stay in Chinese.">
      <CopyBlock
        eyebrow="5 interface languages"
        title="Learn Chinese your way"
        body="Use English, Japanese, Korean, Spanish, or Chinese as your interface."
      />
      <div style={languageGridStyle}>
        {['English', '日本語', '한국어', 'Español', '简体中文'].map((language) => (
          <div key={language} style={languageCardStyle}>
            {language}
          </div>
        ))}
      </div>
    </SceneShell>
  )
}

function OutroScene() {
  const frame = useCurrentFrame()
  const opacity = interpolate(frame, [0, 18, 59], [0, 1, 1], clamp)

  return (
    <AbsoluteFill style={{ ...centerStyle, opacity }}>
      <div style={logoRowStyle}>
        <div style={smallLogoStyle}>L</div>
        <span>Lexis</span>
      </div>
      <h2 style={outroTitleStyle}>Learn Chinese from context</h2>
      <p style={outroBodyStyle}>Select. Understand. Mark. Simplify.</p>
    </AbsoluteFill>
  )
}

function SceneShell({ children, caption }: { children: ReactNode; caption: string }) {
  const frame = useCurrentFrame()
  const opacity = interpolate(frame, [0, 18], [0, 1], clamp)

  return (
    <AbsoluteFill style={{ ...sceneStyle, opacity }}>
      {children}
      <Caption text={caption} />
    </AbsoluteFill>
  )
}

function CopyBlock({ eyebrow, title, body }: { eyebrow: string; title: string; body: string }) {
  const frame = useCurrentFrame()
  const y = interpolate(frame, [0, 26], [44, 0], easeOut)

  return (
    <div style={{ ...copyStyle, transform: `translateY(${y}px)` }}>
      <div style={eyebrowStyle}>{eyebrow}</div>
      <h2 style={slideTitleStyle}>{title}</h2>
      <p style={slideBodyStyle}>{body}</p>
    </div>
  )
}

function BrowserMock({
  highlightOpacity,
  children,
}: {
  highlightOpacity: number
  children?: ReactNode
}) {
  return (
    <div style={browserStyle}>
      <div style={browserHeaderStyle}>
        <span style={{ ...dotStyle, background: '#ff5f56' }} />
        <span style={{ ...dotStyle, background: '#ffbd2e' }} />
        <span style={{ ...dotStyle, background: '#27c93f' }} />
        <div style={addressStyle}>news.sina.com.cn/finance</div>
      </div>
      <div style={articleStyle}>
        <p>
          今日大盘震荡上行，
          <span style={{ ...highlightStyle, opacity: highlightOpacity }}>沪指</span>收涨0.8%。
        </p>
      </div>
      {children}
    </div>
  )
}

function DefinitionTooltip({
  selectedWord,
  selectedOpacity = 0,
  actionOpacity = 0,
}: {
  selectedWord: string
  selectedOpacity?: number
  actionOpacity?: number
}) {
  return (
    <div style={tooltipStyle}>
      <div style={tooltipHeaderStyle}>
        <span>{selectedWord}</span>
        <span style={{ opacity: 0.45, fontSize: 24 }}>×</span>
      </div>
      <div style={tooltipBodyStyle}>
        <h3 style={tooltipHeadingStyle}>Basic definition</h3>
        <p style={tooltipTextStyle}>
          上海证券交易所的
          <span style={{ ...wordChipStyle, ...(selectedOpacity > 0 ? selectedWordStyle : {}) }}>
            股票
          </span>
          <span style={{ ...wordChipStyle, ...(selectedOpacity > 0 ? selectedWordStyle : {}) }}>
            价格
          </span>
          <span style={wordChipStyle}>指数</span>，反映上海证券市场
          <span style={wordChipStyle}>整体</span>走势。
        </p>
        <div style={{ ...actionBoxStyle, opacity: actionOpacity }}>
          <div style={{ fontSize: 16, color: '#666' }}>
            Selected: <strong>股票、价格</strong>
          </div>
          <div style={{ fontSize: 12, color: '#999', marginTop: 4 }}>
            These will be saved to vocabulary
          </div>
          <button style={buttonStyle}>Save and explain again</button>
        </div>
      </div>
    </div>
  )
}

function MousePointer({ x, y }: { x: number; y: number }) {
  return (
    <div style={{ ...pointerStyle, transform: `translate(${x}px, ${y}px)` }}>
      <div style={pointerHeadStyle} />
    </div>
  )
}

function VocabularyNotebook() {
  const words = ['沪指', '股票', '价格', '指数', '整体']
  return (
    <div style={notebookStyle}>
      <div style={notebookHeaderStyle}>📚 Vocabulary</div>
      <div style={{ padding: '8px 20px', background: '#e3f2fd', fontSize: 14, color: '#1976d2' }}>
        12 words · auto-excluded from explanations
      </div>
      {words.map((word, index) => (
        <div key={word} style={wordRowStyle}>
          <span>{word}</span>
          <small>{index === 0 ? 'just now' : `${index * 2} hours ago`}</small>
        </div>
      ))}
      <div style={notebookFooterStyle}>Export · Clear</div>
    </div>
  )
}

function Caption({ text }: { text: string }) {
  return <div style={captionStyle}>{text}</div>
}

function GradientOrbs() {
  return (
    <AbsoluteFill>
      <div style={{ ...orbStyle, left: -180, top: -160, background: '#1976d2' }} />
      <div style={{ ...orbStyle, right: -220, bottom: -200, background: '#1565c0' }} />
      <div style={{ ...orbStyle, right: 420, top: 120, background: '#1a1a2e', opacity: 0.22 }} />
    </AbsoluteFill>
  )
}

function fade(
  frame: number,
  fadeInStart: number,
  fadeInEnd: number,
  fadeOutStart: number,
  fadeOutEnd: number,
) {
  return interpolate(frame, [fadeInStart, fadeInEnd, fadeOutStart, fadeOutEnd], [0, 1, 1, 0], clamp)
}

const clamp = { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' } as const
const easeOut = { ...clamp, easing: Easing.out(Easing.cubic) }
const backgroundStyle: CSSProperties = {
  background: 'linear-gradient(135deg, #1a1a2e 0%, #16213e 100%)',
}
const baseTextStyle: CSSProperties = { color: '#fff', fontFamily: FONT }
const centerStyle: CSSProperties = {
  ...baseTextStyle,
  alignItems: 'center',
  display: 'flex',
  justifyContent: 'center',
  textAlign: 'center',
}
const sceneStyle: CSSProperties = {
  alignItems: 'center',
  display: 'flex',
  gap: 76,
  justifyContent: 'center',
  padding: '90px 110px 150px',
}
const logoMarkStyle: CSSProperties = {
  alignItems: 'center',
  background: 'linear-gradient(135deg, #1976d2 0%, #1565c0 100%)',
  borderRadius: 34,
  display: 'flex',
  fontSize: 92,
  fontWeight: 800,
  height: 156,
  justifyContent: 'center',
  marginBottom: 34,
  width: 156,
}
const heroTitleStyle: CSSProperties = {
  ...baseTextStyle,
  fontSize: 126,
  fontWeight: 800,
  letterSpacing: -5,
  margin: 0,
}
const heroSubtitleStyle: CSSProperties = {
  ...baseTextStyle,
  fontSize: 38,
  marginTop: 20,
  opacity: 0.9,
}
const copyStyle: CSSProperties = { ...baseTextStyle, maxWidth: 560 }
const eyebrowStyle: CSSProperties = {
  color: '#4a90d9',
  fontFamily: FONT,
  fontSize: 30,
  fontWeight: 700,
  letterSpacing: 1.6,
  marginBottom: 24,
  textTransform: 'uppercase',
}
const slideTitleStyle: CSSProperties = {
  ...baseTextStyle,
  fontSize: 76,
  fontWeight: 800,
  letterSpacing: -3,
  lineHeight: 1.05,
  margin: 0,
}
const slideBodyStyle: CSSProperties = {
  ...baseTextStyle,
  fontSize: 34,
  lineHeight: 1.35,
  marginTop: 30,
  opacity: 0.9,
}
const browserStyle: CSSProperties = {
  background: '#fff',
  borderRadius: 28,
  boxShadow: '0 40px 120px rgba(0,0,0,0.38)',
  minHeight: 520,
  overflow: 'hidden',
  position: 'relative',
  width: 920,
}
const browserHeaderStyle: CSSProperties = {
  alignItems: 'center',
  background: '#F3F1ED',
  display: 'flex',
  gap: 12,
  padding: '18px 22px',
}
const dotStyle: CSSProperties = { borderRadius: 99, height: 16, width: 16 }
const addressStyle: CSSProperties = {
  background: '#fff',
  borderRadius: 10,
  color: '#6B6763',
  flex: 1,
  fontFamily: FONT,
  fontSize: 18,
  marginLeft: 18,
  padding: '10px 16px',
}
const articleStyle: CSSProperties = {
  color: '#3A3632',
  fontFamily: FONT,
  fontSize: 34,
  lineHeight: 1.62,
  padding: 56,
}
const highlightStyle: CSSProperties = {
  background: 'linear-gradient(transparent 60%, #a8d8ea 60%)',
  borderRadius: 4,
  padding: '2px 4px',
}
const floatingTooltipWrap: CSSProperties = { left: 430, position: 'absolute', top: 210 }
const tooltipStyle: CSSProperties = {
  background: '#fff',
  borderRadius: 22,
  boxShadow: '0 22px 70px rgba(0,0,0,0.28)',
  color: '#1a1a1a',
  fontFamily: FONT,
  overflow: 'hidden',
  width: 440,
}
const tooltipHeaderStyle: CSSProperties = {
  alignItems: 'center',
  background: '#f8f9fa',
  borderBottom: '1px solid #eee',
  display: 'flex',
  fontSize: 30,
  fontWeight: 800,
  justifyContent: 'space-between',
  padding: '20px 24px',
}
const tooltipBodyStyle: CSSProperties = { padding: 24 }
const tooltipHeadingStyle: CSSProperties = {
  color: '#1976d2',
  fontSize: 18,
  margin: '0 0 12px',
  textTransform: 'uppercase',
  letterSpacing: 0.5,
}
const tooltipTextStyle: CSSProperties = { color: '#333', fontSize: 22, lineHeight: 1.8, margin: 0 }
const wordChipStyle: CSSProperties = {
  background: 'rgba(26, 115, 232, 0.1)',
  borderRadius: 4,
  padding: '1px 3px',
}
const selectedWordStyle: CSSProperties = { background: '#ffd700' }
const actionBoxStyle: CSSProperties = { borderTop: '1px solid #eee', marginTop: 16, paddingTop: 14 }
const buttonStyle: CSSProperties = {
  background: '#1976d2',
  border: 0,
  borderRadius: 8,
  color: '#fff',
  display: 'block',
  fontSize: 15,
  fontWeight: 600,
  marginTop: 12,
  padding: '10px 16px',
  width: '100%',
}
const pointerStyle: CSSProperties = {
  filter: 'drop-shadow(0 12px 18px rgba(0,0,0,0.35))',
  height: 80,
  left: 0,
  position: 'absolute',
  top: 0,
  width: 80,
}
const pointerHeadStyle: CSSProperties = {
  background: '#fff',
  clipPath: 'polygon(0 0, 0 62%, 18% 48%, 30% 78%, 43% 72%, 30% 43%, 54% 43%)',
  height: 80,
  width: 80,
}
const comparePanelStyle: CSSProperties = { alignItems: 'center', display: 'flex', gap: 32 }
const miniTooltipStyle: CSSProperties = {
  ...tooltipTextStyle,
  background: '#fff',
  borderRadius: 22,
  boxShadow: '0 30px 90px rgba(0,0,0,0.35)',
  minHeight: 230,
  padding: 28,
  width: 420,
}
const miniLabelStyle: CSSProperties = {
  color: '#1976d2',
  fontSize: 16,
  fontWeight: 700,
  marginBottom: 14,
  textTransform: 'uppercase',
  letterSpacing: 0.5,
}
const arrowStyle: CSSProperties = {
  color: 'rgba(255,255,255,0.4)',
  fontFamily: FONT,
  fontSize: 50,
  fontWeight: 700,
}
const notebookStyle: CSSProperties = {
  background: '#fff',
  borderRadius: 28,
  boxShadow: '0 40px 120px rgba(0,0,0,0.38)',
  color: '#1a1a1a',
  fontFamily: FONT,
  overflow: 'hidden',
  width: 400,
}
const notebookHeaderStyle: CSSProperties = {
  borderBottom: '1px solid #eee',
  fontSize: 28,
  fontWeight: 800,
  padding: '22px 26px',
}
const wordRowStyle: CSSProperties = {
  alignItems: 'center',
  borderBottom: '1px solid #f5f5f5',
  display: 'flex',
  fontSize: 24,
  fontWeight: 600,
  justifyContent: 'space-between',
  padding: '18px 26px',
}
const notebookFooterStyle: CSSProperties = {
  color: '#1976d2',
  display: 'flex',
  fontSize: 18,
  fontWeight: 600,
  gap: 24,
  justifyContent: 'center',
  padding: '18px 26px',
}
const languageGridStyle: CSSProperties = {
  display: 'grid',
  gap: 24,
  gridTemplateColumns: 'repeat(2, 270px)',
}
const languageCardStyle: CSSProperties = {
  ...baseTextStyle,
  background: 'rgba(255,255,255,0.1)',
  border: '1px solid rgba(255,255,255,0.2)',
  borderRadius: 24,
  fontSize: 34,
  fontWeight: 800,
  padding: '38px 30px',
  textAlign: 'center',
}
const captionStyle: CSSProperties = {
  ...baseTextStyle,
  background: 'rgba(0,0,0,0.5)',
  borderRadius: 18,
  bottom: 42,
  fontSize: 28,
  left: '50%',
  maxWidth: 1320,
  padding: '16px 28px',
  position: 'absolute',
  textAlign: 'center',
  transform: 'translateX(-50%)',
}
const logoRowStyle: CSSProperties = {
  alignItems: 'center',
  display: 'flex',
  fontFamily: FONT,
  fontSize: 52,
  fontWeight: 800,
  gap: 18,
  marginBottom: 30,
}
const smallLogoStyle: CSSProperties = {
  alignItems: 'center',
  background: 'linear-gradient(135deg, #1976d2 0%, #1565c0 100%)',
  borderRadius: 18,
  display: 'flex',
  height: 74,
  justifyContent: 'center',
  width: 74,
}
const outroTitleStyle: CSSProperties = {
  ...baseTextStyle,
  fontSize: 92,
  fontWeight: 800,
  letterSpacing: -3,
  margin: 0,
}
const outroBodyStyle: CSSProperties = {
  ...baseTextStyle,
  fontSize: 42,
  marginTop: 26,
  opacity: 0.9,
}
const orbStyle: CSSProperties = {
  borderRadius: 999,
  filter: 'blur(28px)',
  height: 460,
  opacity: 0.2,
  position: 'absolute',
  width: 460,
}

registerRoot(RemotionRoot)
