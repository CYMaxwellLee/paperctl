// para-pipeline.js -- 段落級改寫 pipeline (paperctl)
//
// Provenance: 教授 2026-07-05 提案:「我每次說要改哪一段,基本上先有個 Opus 4.8 先大概
// 抓個方向…開個 3~5 個 Sonnet 5,要他們也寫…最後再給 Fable 5 or Opus 4.8 max 裁決,
// 整段要流暢正確,最後給我看,然後再上傳。」
// Design rationale + usage: skills/academic-paper-writing/modules/drafting-pipeline.md
//
// Invoke from any session / any machine (repo location via `paperctl root`):
//   ROOT=$(paperctl root)
//   Workflow({ scriptPath: ROOT + "/claude-integration/workflows/para-pipeline.js",
//              args: { paperctlRoot: ROOT, paragraphText, editBrief, paperFacts, ... } })
//
// args:
//   paperctlRoot   (recommended) paperctl repo 根目錄(用 `paperctl root` 取得)。
//                  未給時退回本檔提交時的預設路徑,換機器必給。
//   paragraphText  (required) 要改寫的段落原文(學生稿或現行稿,LaTeX 原樣)
//   editBrief      (required) 教授的指示 + 目標段落角色(如「intro ¶4: method+contributions」)
//   paperFacts     (required) 論文事實包:數字、模型、cite keys、novelty 邊界、LaTeX 慣例
//   moduleFiles    (optional) 章節專用 doctrine 模組;相對路徑會以 paperctlRoot 為基底解析
//                  (如 "skills/academic-paper-writing/modules/introduction.md");style-guide 永遠自動包含
//   directionDraft (optional) 主線已寫好的方向草稿;缺省時由 pipeline 第一階段(繼承主線模型)產生
//   judgeModel     (optional) 'fable' | 'opus' 釘死裁決模型;預設繼承主線 session 模型
//                  (教授 2026-07-05:「反正用 Fable 5 or Opus 最新的」-- 主線選什麼就是什麼,政策變動不用改 code)
//   judgeEffort    (optional) 裁決 effort,預設 'high'(最難的段落可給 'max')
//
// 主線(呼叫方)的責任,pipeline 不代勞:套進 .tex、compile、真跑 paperctl lint、
// 給教授過目、教授 OK 才推 Overleaf。永不 auto-push。

export const meta = {
  name: 'para-pipeline',
  description: 'Paragraph rewrite: direction draft, 3 Sonnet lens-writers + 1 Sonnet critic, strong-model judge synthesis',
  phases: [
    { title: 'Direction', detail: 'skeleton + argument moves (inherits main-loop model; skipped if provided)' },
    { title: 'Write', detail: '3 Sonnet writers with distinct lenses, each self-revised (three-pass)', model: 'sonnet' },
    { title: 'Attack', detail: '1 Sonnet critic attacks the draft and all variants', model: 'sonnet' },
    { title: 'Judge', detail: 'best-of-breed synthesis + finding adjudication against professor rulings' },
  ],
}

// Harness footgun guard: some invocation paths deliver args as a JSON-encoded
// string rather than an object (observed 2026-07-05 on first live run). Normalize.
let A = args
if (typeof A === 'string') {
  try { A = JSON.parse(A) } catch (e) { throw new Error('para-pipeline: args arrived as a non-JSON string') }
}
if (!A || !A.paragraphText || !A.editBrief || !A.paperFacts) {
  throw new Error('para-pipeline requires args: { paragraphText, editBrief, paperFacts }')
}

const ROOT = A.paperctlRoot || '/Users/cymaxwelllee/Project/Papers/paperctl'
const STYLE_GUIDE = ROOT + '/skills/academic-paper-writing/modules/style-guide.md'
const DOCTRINE = [STYLE_GUIDE, ...(A.moduleFiles || []).map(f => f.startsWith('/') ? f : ROOT + '/' + f)]
const readDoctrine = 'FIRST read these doctrine files with the Read tool and obey them (goal function, register audits, argument architecture, three-pass revision, claim strategy, bans):\n' +
  DOCTRINE.map(f => '- ' + f).join('\n') + '\n'

