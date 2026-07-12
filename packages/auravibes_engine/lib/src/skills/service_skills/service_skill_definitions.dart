import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/anthropic.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/brave.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/codex.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/duckduckgo.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/exa.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/firecrawl.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/gemini.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/jina.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/kagi.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/kimi.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/openai.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/parallel.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/perplexity.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/searxng.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/synthetic.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/tavily.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/tinyfish.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/xai.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/zai.dart';

final List<AppSkillDefinition> serviceSkillDefinitions = List.unmodifiable([
  braveSkill,
  exaSkill,
  anthropicSkill,
  openAiSkill,
  codexSkill,
  zaiSkill,
  xAiSkill,
  perplexitySkill,
  geminiSkill,
  tinyFishSkill,
  jinaSkill,
  kagiSkill,
  tavilySkill,
  firecrawlSkill,
  kimiSkill,
  parallelSkill,
  syntheticSkill,
  searXngSkill,
  duckDuckGoSkill,
]);
