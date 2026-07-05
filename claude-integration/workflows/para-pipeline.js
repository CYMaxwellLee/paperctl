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
//   sectionText    (STRONGLY RECOMMENDED) 目標段落所在 section 的完整現行全文。
//                  沒有它就沒有全局視角:跨段冗餘、承先啟後、各段唯一職責都檢查不了
//                  (2026-07-05 ¶4 事故的直接教訓)。缺席時 pipeline 會 log 警告。
//   editBrief      (required) 教授的指示 + 目標段落角色(如「intro ¶4: method+contributions」)
//   paperFacts     (required) 論文事實包:數字、模型、cite keys、novelty 邊界、LaTeX 慣例
//   repoDir        (STRONGLY RECOMMENDED) 論文 repo 路徑。Verifier 用它實查 bib key、
//                  對表格核數字、掃其他 section 的過期數字(2026-07-05 教訓:學生更新
//                  結果後 abstract/conclusion 數字全文不一致,只有 repo 實查抓得到)
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
    { title: 'Direction', detail: 'section editor: whole-section audit + paragraph plan (inherits main-loop model; skipped if provided)' },
    { title: 'Write', detail: '3 Sonnet writers with distinct lenses, each self-revised (three-pass)', model: 'sonnet' },
    { title: 'Attack', detail: '1 Sonnet critic attacks the draft and all variants', model: 'sonnet' },
    { title: 'Judge', detail: 'best-of-breed synthesis + finding adjudication against professor rulings' },
    { title: 'Verify', detail: 'mechanical fact-check against the repo: cite keys, numbers vs tables, stale numbers elsewhere, bans', model: 'sonnet' },
    { title: 'Proxy', detail: 'professor-proxy review against the rulings ledger' },
    { title: 'Refine', detail: 'bounded internal revision loop (max 2 rounds) until verifier passes and proxy approves' },
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
const LEDGER = ROOT + '/skills/academic-paper-writing/modules/rulings-ledger.md'
const DOCTRINE = [STYLE_GUIDE, LEDGER, ...(A.moduleFiles || []).map(f => f.startsWith('/') ? f : ROOT + '/' + f)]
const readDoctrine = 'FIRST read these doctrine files with the Read tool and obey them (goal function, register audits, argument architecture, three-pass revision, claim strategy, bans):\n' +
  DOCTRINE.map(f => '- ' + f).join('\n') + '\n'

if (!A.sectionText) log('WARNING: no sectionText provided — global checks (cross-paragraph redundancy, handoff, section-level length) will be weak. Provide the full current section.')

const GLOBAL_RULES = '\nGLOBAL RULES (the doctrine outranks this edit brief — if they conflict, follow the doctrine and flag the conflict):\n' +
  '- READ THE WHOLE SECTION FIRST. The rewritten paragraph must add only NEW information relative to the rest of the section.\n' +
  '- OWNERSHIP (承先啟後): if this paragraph introduces our method, the first mention must unambiguously mark it as OURS (we propose / we introduce / this paper presents). Clever handoffs never outrank this.\n' +
  '- NO RE-EXPLANATION: a concept already established in an earlier paragraph is referenced in half a sentence, never re-argued. If you catch yourself restating an earlier paragraph\'s reasoning, cut it.\n' +
  '- SELLING TEST (when the module says this paragraph sells, e.g. intro P4): for EVERY sentence ask — does it answer WHY this is good/hard/important, or only WHAT it does? Mechanism narration is compressed to a minimum; the space goes to advantages, impact, significance.\n' +
  '- OUTCOME TESTS, not surface features: satisfying checkable constraints (terminology, numbers, opener syntax) does NOT discharge the spirit requirements above. Verify by outcome: would a reviewer feel the significance? know whose method this is? see no repetition?\n' +
  '- After the three-pass revision, ALSO run the module file\'s own self-check table (e.g. introduction.md\'s Anti-Mediocrity Check) item by item and fix failures.\n'