const CONTEXT = '\nEDIT BRIEF (the professor\'s instruction — this defines success):\n' + A.editBrief +
  '\n\nPAPER FACTS (do not invent beyond these; keep all \\cite keys / numbers / macros exactly):\n' + A.paperFacts +
  '\n\nPARAGRAPH TO REWRITE (LaTeX, verbatim):\n' + A.paragraphText + '\n'

// ---------- Phase 1: direction draft (main-loop model), skipped when provided ----------
phase('Direction')
const DIRECTION_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['skeleton', 'argumentMoves', 'claimBoundaries', 'mustKeep'],
  properties: {
    skeleton: { type: 'string', description: 'sentence-level outline of the target paragraph' },
    argumentMoves: { type: 'string', description: 'the load-bearing argument moves (e.g. asymmetry arguments, callbacks to earlier paragraphs)' },
    claimBoundaries: { type: 'string', description: 'what may be claimed vs what must be credited/scoped (novelty landscape)' },
    mustKeep: { type: 'string', description: 'citations, numbers, terms, macros that must survive verbatim' },
  },
}
const direction = A.directionDraft || await agent(
  readDoctrine + CONTEXT +
  '\nYou are the DIRECTION planner. Do not write the final prose. Produce the plan a strong author would work from: the sentence-level skeleton, the load-bearing argument moves, the claim boundaries (what to credit to prior work, how to scope claims), and the elements that must survive verbatim.',
  { label: 'direction', phase: 'Direction', schema: DIRECTION_SCHEMA }
)

// ---------- Phase 2: 3 Sonnet writers (lens diversity) + Phase 3 critic needs all of them (barrier) ----------
phase('Write')
const LENSES = [
  { key: 'argument', brief: 'LENS: argument depth. Your priority is that every claim is argued, not asserted: unpack the why, add the asymmetry/causal arguments, make transitions carry real logical relations, align referents, and never leave a sentence the professor would mark 「不太懂」「跳太快」.' },
  { key: 'reviewer', brief: 'LENS: reviewer-proofing. Your priority is claim safety: credit shared observations to prior work, scope every generality claim to what is demonstrated, pre-empt the strongest reviewer attack, and keep the framing solid-and-strong (不示弱, no self-inflicted weaknesses).' },
  { key: 'register', brief: 'LENS: register precision. Your priority is top-venue academic register: precise verbs over casual ones, no spoken idioms or slogans, locked terminology (one concept one name), no word echoes within/across adjacent sentences, concise without losing clarity.' },
]
const WRITE_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['text', 'passNotes'],
  properties: {
    text: { type: 'string', description: 'the full rewritten paragraph, LaTeX-ready' },
    passNotes: { type: 'string', description: 'brief notes on what each of your three revision passes changed' },
  },
}
const drafts = (await parallel(LENSES.map(l => () =>
  agent(
    readDoctrine + CONTEXT +
    '\nDIRECTION PLAN (follow its skeleton and boundaries):\n' + JSON.stringify(direction, null, 2) +
    '\n\n' + l.brief +
    '\n\nWrite the full rewritten paragraph. Then apply the three-pass revision protocol to YOUR OWN output before returning (argument pass, register pass with all four audits, mechanical pass by grep-scanning your text against the ban list in style-guide §八 — actually scan, do not just claim you did). Return the revised paragraph.',
    { label: 'write:' + l.key, phase: 'Write', schema: WRITE_SCHEMA, model: 'sonnet' }
  )
))).filter(Boolean)

if (drafts.length === 0) throw new Error('all writer agents failed')