const CONTEXT = '\nEDIT BRIEF (the professor\'s instruction — this defines success):\n' + A.editBrief +
  '\n\nPAPER FACTS (do not invent beyond these; keep all \\cite keys / numbers / macros exactly):\n' + A.paperFacts +
  (A.sectionText ? '\n\nFULL CURRENT SECTION (read END TO END before anything else):\n' + A.sectionText : '') +
  '\n\nPARAGRAPH TO REWRITE (LaTeX, verbatim):\n' + A.paragraphText + '\n' + GLOBAL_RULES

// ---------- Phase 1: direction draft (main-loop model), skipped when provided ----------
phase('Direction')
const DIRECTION_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['sectionAudit', 'skeleton', 'argumentMoves', 'claimBoundaries', 'mustKeep'],
  properties: {
    sectionAudit: { type: 'string', description: 'whole-section audit: each paragraph\'s unique job; cross-paragraph redundancy (quote the repeated concepts); overlong paragraphs; exactly which established concepts the target paragraph must NOT re-explain' },
    skeleton: { type: 'string', description: 'sentence-level outline of the target paragraph, marking for each sentence whether it SELLS (why good/important) or informs, and what NEW information it adds' },
    argumentMoves: { type: 'string', description: 'the load-bearing argument moves (e.g. asymmetry arguments, callbacks to earlier paragraphs)' },
    claimBoundaries: { type: 'string', description: 'what may be claimed vs what must be credited/scoped (novelty landscape)' },
    mustKeep: { type: 'string', description: 'citations, numbers, terms, macros that must survive verbatim; plus the ownership marker if the method debuts here' },
  },
}
const direction = A.directionDraft || await agent(
  readDoctrine + CONTEXT +
  '\nYou are the SECTION EDITOR. Do not write the final prose. FIRST read the entire section end to end and produce the sectionAudit: what each paragraph uniquely contributes, where paragraphs repeat each other (quote the repetitions), which paragraphs run long, and exactly which established concepts the target paragraph must reference in half a sentence instead of re-explaining. THEN produce the plan for the target paragraph: a sentence-level skeleton where each sentence is marked as selling vs informing and justified by the NEW information it adds, the load-bearing argument moves, the claim boundaries, and the must-keep elements (including the ownership marker if our method debuts here). Any section-level problem you find that lies OUTSIDE the target paragraph (e.g. an earlier paragraph is overlong) goes into sectionAudit for the judge to surface upward.',
  { label: 'section-editor', phase: 'Direction', schema: DIRECTION_SCHEMA }
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
  required: ['final', 'provenance', 'adjudications', 'globalChecks', 'openQuestions'],
  properties: {
    final: { type: 'string', description: 'the single best final paragraph, LaTeX-ready, fluent and correct as a whole' },
    provenance: { type: 'string', description: 'which sentences/moves came from which draft or the direction plan, and why' },
    globalChecks: { type: 'object', additionalProperties: false,
      required: ['ownership', 'sellingVsNarrative', 'crossParagraphRedundancy', 'moduleSelfCheck'],
      properties: {
        ownership: { type: 'string', description: 'is the method debut unambiguously marked as ours? quote the marker' },
        sellingVsNarrative: { type: 'string', description: 'sentence-by-sentence verdict: which sentences sell (why-good) vs narrate (what-it-does); overall verdict' },
        crossParagraphRedundancy: { type: 'string', description: 'every repetition against other paragraphs found and eliminated (quote both sides), or "none found"' },
        moduleSelfCheck: { type: 'string', description: 'the module checklist (e.g. Anti-Mediocrity Check) run item by item with results' },
      },
    },
    adjudications: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['finding', 'verdict', 'action'], properties: {
      finding: { type: 'string' },
      verdict: { type: 'string', enum: ['accepted', 'rejected-relitigation', 'rejected-false-positive'] },
      action: { type: 'string' },
    } } },
    openQuestions: { type: 'string', description: 'anything only the professor can decide; empty string if none' },
  },
}
const judgePrompt = readDoctrine + CONTEXT +
  '\nYou are the JUDGE. Synthesize ONE best-of-breed final paragraph from the direction plan and the candidate drafts: take the strongest argument spine, the safest claims, the most precise register, and make the whole fluent and internally consistent (theme words, referents, terminology locked). Adjudicate every critic finding: accept real ones into the final text; REJECT any that relitigate professor-attested rulings (because->since is mandated; the 2026-06-12 OK-list is protected; approved conventions stand) or that are false positives — say which and why. Then run the full three-pass revision on your own final text, scanning it against the §八 ban list literally. THEN run the GLOBAL ACCEPTANCE PASS (mandatory; verdicts go in globalChecks, and these are OUTCOME tests, not surface features): read your final text as part of the FULL SECTION and verify (1) OWNERSHIP — the method debut carries an unambiguous we-propose-level marker; (2) SELLING vs NARRATIVE — sentence-by-sentence audit; a paragraph that merely narrates mechanism FAILS even with every mechanical constraint satisfied; (3) CROSS-PARAGRAPH REDUNDANCY — list every restatement of content from other paragraphs (quote both sides) and eliminate it from your final text; (4) MODULE SELF-CHECK — run the module file\'s own checklist (e.g. introduction.md Anti-Mediocrity Check) item by item. The doctrine outranks the edit brief: where they conflict, follow the doctrine and record the conflict in openQuestions. Section-level problems OUTSIDE this paragraph (from the sectionAudit or your own reading, e.g. an overlong earlier paragraph) also go into openQuestions for the professor. Do NOT return a placeholder or summary — `final` must be the complete paragraph.\n\nDIRECTION PLAN:\n' + JSON.stringify(direction, null, 2) +
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

// ---------- Phase 5: Verifier — mechanical fact check, tools actually run ----------
phase('Verify')
const VERIFY_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['pass', 'issues', 'notes'],
  properties: {
    pass: { type: 'boolean', description: 'true only if zero must-fix issues' },
    issues: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['severity', 'kind', 'detail'], properties: {
      severity: { type: 'string', enum: ['must-fix', 'minor'] },
      kind: { type: 'string', description: 'stale-number | cite-key | terminology | ban | fact' },
      detail: { type: 'string' },
    } } },
    notes: { type: 'string' },
  },
}
const verifierPrompt = (text) => readDoctrine + CONTEXT +
  '\nYou are the VERIFIER. Mechanically fact-check the candidate text. ACTUALLY run every check with tools (Read/Grep/Bash); never report a check you did not run.' +
  (A.repoDir
    ? '\nPaper repo: ' + A.repoDir + ' — (1) grep every \\cite key in the candidate against the repo\'s .bib file(s); (2) read the results tables and cross-check every number in the candidate; (3) grep the OTHER section files for numbers that conflict with the current results and flag them as must-fix stale-number issues (even though they are outside the candidate — the professor must know); (4) check the candidate\'s terminology against the section for drift.'
    : '\nNo repoDir given — verify text-only: numbers vs paperFacts, internal consistency, terminology vs sectionText.') +
  '\n(5) grep-scan the candidate against the style-guide §八 ban list.\n\nCANDIDATE:\n' + text
let verifier = await agent(verifierPrompt(judgement.final), { label: 'verifier', phase: 'Verify', schema: VERIFY_SCHEMA, model: 'sonnet' })