// ---------- Phase 3: critic (needs all drafts -> barrier above is genuine) ----------
phase('Attack')
const CRITIQUE_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['findings', 'bestDraftIndex', 'overall'],
  properties: {
    findings: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['target', 'severity', 'quote', 'problem', 'fix'], properties: {
      target: { type: 'string', description: 'direction | draft-1 | draft-2 | draft-3' },
      severity: { type: 'string', enum: ['must-fix', 'suggestion', 'taste'] },
      quote: { type: 'string' },
      problem: { type: 'string' },
      fix: { type: 'string' },
    } } },
    bestDraftIndex: { type: 'number', description: '1-based index of the strongest draft' },
    overall: { type: 'string' },
  },
}
const critique = await agent(
  readDoctrine + CONTEXT +
  '\nYou are the ADVERSARIAL CRITIC. You do not write a draft. Attack the direction plan and every candidate below: argument holes, claim-safety exposures a hostile reviewer could cite, register leaks, terminology drift, ban violations, unfaithfulness to the edit brief. Quote the offending text for each finding. IMPORTANT: professor-attested rulings in the doctrine (provenance-dated items, the mandated replacements like because->since, the 2026-06-12 explicitly-OK list) are BINDING — do not report compliant usage as a problem.\n\nDIRECTION PLAN:\n' + JSON.stringify(direction, null, 2) +
  '\n\nCANDIDATE DRAFTS:\n' + drafts.map((d, i) => 'DRAFT ' + (i + 1) + ':\n' + d.text).join('\n\n'),
  { label: 'critic', phase: 'Attack', schema: CRITIQUE_SCHEMA, model: 'sonnet' }
)

// ---------- Phase 4: judge (strong model = inherit main loop; effort tunable) ----------
phase('Judge')
const JUDGE_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['final', 'provenance', 'adjudications', 'openQuestions'],
  properties: {
    final: { type: 'string', description: 'the single best final paragraph, LaTeX-ready, fluent and correct as a whole' },
    provenance: { type: 'string', description: 'which sentences/moves came from which draft or the direction plan, and why' },
    adjudications: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['finding', 'verdict', 'action'], properties: {
      finding: { type: 'string' },
      verdict: { type: 'string', enum: ['accepted', 'rejected-relitigation', 'rejected-false-positive'] },
      action: { type: 'string' },
    } } },
    openQuestions: { type: 'string', description: 'anything only the professor can decide; empty string if none' },
  },
}
const judgePrompt = readDoctrine + CONTEXT +
  '\nYou are the JUDGE. Synthesize ONE best-of-breed final paragraph from the direction plan and the candidate drafts: take the strongest argument spine, the safest claims, the most precise register, and make the whole fluent and internally consistent (theme words, referents, terminology locked). Adjudicate every critic finding: accept real ones into the final text; REJECT any that relitigate professor-attested rulings (because->since is mandated; the 2026-06-12 OK-list is protected; approved conventions stand) or that are false positives — say which and why. Then run the full three-pass revision on your own final text, scanning it against the §八 ban list literally. Do NOT return a placeholder or summary — `final` must be the complete paragraph.\n\nDIRECTION PLAN:\n' + JSON.stringify(direction, null, 2) +
  '\n\nCANDIDATE DRAFTS:\n' + drafts.map((d, i) => 'DRAFT ' + (i + 1) + ' (passNotes: ' + d.passNotes.slice(0, 300) + '):\n' + d.text).join('\n\n') +
  '\n\nCRITIC REPORT:\n' + JSON.stringify(critique, null, 2)

const judgeOpts = { label: 'judge', phase: 'Judge', schema: JUDGE_SCHEMA, effort: A.judgeEffort || 'high' }
if (A.judgeModel) judgeOpts.model = A.judgeModel
let judgement = await agent(judgePrompt, judgeOpts)

// Placeholder guard (2026-07-05 lesson: a synthesizer once returned stubs).
const longestDraft = Math.max(...drafts.map(d => d.text.length))
if (!judgement || judgement.final.length < Math.min(400, longestDraft * 0.5)) {
  log('judge output too short — retrying once with explicit anti-placeholder warning')
  judgement = await agent(
    judgePrompt + '\n\nWARNING: your previous attempt returned a truncated/placeholder `final`. Return the COMPLETE final paragraph this time.',
    { ...judgeOpts, label: 'judge:retry' }
  )
}

return {
  final: judgement.final,
  provenance: judgement.provenance,
  adjudications: judgement.adjudications,
  openQuestions: judgement.openQuestions,
  critique,
  drafts: drafts.map(d => d.text),
  direction,
}