// ---------- Phase 6: Professor-Proxy review, then bounded internal refinement ----------
phase('Proxy')
const PROXY_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['verdict', 'lineEdits', 'overall'],
  properties: {
    verdict: { type: 'string', enum: ['approve', 'revise'] },
    lineEdits: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['quote', 'problem', 'fix', 'rulingRef'], properties: {
      quote: { type: 'string' }, problem: { type: 'string' }, fix: { type: 'string' },
      rulingRef: { type: 'string', description: 'the ledger entry / doctrine clause this finding invokes' },
    } } },
    overall: { type: 'string', description: 'overall assessment; open questions the proxy cannot settle go here' },
  },
}
const proxyPrompt = (text) => readDoctrine + CONTEXT +
  '\nYou are the PROFESSOR-PROXY REVIEWER. The rulings ledger (among the doctrine files above) is your ground truth. Review the candidate exactly as the professor would, line by line: register line-edits (ledger §一), argument/structure/clarity (§二 — transitions, over-compressed sentences, referent alignment, cross-paragraph redundancy, selling vs narrative, ownership marker), claim safety (§三), conventions (§四). Cite the ledger entry in rulingRef for every finding. Verdict approve ONLY if the professor would plausibly accept without line edits. Professor-approved conventions are binding — do not flag them. When unsure whether something violates a ruling, raise it in overall as an open question instead of inventing a finding.\n\nCANDIDATE:\n' + text
let proxy = await agent(proxyPrompt(judgement.final), { label: 'proxy', phase: 'Proxy', schema: PROXY_SCHEMA, effort: A.judgeEffort || 'high' })

const REVISE_SCHEMA = { type: 'object', additionalProperties: false, required: ['final', 'changes'], properties: {
  final: { type: 'string', description: 'the COMPLETE revised text' },
  changes: { type: 'string', description: 'what changed and which finding each change answers' },
} }
let rounds = 0
const unresolved = []
while (rounds < 2 && (!verifier.pass || proxy.verdict === 'revise')) {
  rounds += 1
  log('internal refinement round ' + rounds + ' (verifier pass=' + verifier.pass + ', proxy=' + proxy.verdict + ')')
  const revision = await agent(
    readDoctrine + CONTEXT +
    '\nYou are the JUDGE revising your own final text. Apply the verifier issues and professor-proxy line edits below. Doctrine and ledger outrank everything; do not regress any global check (ownership, selling, redundancy, terminology). Return the COMPLETE revised text, not a diff.\n\nCURRENT TEXT:\n' + judgement.final +
    '\n\nVERIFIER ISSUES:\n' + JSON.stringify(verifier.issues, null, 2) +
    '\n\nPROXY LINE EDITS:\n' + JSON.stringify(proxy.lineEdits, null, 2),
    { ...judgeOpts, label: 'refine:' + rounds, phase: 'Refine', schema: REVISE_SCHEMA }
  )
  if (revision && revision.final && revision.final.length > 200) judgement.final = revision.final
  verifier = await agent(verifierPrompt(judgement.final), { label: 'verifier:r' + rounds, phase: 'Refine', schema: VERIFY_SCHEMA, model: 'sonnet' })
  proxy = await agent(proxyPrompt(judgement.final), { label: 'proxy:r' + rounds, phase: 'Refine', schema: PROXY_SCHEMA, effort: A.judgeEffort || 'high' })
}
if (!verifier.pass) unresolved.push('Verifier still failing: ' + JSON.stringify(verifier.issues.filter(i => i.severity === 'must-fix')))
if (proxy.verdict === 'revise') unresolved.push('Proxy still requests revisions: ' + JSON.stringify(proxy.lineEdits.slice(0, 5)))

return {
  final: judgement.final,
  provenance: judgement.provenance,
  globalChecks: judgement.globalChecks,
  adjudications: judgement.adjudications,
  openQuestions: (judgement.openQuestions || '') + (unresolved.length ? '\n\nUNRESOLVED AFTER ' + rounds + ' REFINEMENT ROUND(S):\n' + unresolved.join('\n') : ''),
  verifier,
  proxy,
  refinementRounds: rounds,
  critique,
  drafts: drafts.map(d => d.text),
  direction,
}
